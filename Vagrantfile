Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  #config.vm.box_url = "file://c:/soft/precise-server-cloudimg-amd64-vagrant-disk1.box"
  #config.vm.box_url = "ubuntu/xenial64"
  #config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"
    

  config.vm.hostname = "drupal.dev"

  config.vm.network :private_network, ip: "33.33.33.10"
    config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--memory", 4048]
#C:\Users\User\VirtualBox VMs\drupal-dev_default_1478353912008_30701>"C:\Program Files\Oracle VM VirtualBox\VBoxManage.exe" showhdinfo  ubuntu-xenial-16.04-cloudimg.vmdk
#    v.customize ["modifyhd", "c18d6150-f5ca-4c4e-b16f-e10126c7bfa0", "--resize", "16384"]
    
  end

  # config.vm.synced_folder "./sites", "/var/www", type: "smb"
  #config.vm.synced_folder "./sites", "/var/www", :nfs => true
  config.vm.synced_folder "./sites", "/var/www", :nfs => true,  :mount_options => ['nolock,vers=3,udp,noatime,actimeo=1']
  config.vm.provision :shell, :inline => "sudo apt-get update"
  config.vm.provision :shell, :path => "upgrade_puppet.sh"

  config.vm.provision :puppet do |puppet|
    #puppet.facter = {
    #  "ssh_username" => "vagrant"
    #}

    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.options = ["--verbose", "--hiera_config /vagrant/hiera.yaml"]
  end

  config.ssh.username = "ubuntu"     
end
