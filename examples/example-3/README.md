## Create VCN and Deploy Cassandra Cluster (single AD scenario)
This example creates a VCN, including default route table, DHCP options, security list and subnets, in Oracle Cloud Infrastructure. Then it uses terraform_oci_cassandra_cluster module to deploy a Cassandra cluster.

### Using this example
Update terraform.tfvars with the required information.

### Deploy the cluster  
Initialize Terraform:
```
$ terraform init
```
View what Terraform plans to do before actually executing it:
```
$ terraform plan
```
Use Terraform to provision resources and Cassandra cluster on OCI:
```
$ terraform apply
```
