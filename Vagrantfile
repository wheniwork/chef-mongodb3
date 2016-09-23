# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

Vagrant.require_version '>= 1.5.0'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = 'mongodb3-berkshelf'

  config.vm.box = 'ubuntu/trusty64'

  config.berkshelf.enabled = true

  config.vm.provider :lxc do |provider, override|
    override.vm.box = "wiw-lxc-base"
    override.vm.box_url = "https://s3.amazonaws.com/wiw-vagrant/wiw-lxc-base"
    override.vm.network "private_network", ip: "192.168.100.109", lxc__bridge_name: 'lxcbr1'
  end

  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  config.vm.synced_folder '.', '/vagrant', type: 'rsync'
  config.berkshelf.enabled = true

  config.omnibus.chef_version = '12.9.41'

  config.vm.provision :chef_solo do |chef|
    chef.run_list = [
      'recipe[mongodb3::default]',
      'recipe[mongodb3::users]'
    ]
  end
end
