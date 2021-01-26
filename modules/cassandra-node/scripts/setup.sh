#!/bin/bash
set -e -x

# Install Java
sudo yum install java-1.8.0-openjdk -y

nvme_mdadm_setup() {
	# Install tools
    sudo yum install mdadm -y
	# Create a RAID 6 array across all 9 NVMe drives, create an XFS filesystem on the array and mount the filesystem
	sudo mdadm --create /dev/md0 --chunk=256 --raid-devices=9 --level=6 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1 /dev/nvme5n1 /dev/nvme6n1 /dev/nvme7n1 /dev/nvme8n1
	sudo mdadm --detail --scan | sudo tee -a /etc/mdadm.conf >> /dev/null
	sudo mkfs.xfs -s size=4096 -d su=262144 -d sw=6 /dev/md0
	sudo mkdir /mnt/cassandra
	sudo mount /dev/md0 /mnt/cassandra
}
if ls /dev/nvme* 1> /dev/null 2>&1; then
    echo "NVME drives exists."
    nvme_mdadm_setup
else
    echo "No NVME drives."
    sudo mkdir /mnt/cassandra
fi

# Open up the operating system firewall to allow Cassandra to communicate between instances. We limit communication on the Cassandra ports to the VCN subnet.
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="${vcn_cidr}" port protocol="tcp" port="${storage_port}" accept'
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="${vcn_cidr}" port protocol="tcp" port="${ssl_storage_port}" accept'
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="${vcn_cidr}" port protocol="tcp" port="7199" accept'

# Add the Apache Cassandra repo, using yum to install Cassandra
echo -e "[cassandra]\nname=Apache Cassandra\nbaseurl=https://www.apache.org/dist/cassandra/redhat/311x/\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://www.apache.org/dist/cassandra/KEYS" | sudo tee /etc/yum.repos.d/cassandra.repo
sudo yum install cassandra-3.11.9 -y

# Set the cluster name, use the NVMe backed filesystem for data, and a few more details
sudo chown cassandra.cassandra /mnt/cassandra/
sudo sed -i "s/cluster_name:.*/cluster_name: '${cluster_name}'/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/hints_directory:.*/hints_directory: \/mnt\/cassandra\/hints/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/.*\/cassandra\/data/    - \/mnt\/cassandra\/data/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/commitlog_directory:.*/commitlog_directory: \/mnt\/cassandra\/commitlog/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/saved_caches_directory:.*/saved_caches_directory: \/mnt\/cassandra\/saved_caches/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i 's/.*- seeds:.*/          - seeds: "${private_ips}"/g' /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/^storage_port:.*/storage_port: ${storage_port}/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/ssl_storage_port:.*/ssl_storage_port: ${ssl_storage_port}/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/listen_address:.*/listen_address: ${local_private_ip}/g" /etc/cassandra/conf/cassandra.yaml
sudo sed -i "s/endpoint_snitch:.*/endpoint_snitch: GossipingPropertyFileSnitch/g" /etc/cassandra/conf/cassandra.yaml

# Create the Cassandra cluster
sudo rm /etc/cassandra/conf/cassandra-topology.properties
sudo sed -i "s/dc=.*/dc=${node_ad}/g" /etc/cassandra/conf/cassandra-rackdc.properties
sudo sed -i "s/rack=.*/rack=${node_fd}/g" /etc/cassandra/conf/cassandra-rackdc.properties

# Start the Cassandra cluster
sudo service cassandra start
