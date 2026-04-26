# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

INSTANCES = 2
box_info = { name: 'generic/rocky8', version: '4.3.12' }

PROVISION_PUPPET = <<~PUPPET
  /usr/bin/dnf makecache
  /usr/bin/dnf upgrade -y
  /bin/rpm -Uvh https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
  /usr/bin/dnf -y install puppet-agent
  /usr/bin/dnf autoremove -y
  /usr/bin/dnf clean all
  echo '*' > /etc/puppetlabs/puppet/autosign.conf
  /opt/puppetlabs/bin/puppet resource host puppet.choria ensure=present ip=192.168.56.5 host_aliases=puppet
  mkdir -p /etc/puppetlabs/facter/facts.d
  echo "role=${1}" > /etc/puppetlabs/facter/facts.d/role.txt
PUPPET

Vagrant.configure('2') do |config|
  config.vm.synced_folder '.', '/vagrant', type: 'virtualbox'

  config.vm.define :puppet do |vmconfig|
    vmconfig.vm.box = box_info[:name]
    vmconfig.vm.box_version = box_info[:version]
    vmconfig.vm.hostname = 'puppet.choria'
    vmconfig.vm.network :private_network, ip: '192.168.56.5'
    vmconfig.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', 3072]
    end

    vmconfig.vbguest.installer_options = { allow_kernel_upgrade: true }
    vmconfig.vbguest.auto_update = false

    vmconfig.vm.provision :shell do |s|
      s.inline = PROVISION_PUPPET
      s.args = 'puppetserver'
    end

    vmconfig.vm.provision 'shell', inline: <<-SHELL
      echo ">>> Installing PuppetServer..."
      /bin/rpm -Uvh https://yum.puppet.com/puppetserver-release-el-8.noarch.rpm
      dnf install -y puppetserver

      echo ">>> Syncing environments to /etc/puppetlabs/code/environments..."
      rsync -a --delete /vagrant/environments/ /etc/puppetlabs/code/environments/

      echo ">>> Starting PuppetServer..."
      systemctl start puppetserver
      systemctl enable puppetserver

      sleep 10
      systemctl status puppetserver --no-pager | head -5
    SHELL

    vmconfig.vm.provision 'shell', inline: <<-SHELL
      echo ">>> Running puppet apply to configure Choria and Puppet..."
      /opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/default.pp \
        --hiera_config=/etc/puppetlabs/code/environments/production/hiera.yaml \
        --modulepath=/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site
    SHELL
  end

  INSTANCES.times do |i|
    config.vm.define "instance#{i}" do |vmconfig|
      vmconfig.vm.box = box_info[:name]
      vmconfig.vm.box_version = box_info[:version]
      vmconfig.vm.hostname = "choria#{i}.choria"
      vmconfig.vm.network :private_network, ip: format('192.168.56.%d', 9 + i)
      vmconfig.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 1024]
      end

      vmconfig.vbguest.installer_options = { allow_kernel_upgrade: true }
      vmconfig.vbguest.auto_update = false

      vmconfig.vm.provision :shell do |s|
        s.inline = PROVISION_PUPPET
        s.args = 'managed'
      end

      vmconfig.vm.provision 'shell', inline: <<-SHELL
        echo ">>> Syncing environments to /etc/puppetlabs/code/environments..."
        rsync -a --delete /vagrant/environments/ /etc/puppetlabs/code/environments/

        echo ">>> Running puppet apply to configure Choria and Puppet..."
        /opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/default.pp \
          --hiera_config=/etc/puppetlabs/code/environments/production/hiera.yaml \
          --modulepath=/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site
      SHELL
      vmconfig.vm.provision 'shell', inline: <<-SHELL
        echo ">>> Running puppet agent to enroll with PuppetServer..."
        /opt/puppetlabs/bin/puppet agent -tv --waitforcert 30 --server puppet.choria
      SHELL
    end
  end
end
