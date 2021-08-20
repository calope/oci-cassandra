# ---------------------------------------------------------------------------------------------------------------------
# This is an example of how to use the terraform_oci_cassandra_cluster module to deploy a Cassandra cluster in OCI
# by using existing VCN, security list and subnets.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
variable "tenancy_ocid" {}

variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_authorized_keys" {}
variable "ssh_private_key" {}
variable "vcn_cidr" {}

variable "subnet_ocids" {
  type = list(string)
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "7.9"
}

variable "node_shape" {
  type        = string
  description = "Instance shape for node instance to use."
  default     = "VM.Standard2.1"
}

variable "cassandra_version" {
  description = "Version of Cassandra software"
  default     = "3.11.11"
}

# ---------------------------------------------------------------------------------------------------------------------
# DATASOURCE
# ---------------------------------------------------------------------------------------------------------------------
# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "InstanceImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.node_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

data "template_file" "ad_names" {
  count    = length(data.oci_identity_availability_domains.ad.availability_domains)
  template = lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CASSANDRA CLUSTER
# ---------------------------------------------------------------------------------------------------------------------
module "cassandra" {
  source               = "../../"
  compartment_ocid     = var.compartment_ocid
  node_count           = "3"
  seeds_count          = "3"
  availability_domains = data.template_file.ad_names.*.rendered
  subnet_ocids         = var.subnet_ocids
  vcn_cidr             = var.vcn_cidr
  image_ocid           = lookup(data.oci_core_images.InstanceImageOCID.images[0], "id")
  storage_port         = "7000"
  ssl_storage_port     = "7001"
  ssh_authorized_keys  = file(var.ssh_authorized_keys)
  ssh_private_key      = file(var.ssh_private_key)
  cassandra_version    = var.cassandra_version
}
