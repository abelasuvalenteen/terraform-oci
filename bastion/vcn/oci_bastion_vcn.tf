# Variables
variable "bastion_vcn_name" { type = string }
variable "bastion_vcn_dns_label" { type = string }
variable "bastion_vcn_subnet_name" { type = string }
variable "bastion_vcn_subnet_dns_label" { type = string }
variable "compartment_ocid" { type = string }
variable "ssh_public_key_path" { type = string }
variable "availability_domain" {
  default = 1
}

variable "instance_image_ocid" {
  type = map(string)

  default = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle Linux 7.9"
    ap-tokyo-1     = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaapj6tt3elckgdsgvambg7unr3vzv7ngsb7qw7yybuyb3utymhgz2a"
  }
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

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
      max = "3000"
      min = "3000"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "3005"
      min = "3005"
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


# Bastion compute

resource "oci_core_instance" "bastion" {
  availability_domain = data.oci_identity_availability_domain.ad1.name
  compartment_id      = var.compartment_ocid

  create_vnic_details {
    assign_public_ip = "public"
    display_name     = "bastion-vnic"
    hostname_label   = "bastion"
    subnet_id        = oci_core_subnet.bastion_subnet.id
  }

  display_name ="bastion"

  launch_options {
    boot_volume_type = "PARAVIRTUALIZED"
    network_type     = "PARAVIRTUALIZED"
  }

  # prevent the bastion from destroying and recreating itself if the image ocid changes
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  shape = "VM.Standard.E4.Flex"

  source_details {
    boot_volume_size_in_gbs = "50"
    source_type             = "image"
    source_id               = local.bastion_image_id
  }

  state = "RUNNING"

  timeouts {
    create = "60m"
  }

  count = 0
}

locals {
  all_protocols    = "all"
  anywhere         = "0.0.0.0/0"
  ssh_port         = 22
  tcp_protocol     = 6
  bastion_image_id = var.instance_image_ocid[var.region]
  vcn_cidr         = oci_core_virtual_network.bastion_vcn.id
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