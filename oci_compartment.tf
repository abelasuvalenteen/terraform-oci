# Variables
variable "bastion_compartment_name" { type = string }
variable "bastion_compartment_desc" { type = string }
variable "app_compartment_name" { type = string }
variable "app_compartment_desc" { type = string }

# Resources
resource "oci_identity_compartment" "bastion_compartment" {
  # Required
  compartment_id = var.root_compartment_id
  description    = var.bastion_compartment_desc
  name           = var.bastion_compartment_name
}

resource "oci_identity_compartment" "application_compartment" {
  # Required
  compartment_id = var.root_compartment_id
  description    = var.app_compartment_desc
  name           = var.app_compartment_name
}

# Outputs
output "bastion_compartment_name" {
  value = oci_identity_compartment.bastion_compartment.name
}

output "bastion_compartment_id" {
  value = oci_identity_compartment.bastion_compartment.id
}

output "app_compartment_name" {
  value = oci_identity_compartment.application_compartment.name
}

output "app_compartment_id" {
  value = oci_identity_compartment.application_compartment.id
}