# frozen_string_literal: true

require 'spec_helper'
require 'net/ssh'
require 'json'

def run_remote_command(ssh, command)
  stdout_data = ''
  stderr_data = ''
  exit_code = nil

  channel = ssh.open_channel do |ch|
    ch.request_pty do |_, success|
      abort "Could not obtain pty" unless success
    end

    ch.exec(command) do |_, success|
      abort "could not execute #{command}" unless success

      ch.on_data do |_, data|
        stdout_data += data
      end

      ch.on_extended_data do |_, _, data|
        puts "got STDERR: #{data}"
      end

      ch.on_request('exit-status') do |_, data|
        exit_code = data.read_long
      end
    end
  end

  ssh.loop(0.1) { channel.active? }
  [stdout_data, exit_code]
end

def parse_ping(output)
  result = Set[]
  output.split("\n").each do |line|
    result.add(line.strip)
  end
  result
end

def parse_roles(output)
  data = JSON.parse(output, symbolize_names: true)
  managed = Set.new
  data[:managed][:identities].each do |identity|
    managed.add(identity)
  end
  data[:managed][:identities] = managed
  data
end

describe 'Choria configuration validation' do
  before(:all) do
    host = '127.0.0.1'
    user = 'vagrant'
    port = 2222
    key_path = File.expand_path('.vagrant.d/boxes/custom-VAGRANTSLASH-rockylinux-8.10/0/amd64/virtualbox/vagrant_private_key', ENV['HOME'])
    @ssh = Net::SSH.start(host, user, port: port, keys: [key_path], non_interactive: true)
  end

  after(:all) do
    @ssh.close if @ssh
  end

  let(:expected_ping) {Set[ 'puppet.choria', 'choria0.choria', 'choria1.choria']}

  let(:expected_roles) do
    {
      managed: {
        count: 2,
        identities: Set['choria1.choria', 'choria0.choria']
      },
      puppetserver: {
        count: 1,
        identities: ['puppet.choria']
      }
    }
  end

  it 'choria ping reports the expected nodes' do
    output, exit_code = run_remote_command(@ssh, 'choria ping --names')

    if exit_code != 0
      run_remote_command(@ssh, 'choria enroll')
      output, exit_code = run_remote_command(@ssh, 'choria ping --names')
    end

    expect(exit_code).to eq(0)
    expect(parse_ping(output)).to eq(expected_ping)
  end

  it 'choria facts properly identifies the nodes roles' do
    output, exit_code = run_remote_command(@ssh, 'choria facts role --json')
    expect(exit_code).to eq(0)
    expect(parse_roles(output)).to eq(expected_roles)
  end

end
