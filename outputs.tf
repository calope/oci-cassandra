output "instance_ids" {
  value = module.cassandra-node.ids
}

output "node_public_ips" {
  value = module.cassandra-node.public_ips
}

output "node_private_ips" {
  value = module.cassandra-node.private_ips
}
