variable "compartment_ocid" {
  description = "Compartment OCID where VCN is created. "
}

variable "label_prefix" {
  description = "To create unique identifier for multiple clusters in a compartment."
  default     = ""
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance. "
  default     = ""
}

variable "ssh_private_key" {
  description = "The private key path to access instance. "
  default     = ""
}

variable "node_count" {
  description = "The number of Cassandra nodes in the cluster. "
  default     = 3
}

variable "seeds_count" {
  description = "The number of Cassandra seed nodes in the cluster. "
  default     = 3
}

variable "availability_domains" {
  description = "The Availability Domain(s) for Cassandra node(s). "
  default     = []
}

variable "subnet_ocids" {
  description = "List of Cassandra node subnets' ids. "
  default     = []
}

variable "vcn_cidr" {
  description = "Virtual Cloud Network's CIDR block. "
  default     = ""
}

variable "node_display_name" {
  description = "The name of the Cassandra node. "
  default     = "tf-cassandra-node"
}

variable "cluster_display_name" {
  description = "The Cassandra cluster name. "
  default     = "Cassandra_Cluster"
}

variable "image_ocid" {
  description = "The OCID of an image on which the Cassandra node instance is based.  "
  default     = ""
}

variable "node_shape" {
  description = "Instance shape for node instance to use. "
  default     = "BM.DenseIO1.36"
}

variable "storage_port" {
  description = "TCP port for commands and data among Cassandra nodes. "
  default     = 7000
}

variable "ssl_storage_port" {
  description = "SSL port for encrypted communication among Cassandra nodes. "
  default     = 7001
}

variable "cassandra_version" {
  description = "Version of Cassandra software"
  default     = "3.11.10"
}
