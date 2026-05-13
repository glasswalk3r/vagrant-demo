# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

INSTANCES = 2
BOX_NAME = 'custom/rockylinux-8.10'

PROVISION_OPENVOX = <<~OPENVOX
  ROLE_FILE=/etc/puppetlabs/facter/facts.d/role.txt
  if [[ -f $ROLE_FILE ]]
  then
      echo 'Packages already installed, nothing to do'
  else
      echo '*' > /etc/puppetlabs/puppet/autosign.conf
      /opt/puppetlabs/bin/puppet resource host puppet.choria ensure=present ip=192.168.56.5 host_aliases=puppet
      mkdir -p /etc/puppetlabs/facter/facts.d
      echo "role=${1}" > /etc/puppetlabs/facter/facts.d/role.txt
  fi
OPENVOX

Vagrant.configure('2') do |config|
  config.vm.synced_folder '.', '/vagrant', type: 'virtualbox'

  config.vm.define :puppet do |vmconfig|
    vmconfig.vm.box = BOX_NAME
    vmconfig.vm.hostname = 'puppet.choria'
    vmconfig.vm.network :private_network, ip: '192.168.56.5'
    vmconfig.vm.network :forwarded_port, guest: 9100, host: 9100, id: 'Prometheus'
    vmconfig.vm.provider :virtualbox do |vb|
      vb.linked_clone = true
      vb.customize ['modifyvm', :id, '--memory', 3072]
      vb.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
      vb.customize ['modifyvm', :id, '--vram', '16']
      vb.name = "openvox"
    end

    vmconfig.vbguest.auto_update = false

    vmconfig.vm.provision :shell do |s|
      s.inline = PROVISION_OPENVOX
      s.args = 'puppetserver'
    end

    vmconfig.vm.provision 'shell', inline: <<-SHELL
      SERVICE_NAME=puppetserver
      if systemctl status $SERVICE_NAME --no-pager &> /dev/null
      then
          echo 'OpenVox already installed, nothing to do'
      else
          /usr/bin/dnf install -y openvox-server
          echo ">>> Syncing environments to /etc/puppetlabs/code/environments..."
          rsync -a --delete /vagrant/environments/ /etc/puppetlabs/code/environments/
          systemctl start $SERVICE_NAME
          systemctl enable $SERVICE_NAME
          sleep 10
          systemctl status $SERVICE_NAME --no-pager | head -5
      fi
    SHELL

    vmconfig.vm.provision 'shell', inline: <<-SHELL
      /opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/default.pp \
        --hiera_config=/etc/puppetlabs/code/environments/production/hiera.yaml \
        --modulepath=/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site
    SHELL
  end

  INSTANCES.times do |i|
    config.vm.define "instance#{i}" do |vmconfig|
      vmconfig.vm.box = BOX_NAME
      vmconfig.vm.hostname = "choria#{i}.choria"
      vmconfig.vm.network :private_network, ip: format('192.168.56.%d', 9 + i)
      vmconfig.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 1024]
        vb.customize ['modifyvm', :id, '--graphicscontroller', 'vmsvga']
        vb.customize ['modifyvm', :id, '--vram', '16']
        vb.linked_clone = true
        vb.name = "instance#{i}"
      end

      vmconfig.vbguest.auto_update = false

      vmconfig.vm.provision :shell do |s|
        s.inline = PROVISION_OPENVOX
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
