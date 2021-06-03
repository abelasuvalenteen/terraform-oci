module "bastion" {
  source  = "oracle-terraform-modules/bastion/oci"
  version = "2.1.0"
  # insert the 5 required variables here
  tenancy_id = var.tenancy_ocid
  user_id = var.user_ocid
  region = var.region
  compartment_id = var.compartment_ocid
  ig_route_id = oci_core_internet_gateway.bastion_internet_gateway.id
  vcn_id = oci_core_virtual_network.bastion_vcn.id
  ssh_public_key_path = var.ssh_public_key_path
  api_fingerprint = var.fingerprint
  api_private_key_path = var.private_key_path
}