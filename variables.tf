variable "name" {}
variable "flavor" {}
variable "image_name" {}
variable "pool" {}
variable "network_name" {}

variable "puppet_environment" {
  default = "production"
}

variable "agent_num" {
  default = 2
}
