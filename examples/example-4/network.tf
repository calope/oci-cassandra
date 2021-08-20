############################################
# Create VCN
############################################
resource "oci_core_virtual_network" "CassandraVCN" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "CassandraVCN"
  dns_label      = "ocicassandra"
}

############################################
# Create Internet Gateway
############################################
resource "oci_core_internet_gateway" "CassandraIG" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.label_prefix}CassandraIG"
  vcn_id         = oci_core_virtual_network.CassandraVCN.id
}

############################################
# Create NAT Gateway
############################################
resource "oci_core_nat_gateway" "CassandraNATGW" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.label_prefix}CassandraNATGW"
  vcn_id         = oci_core_virtual_network.CassandraVCN.id
}

############################################
# Create Route Table via IGW
############################################
resource "oci_core_route_table" "CassandraRT1" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.CassandraVCN.id
  display_name   = "${var.label_prefix}CassandraRouteTable1"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.CassandraIG.id
  }
}

############################################
# Create Route Table via NATGW
############################################
resource "oci_core_route_table" "CassandraRT2" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.CassandraVCN.id
  display_name   = "${var.label_prefix}CassandraRouteTable2"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.CassandraNATGW.id
  }
}

############################################
# Create Security List
############################################
resource "oci_core_security_list" "CassandraSL" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.label_prefix}CassandraSecurityList"
  vcn_id         = oci_core_virtual_network.CassandraVCN.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = var.storage_port
      min = var.storage_port
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = var.ssl_storage_port
      min = var.ssl_storage_port
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }

}

############################################
# Create Subnets
############################################
resource "oci_core_subnet" "BastionSubnet" {
  cidr_block        = var.public_subnet_cidr
  display_name      = "${var.label_prefix}BastionSubnet"
  dns_label         = "bastion"
  security_list_ids = [oci_core_virtual_network.CassandraVCN.default_security_list_id, oci_core_security_list.CassandraSL.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.CassandraVCN.id
  route_table_id    = oci_core_route_table.CassandraRT1.id
  dhcp_options_id   = oci_core_virtual_network.CassandraVCN.default_dhcp_options_id
}

resource "oci_core_subnet" "CassandraSubnet" {
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.label_prefix}CassandraSubnet"
  dns_label                  = "cassandra"
  security_list_ids          = [oci_core_virtual_network.CassandraVCN.default_security_list_id, oci_core_security_list.CassandraSL.id]
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.CassandraVCN.id
  route_table_id             = oci_core_route_table.CassandraRT2.id
  dhcp_options_id            = oci_core_virtual_network.CassandraVCN.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}
