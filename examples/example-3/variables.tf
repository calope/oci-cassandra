variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_authorized_keys" {}
variable "ssh_private_key" {}

variable "cassandra_version" {
  description = "Version of Cassandra software"
  default     = "3.11.11"
}

variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "7.9"
}

variable "node_shape" {
  default = "VM.Standard.E3.Flex"
}

variable "node_flex_shape_ocpus" {
  description = "Number of Flex shape OCPUs"
  default     = 1
}

variable "node_flex_shape_memory" {
  description = "Amount of Flex shape Memory in GB"
  default     = 10
}

variable "label_prefix" {
  default = ""
}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.0.0/24"
}

variable "storage_port" {
  default = 7000
}

variable "ssl_storage_port" {
  default = 7001
}
