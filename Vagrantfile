Vagrant.configure("2") do |config|
    config.vm.box = "puppetlabs/centos-7.0-64-puppet"
    
    config.vm.network "forwarded_port", guest: 80, host: 2200, auto_correct: true
    config.vm.network "forwarded_port", guest: 8125, host: 2201, protocol: 'udp', auto_correct: true
    
    config.vm.provision "puppet" do |puppet|
        puppet.environment_path = "puppet/environments"
        puppet.environment = "dev"
    end
end
