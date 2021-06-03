# Variables
variable "bastion_compartment_name" { type = string }
variable "bastion_compartment_desc" { type = string }
variable "targetSubnetId" { type = string }
variable "session_key_details_public_key_content" { type = string }
variable "targetResourceOCID" { type = string }
variable "targetResouceIP" { type = string }


# Resources
resource "oci_identity_compartment" "bastion_compartment" {
  # Required
  compartment_id = var.root_compartment_id
  description    = var.bastion_compartment_desc
  name           = var.bastion_compartment_name
}

resource "oci_bastion_bastion" "BastionCompute" {
    bastion_type = "standard"
    compartment_id = oci_identity_compartment.bastion_compartment.id
    target_subnet_id = var.targetSubnetId
    client_cidr_block_allow_list = "10.0.0.0/24"
}

resource "oci_bastion_session" "bastionsshcomputesession" {
    #Required
    bastion_id = oci_bastion_bastion.BastionCompute.id
    key_details {
        public_key_content = var.session_key_details_public_key_content
    }
    target_resource_details {
        session_type = "MANAGED_SSH"
        target_resource_id = var.targetResourceOCID
        target_resource_private_ip_address = var.targetResouceIP
    }
}

# Outputs
output "bastion_compartment_name" {
  value = oci_identity_compartment.bastion_compartment.name
}

output "bastion_compartment_id" {
  value = oci_identity_compartment.bastion_compartment.id
}
