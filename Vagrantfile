Vagrant.configure("2") do |config|
    config.vm.box = "puppetlabs/centos-7.0-64-puppet"
    
    config.vm.provision "puppet" do |puppet|
        puppet.environment_path = "puppet/environments"
        puppet.environment = "dev"
    end
end
