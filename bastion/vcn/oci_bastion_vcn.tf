# Variables
variable "bastion_vcn_name" { type = string }
variable "bastion_vcn_dns_label" { type = string }
variable "bastion_vcn_subnet_name" { type = string }
variable "bastion_vcn_subnet_dns_label" { type = string }
variable "compartment_ocid" { type = string }
variable "ssh_public_key_path" { type = string }

resource "oci_core_virtual_network" "bastion_vcn" {
  cidr_block     = "172.168.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = var.bastion_vcn_name
  dns_label      = var.bastion_vcn_dns_label
}

resource "oci_core_subnet" "bastion_subnet" {
  cidr_block        = "172.168.1.0/24"
  display_name      = var.bastion_vcn_subnet_name
  dns_label         = var.bastion_vcn_subnet_dns_label
  security_list_ids = [oci_core_security_list.bastion_security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.bastion_vcn.id
  route_table_id    = oci_core_route_table.bastion_route_table.id
  dhcp_options_id   = oci_core_virtual_network.bastion_vcn.default_dhcp_options_id
}

resource "oci_core_internet_gateway" "bastion_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "Bastion IG"
  vcn_id         = oci_core_virtual_network.bastion_vcn.id
}

resource "oci_core_route_table" "bastion_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.bastion_vcn.id
  display_name   = "Bastion RouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.bastion_internet_gateway.id
  }
}

resource "oci_core_security_list" "bastion_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.bastion_vcn.id
  display_name   = "Bastion SecurityList"

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "80"
      min = "80"
    }
  }
}

# Outputs for the vcn module

output "bastion_vcn_id" {
  description = "OCID of the Bastion VCN that is created"
  value = oci_core_virtual_network.bastion_vcn.id
}
output "bastion_id-for-route-table-that-includes-the-internet-gateway" {
  description = "OCID of the Bastion internet-route table. This route table has an internet gateway to be used for public subnets"
  value = oci_core_internet_gateway.bastion_internet_gateway.id
}