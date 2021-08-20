## DATASOURCE
# Script Files
data "template_file" "setup_node" {
  count    = var.number_of_nodes
  template = file("${path.module}/scripts/setup.sh")

  vars = {
    vcn_cidr          = var.vcn_cidr
    cluster_name      = var.cluster_display_name
    private_ips       = join(",", slice(oci_core_instance.TFCassandraNode.*.private_ip, 0, tonumber(var.number_of_seeds)))
    local_private_ip  = oci_core_instance.TFCassandraNode.*.private_ip[count.index]
    node_ad           = oci_core_instance.TFCassandraNode.*.availability_domain[count.index]
    node_fd           = oci_core_instance.TFCassandraNode.*.fault_domain[count.index]
    node_index        = count.index + 1
    storage_port      = var.storage_port
    ssl_storage_port  = var.ssl_storage_port
    cassandra_version = var.cassandra_version
  }
}

# Cassandra Node
resource "oci_core_instance" "TFCassandraNode" {
  count               = var.number_of_nodes
  availability_domain = var.availability_domains[count.index % length(var.availability_domains)]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.label_prefix}${var.node_display_name}-${count.index + 1}"
  shape               = var.shape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.flex_shape_memory
      ocpus         = var.flex_shape_ocpus
    }
  }

  dynamic "agent_config" {
    for_each = var.use_private_subnet ? [1] : []
    content {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config {
        desired_state = "ENABLED"
        name          = "Bastion"
      }
    }
  }

  fault_domain = "FAULT-DOMAIN-${element(["1", "2", "3"], count.index + 1)}"
  defined_tags = var.defined_tags

  create_vnic_details {
    subnet_id        = var.subnet_ids[count.index % length(var.subnet_ids)]
    display_name     = "${var.label_prefix}${var.node_display_name}-${count.index + 1}"
    assign_public_ip = var.use_private_subnet ? false : true
    hostname_label   = "${var.node_display_name}-${count.index + 1}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  source_details {
    source_id   = var.image_id
    source_type = "image"
  }

  provisioner "local-exec" {
    command = "sleep 240"
  }
}

# Prepare files and execute scripts on Cassandra node via bastion service
resource "null_resource" "remote-exec-scripts-without-bastion-service" {
  depends_on = [oci_core_instance.TFCassandraNode]

  count = var.use_private_subnet ? 0 : var.number_of_nodes

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
      private_key = var.ssh_private_key
    }

    inline = [
      "sleep 60",
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
    ]
  }
}

resource "oci_bastion_session" "ssh_via_bastion_service" {
  count      = var.use_private_subnet ? var.number_of_nodes : 0
  bastion_id = var.bastion_service_id

  key_details {
    public_key_content = var.ssh_authorized_keys
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = oci_core_instance.TFCassandraNode[count.index].id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.TFCassandraNode[count.index].private_ip
  }

  display_name           = "ssh_via_bastion_service"
  key_type               = "PUB"
  session_ttl_in_seconds = 1800
}


# Prepare files and execute scripts on Cassandra node via bastion service
resource "null_resource" "remote-exec-scripts-with-bastion-service" {
  depends_on = [oci_core_instance.TFCassandraNode, oci_bastion_session.ssh_via_bastion_service]

  count = var.use_private_subnet ? var.number_of_nodes : 0

  # Prepare files on Cassandra node
  provisioner "file" {
    connection {
      host                = oci_core_instance.TFCassandraNode.*.private_ip[count.index]
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = var.ssh_private_key
      bastion_host        = "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.ssh_via_bastion_service[count.index].id
      bastion_private_key = var.ssh_private_key
    }

    content     = data.template_file.setup_node.*.rendered[count.index]
    destination = "/tmp/setup.sh"
  }

  # Execute scripts on Cassandra node
  provisioner "remote-exec" {
    connection {
      host                = oci_core_instance.TFCassandraNode.*.private_ip[count.index]
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = var.ssh_private_key
      bastion_host        = "host.bastion.${var.bastion_service_region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.ssh_via_bastion_service[count.index].id
      bastion_private_key = var.ssh_private_key
    }

    inline = [
      "sleep 60",
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
    ]
  }
}
