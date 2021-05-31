# Variables
variable "bastion_vcn_name" { type = string }
variable "bastion_vcn_dns_label" { type = string }

# Modules - Import
module "bastion_compartment" {
  source = "."
  # the variable that you set for your resource group
  compartment_id = "bastion_compartment_id"
}

module "vcn"{
  source  = "oracle-terraform-modules/vcn/oci"
  version = "2.0.0"

  compartment_id = module.bastion_compartment.compartment_id
  region = var.region
  vcn_name = var.bastion_vcn_name
  vcn_dns_label = var.bastion_vcn_dns_label
  internet_gateway_enabled = true
  nat_gateway_enabled = true
  service_gateway_enabled = true
  vcn_cidr = "172.168.0.0/29"
}

# Outputs for the vcn module

output "bastion_vcn_id" {
  description = "OCID of the Bastion VCN that is created"
  value = module.vcn.vcn_id
}
output "bastion_id-for-route-table-that-includes-the-internet-gateway" {
  description = "OCID of the Bastion internet-route table. This route table has an internet gateway to be used for public subnets"
  value = module.vcn.ig_route_id
}
output "bastion_nat-gateway-id" {
  description = "OCID for Bastion NAT gateway"
  value = module.vcn.nat_gateway_id
}
output "bastion_id-for-for-route-table-that-includes-the-nat-gateway" {
  description = "OCID of the Bastion nat-route table - This route table has a nat gateway to be used for private subnets. This route table also has a service gateway."
  value = module.vcn.nat_route_id
}