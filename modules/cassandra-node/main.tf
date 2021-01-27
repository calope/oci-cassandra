## DATASOURCE
# Script Files
data "template_file" "setup_node" {
  count    = var.number_of_nodes
  template = file("${path.module}/scripts/setup.sh")

  vars = {
    vcn_cidr         = var.vcn_cidr
    cluster_name     = var.cluster_display_name
    #private_ips      = join(",", oci_core_instance.TFCassandraNode.*.private_ip)
    private_ips      = join(",", slice(oci_core_instance.TFCassandraNode.*.private_ip,0,tonumber(var.number_of_seeds)))
    local_private_ip = oci_core_instance.TFCassandraNode.*.private_ip[count.index]
    node_ad          = oci_core_instance.TFCassandraNode.*.availability_domain[count.index]
    node_fd          = oci_core_instance.TFCassandraNode.*.fault_domain[count.index]
    node_index       = count.index+1
    storage_port     = var.storage_port
    ssl_storage_port = var.ssl_storage_port
  }
}

# Cassandra Node
resource "oci_core_instance" "TFCassandraNode" {
  count               = var.number_of_nodes
  availability_domain = var.availability_domains[count.index%length(var.availability_domains)]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.label_prefix}${var.node_display_name}-${count.index+1}"
  shape               = var.shape
  fault_domain        = "FAULT-DOMAIN-${element(["1","2","3"],count.index+1)}"

  create_vnic_details {
    subnet_id        = var.subnet_ids[count.index%length(var.subnet_ids)]
    display_name     = "${var.label_prefix}${var.node_display_name}-${count.index+1}"
    assign_public_ip = true
    hostname_label   = "${var.node_display_name}-${count.index+1}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  source_details {
    source_id   = var.image_id
    source_type = "image"
  }
}

# Prepare files and execute scripts on Cassandra node
resource "null_resource" "remote-exec-scripts" {
  depends_on = [oci_core_instance.TFCassandraNode]

  count = var.number_of_nodes

  # Prepare files on Cassandra node
  provisioner "file" {
    connection {
      host        = oci_core_instance.TFCassandraNode.*.public_ip[count.index]
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = var.ssh_private_key
    }

    content     = data.template_file.setup_node.*.rendered[count.index]
    destination = "/tmp/setup.sh"
  }

  # Execute scripts on Cassandra node
  provisioner "remote-exec" {
    connection {
      host        = oci_core_instance.TFCassandraNode.*.public_ip[count.index]
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = file(var.ssh_private_key)
    }

    inline = [
      "sleep 60",
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
    ]
  }
}
