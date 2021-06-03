// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

/*
 * This example creates a private load balancer on one subnet in a single AD.
 */

variable "instance_image_ocid" {
  type = map(string)

  default = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle Linux 7.9"
    ap-tokyo-1     = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaapj6tt3elckgdsgvambg7unr3vzv7ngsb7qw7yybuyb3utymhgz2a"
  }
}

variable "instance_shape" {
  default = "VM.Standard2.1"
}

variable "availability_domain" {
  default = 1
}


/* Provider */
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}


/* Network */

resource "oci_core_vcn" "application_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "application_vcn"
  dns_label      = "appvcn"
}


resource "oci_core_subnet" "application_subnet1" {
  availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.20.0/24"
  display_name        = "application vcn subnet1"
  dns_label           = "appsubnet1"
  security_list_ids   = [oci_core_security_list.appsecuritylist.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.application_vcn.id
  route_table_id      = oci_core_route_table.approutetable.id
  dhcp_options_id     = oci_core_vcn.application_vcn.default_dhcp_options_id

  provisioner "local-exec" {
    command = "sleep 5"
  }
}


resource "oci_core_internet_gateway" "appinternetgateway" {
  compartment_id = var.compartment_ocid
  display_name   = "appinternetgateway"
  vcn_id         = oci_core_vcn.application_vcn.id
}

resource "oci_core_route_table" "approutetable" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.application_vcn.id
  display_name   = "approutetable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.appinternetgateway.id
  }
}

resource "oci_core_public_ip" "app_reserved_ip" {
  compartment_id = "${var.compartment_ocid}"
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}

resource "oci_core_security_list" "appsecuritylist" {
  display_name   = "public"
  compartment_id = oci_core_vcn.application_vcn.compartment_id
  vcn_id         = oci_core_vcn.application_vcn.id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

    ingress_security_rules {
      protocol = "6"
      source   = "0.0.0.0/0"

      tcp_options {
        min = 80
        max = 80
      }
    }
}

/* Load Balancer */

resource "oci_load_balancer" "lb1" {
  shape          = "100Mbps"
  compartment_id = var.compartment_ocid

  subnet_ids = [
      oci_core_subnet.application_subnet1.id,
    ]

  display_name = "loadbalancer1"
  reserved_ips {
    id = "${oci_core_public_ip.app_reserved_ip.id}"
  }
}

resource "oci_load_balancer_backend_set" "lb-bes1" {
  name             = "lb-bes1"
  load_balancer_id = oci_load_balancer.lb1.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "8080"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/"
  }
}

resource "oci_load_balancer_path_route_set" "app_test_path_route_set" {
  #Required
  load_balancer_id = oci_load_balancer.lb1.id
  name             = "app_test-set"

  path_routes {
    #Required
    backend_set_name = oci_load_balancer_backend_set.lb-bes1.name
    path             = "/app/video/123"

    path_match_type {
      #Required
      match_type = "EXACT_MATCH"
    }
  }
}

resource "oci_load_balancer_hostname" "test_hostname1" {
  #Required
  hostname         = "app1.oracle.com"
  load_balancer_id = oci_load_balancer.lb1.id
  name             = "hostname1"
}

resource "oci_load_balancer_hostname" "test_hostname2" {
  #Required
  hostname         = "app2.oracle.com"
  load_balancer_id = oci_load_balancer.lb1.id
  name             = "hostname2"
}

resource "oci_load_balancer_listener" "lb-listener1" {
  load_balancer_id         = oci_load_balancer.lb1.id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.lb-bes1.name
  hostname_names           = [oci_load_balancer_hostname.test_hostname1.name, oci_load_balancer_hostname.test_hostname2.name]
  port                     = 80
  protocol                 = "HTTP"
  rule_set_names           = [oci_load_balancer_rule_set.test_rule_set.name]

  connection_configuration {
    idle_timeout_in_seconds = "2"
  }
}

resource "oci_load_balancer_backend" "lb-be1" {
  load_balancer_id = oci_load_balancer.lb1.id
  backendset_name  = oci_load_balancer_backend_set.lb-bes1.name
  ip_address       = oci_core_instance.app_instance1.private_ip
  port             = 8080
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_rule_set" "test_rule_set" {
  items {
    action = "ADD_HTTP_REQUEST_HEADER"
    header = "app_header_name"
    value  = "app_header_value"
  }

  items {
    action          = "CONTROL_ACCESS_USING_HTTP_METHODS"
    allowed_methods = ["GET", "POST"]
    status_code     = "405"
  }

  items {
    action = "REDIRECT"

    conditions {
      attribute_name  = "PATH"
      attribute_value = "/app"
      operator        = "FORCE_LONGEST_PREFIX_MATCH"
    }

    redirect_uri {
      protocol = "{protocol}"
      host     = "{host}"
      port     = 8081
      path     = "{path}/video"
      query    = "?lang=en"
    }

    response_code = 302
  }

  items {
    action                         = "HTTP_HEADER"
    are_invalid_characters_allowed = true
    http_large_header_size_in_kb   = 8
  }

  load_balancer_id = oci_load_balancer.lb1.id
  name             = "app_rule_set_name"
}

output "lb_public_ip" {
  value = [oci_load_balancer.lb1.ip_address_details]
}


/* Instance */

resource "oci_core_instance" "app_instance1" {
  availability_domain = data.oci_identity_availability_domain.ad1.name
  compartment_id      = var.compartment_ocid
  display_name        = "app_instance1"
  shape               = var.instance_shape

  metadata = {
    user_data = base64encode(var.user-data)
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.application_subnet1.id
    hostname_label = "app-instance1"
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }

    timeouts {
      create = "60m"
    }
}

# Gets a list of vNIC attachments on the instance
data "oci_core_vnic_attachments" "instance_vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad1.name
  instance_id         = oci_core_instance.app_instance1.id
}

# Gets the OCID of the first (default) vNIC
data "oci_core_vnic" "instance_vnic" {
  vnic_id = data.oci_core_vnic_attachments.instance_vnics.vnic_attachments[0]["vnic_id"]
}


variable "user-data" {
  default = <<EOF
#!/bin/bash -x
echo '################### webserver userdata begins #####################'
touch ~opc/userdata.`date +%s`.start
# echo '########## yum update all ###############'
# yum update -y
echo '########## basic webserver ##############'
yum install -y httpd
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
systemctl enable  httpd.service
systemctl start  httpd.service
echo '<html><head></head><body><pre><code>' > /var/www/html/index.html
hostname >> /var/www/html/index.html
echo '' >> /var/www/html/index.html
cat /etc/os-release >> /var/www/html/index.html
echo '</code></pre></body></html>' >> /var/www/html/index.html
firewall-offline-cmd --add-service=http
systemctl enable  firewalld
systemctl restart  firewalld
echo '########## JDK8 ######systemctl start docker########'
yum install -y java-1.8.0-openjdk
java -version
echo '########## docker Engine ##############'
yum install -y docker-engine
systemctl start docker.service
systemctl enable docker.service
systemctl status docker.service
docker info
docker version
touch ~opc/userdata.`date +%s`.finish
echo '################### webserver userdata ends #######################'
EOF

}

