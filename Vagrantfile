# vi: set ft=ruby :
#


node_data_disk_count = 4
driveletters = ('a'..'z').to_a
disk_size = 501 #GB
cpus = 1
memory = 824

node_count = 6 # node-0 is our client.

Vagrant.configure(2) do |config|
    puts "Creating #{node_count} nodes."
    puts "Creating #{node_data_disk_count} data disks (#{disk_size}G) each."

    require "fileutils"
    f = File.open("dist/hosts.ini","w")
    g = File.open("dist/glusto.yml", "w")
    f.puts "node-0 ansible_host=192.168.250.10"
    f.puts ""
    f.puts "[gluster_servers]"
    g.puts "log_level: DEBUG"
    g.puts "log_file: /tmp/gluster_tests.log"
    g.puts "servers:"
    (1..node_count).each do |num|
      f.puts "node-#{num} ansible_host=192.168.250.#{num+10}"
      g.puts "  - node-#{num} "
    end
    g.puts "clients:\n\  - node-0"
    g.puts "servers_info:"
    (1..node_count).each do |num|
      g.puts "  node-#{num}: &server#{num}"
      g.puts "    host: 192.168.250.#{num+10}"
      g.print "    devices: ["
      (1..(node_data_disk_count - 1)).each do |d|
        g.print "\"/dev/vd#{driveletters[d]}\", "
      end
      g.puts "/dev/vd#{driveletters[node_data_disk_count]}]"
      g.puts "    brick_root: \"/mnt\""
    end
    g.puts "clients_info:"
    g.puts "  node-0: &client1"
    g.puts "    host: 192.168.250.10"
    g.puts "\ngluster:"
    g.puts "  volume_types:"
    g.puts "    distributed_replicated: &distributed_replicated"
    g.puts "      type: \"distributed-replicated\""
    g.puts "      dist_count: 2"
    g.puts "      replica_count: 2"
    g.puts "      transport: \"tcp\""
    #g.puts "  smb_share_options:"
    #g.puts "    group: \"metadata-cache\""
    #g.puts "    cache-samba-metadata: \"on\""
    f.close
    g.close


    (0..node_count).reverse_each do |num|
      config.vm.define "node-#{num}" do |node|
        vm_ip = "192.168.250.#{num+10}"

        node.vm.box = "centos/7"
        node.vm.synced_folder ".", "/vagrant", disabled: true
        node.vm.network :private_network,
            :ip => vm_ip,
            :libvirt__driver_queues => "#{cpus}"
        node.vm.post_up_message = "VM private ip: #{vm_ip}"
        node.vm.hostname = "node-#{num}"

        node.vm.provider "libvirt" do |lvt|
          lvt.qemu_use_session = false
          lvt.storage_pool_name = "default"
          lvt.memory = "#{memory}"
          lvt.cpus = "#{cpus}"
          lvt.nested = false
          lvt.cpu_mode = "host-passthrough"
          lvt.volume_cache = "writeback"
          lvt.graphics_type = "none"
          lvt.video_type = "vga"
          lvt.video_vram = 1
          #lvt.usb_controller :model => "none"  # (requires vagrant-libvirt >= 0.44 which is in Fedora 30 only)
          lvt.random :model => 'random'
          lvt.channel :type => 'unix', :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
          #disk_config
          if num != 0
            (1..(node_data_disk_count)).each do |d|
              lvt.storage :file, :size => "#{disk_size}G", :serial => "#{d}"
	    end #disk_config
          end

        end #libvirt

        if num == 0
          node.vm.synced_folder "./dist", "/vagrant", type: "rsync", create: true, rsync__args: ["--verbose", "--archive", "--delete", "-z"]
          node.vm.post_up_message << "\nYou can now access the nodes (credential for root is 'foobar')"
        end

	# Prepare VMs and deploy Gluster packages on all of them.
	node.vm.provision "ansible" do |ansible|
	  ansible.become = true
	  ansible.playbook = "ansible/machine_config.yml"
	  ansible.verbose = false
          ansible.inventory_path = "dist/hosts.ini"
          ansible.extra_vars = {
            node_count: "#{node_count}",
            servers: (1..node_count).map { |n| "node-#{n}" % n },
            clients: ["node-0"]
          }
        end
	# Deploy Glusto and Gluster using Gluster-Ansible via node-0
	if num == 0
          node.vm.provision "ansible" do |ansible|
            ansible.become = true
            ansible.playbook = "ansible/glusto.yml"
            ansible.limit = "node-0"
            ansible.inventory_path = "dist/hosts.ini"
          end

	  node.vm.provision "shell", inline: <<-SHELL
            set -u

            echo "Running Gluster Ansible on node-0 to deploy Gluster..."
            PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_CONFIG='/vagrant/ansible.cfg' ansible-playbook --limit="gluster_servers" --inventory-file=/vagrant/hosts.ini --extra-vars "node_count=#{node_count}" /vagrant/gluster.yml

            echo "Cleaning up created volume, before running tests..."
            PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_CONFIG='/vagrant/ansible.cfg' ansible-playbook --limit="node-1" --inventory-file=/vagrant/hosts.ini --extra-vars "node_count=#{node_count}" /vagrant/gluster-cleanup.yml
            SHELL
	  end
        end
      end
    end
