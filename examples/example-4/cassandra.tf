# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CASSANDRA CLUSTER
# ---------------------------------------------------------------------------------------------------------------------
module "cassandra" {
  source                 = "../../"
  compartment_ocid       = var.compartment_ocid
  node_count             = "6"
  seeds_count            = "3"
  availability_domains   = data.template_file.ad_names.*.rendered
  subnet_ocids           = oci_core_subnet.CassandraSubnet.*.id
  vcn_cidr               = oci_core_virtual_network.CassandraVCN.cidr_block
  image_ocid             = lookup(data.oci_core_images.InstanceImageOCID.images[0], "id")
  node_shape             = var.node_shape
  node_flex_shape_ocpus  = var.node_flex_shape_ocpus
  node_flex_shape_memory = var.node_flex_shape_memory
  storage_port           = var.storage_port
  ssl_storage_port       = var.ssl_storage_port
  ssh_authorized_keys    = file(var.ssh_authorized_keys)
  ssh_private_key        = file(var.ssh_private_key)
  use_private_subnet     = true
  bastion_service_id     = oci_bastion_bastion.bastion-service.id
  bastion_service_region = var.region
  cassandra_version      = var.cassandra_version
}

