############################################
# Cassandra Node Instance(s)
############################################
module "cassandra-node" {
  source               = "./modules/cassandra-node"
  number_of_nodes      = var.node_count
  number_of_seeds      = var.seeds_count
  availability_domains = var.availability_domains
  compartment_ocid     = var.compartment_ocid
  node_display_name    = var.node_display_name
  cluster_display_name = var.cluster_display_name
  image_id             = var.image_ocid
  shape                = var.node_shape
  label_prefix         = var.label_prefix
  subnet_ids           = var.subnet_ocids
  vcn_cidr             = var.vcn_cidr
  storage_port         = var.storage_port
  ssl_storage_port     = var.ssl_storage_port
  ssh_authorized_keys  = var.ssh_authorized_keys
  ssh_private_key      = var.ssh_private_key
}
