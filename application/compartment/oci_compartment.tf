# Variables
variable "app_compartment_name" { type = string }
variable "app_compartment_desc" { type = string }

# Resources
resource "oci_identity_compartment" "application_compartment" {
  # Required
  compartment_id = var.root_compartment_id
  description    = var.app_compartment_desc
  name           = var.app_compartment_name
}

# Outputs
output "app_compartment_name" {
  value = oci_identity_compartment.application_compartment.name
}

output "app_compartment_id" {
  value = oci_identity_compartment.application_compartment.id
}