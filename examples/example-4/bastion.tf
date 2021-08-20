# ------------------------------------------------------------------------------
# Setup Bastion Service
# ------------------------------------------------------------------------------
resource "oci_bastion_bastion" "bastion-service" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = oci_core_subnet.BastionSubnet.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = "BastionService"
  max_session_ttl_in_seconds   = 1800
}
