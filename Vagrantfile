# vi: set ft=ruby :
#


node_data_disk_count = 3
driveletters = ('a'..'z').to_a
disk_size = 501 #GB
cpus = 2
memory = 1024

node_count = 3

Vagrant.configure(2) do |config|
    puts "Creating #{node_count} nodes."
    puts "Creating #{node_data_disk_count} data disks (#{disk_size}G) each."

    (1..node_count).reverse_each do |num|
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
          lvt.storage_pool_name = "default"
          lvt.memory = "#{memory}"
          lvt.cpus = "#{cpus}"
          lvt.nested = false
          lvt.cpu_mode = "host-passthrough"
          lvt.volume_cache = "writeback"
          lvt.graphics_type = "none"
          lvt.video_type = "vga"
          lvt.video_vram = 1
          # lvt.usb_controller :model => "none"  # (requires vagrant-libvirt 0.44 which is not in Fedora yet)
          lvt.random :model => 'random'
          lvt.channel :type => 'unix', :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
          #disk_config
          disks = []
          (2..(node_data_disk_count+1)).each do |d|
            lvt.storage :file, :device => "vd#{driveletters[d]}", :size => "#{disk_size}G"
            disks.push "/dev/vd#{driveletters[d]}"
	  end #disks

        end #libvirt

	# Prepare VMs and deploy Gluster packages on all of them.
	node.vm.provision "ansible" do |ansible|
	  ansible.become = true
	  ansible.playbook = "ansible/machine_config.yml"
	  ansible.verbose = false
	  #ansible.groups = {
	  #  "gluster_servers" => "node-1:#{node_count}"
	  #}
        end
	# Deploy Glusto and Gluster using Gluster-Ansible via node-1
	if num == 1
          node.vm.synced_folder "./dist", "/vagrant", type: "rsync", create: true, rsync__args: ["--verbose", "--archive", "--delete", "-z"]
          node.vm.network "forwarded_port", guest: 9090, host: 9091
          node.vm.post_up_message << "You can now access Cockpit at http://localhost:9091 (login as 'root' with password 'foobar')"

          node.vm.provision "ansible" do |ansible|
            ansible.become = true
            ansible.playbook = "ansible/glusto.yml"
            ansible.limit = "node-1"
            ansible.verbose = false
          end

	  node.vm.provision "shell", inline: <<-SHELL
            set -u

            if [[ #{num} -eq 1 ]]
	    then
              echo "Preparing static inventory file..."
              echo "node-1 ansible_connection=local" >> /tmp/inventory.hosts
              echo "[gluster_servers]" >> /tmp/inventory.hosts
              echo "node-[1:#{node_count}]" >> /tmp/inventory.hosts

              echo "Running Gluster Ansible on node-1 to deploy Gluster..."
              PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_CONFIG='/vagrant/ansible.cfg' ansible-playbook --limit="gluster_servers" --inventory-file=/tmp/inventory.hosts /vagrant/gluster.yml
              sudo gluster pool list
            fi
            SHELL
	  end
        end
      end
    end
