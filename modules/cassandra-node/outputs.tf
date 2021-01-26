output "ids" {
  value = [oci_core_instance.TFCassandraNode.*.id]
}

output "public_ips" {
  value = [oci_core_instance.TFCassandraNode.*.public_ip]
}

output "private_ips" {
  value = [oci_core_instance.TFCassandraNode.*.private_ip]
}

output "node_names" {
  value = [oci_core_instance.TFCassandraNode.*.display_name]
}
