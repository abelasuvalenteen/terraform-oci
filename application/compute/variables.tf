# provider identity parameters
variable "fingerprint" {
  description = "fingerprint of oci api private key"
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "path to oci api private key used"
  type        = string
  default     = ""
}

variable "region" {
  description = "the oci region where resources will be created"
  type        = string
}

variable "tenancy_ocid" {
  description = "tenancy id where to create the sources"
  type        = string
  default     = ""
}

variable "user_ocid" {
  description = "id of user that terraform will use to create the resources"
  type        = string
  default     = ""
}

variable "compartment_ocid" {
  description = "compartment id where to create all resources"
  type        = string
}
