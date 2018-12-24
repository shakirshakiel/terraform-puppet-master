provider "openstack" {
}

resource "openstack_compute_keypair_v2" "puppet-machine-keypair" {
  name = "${var.name}-keypair"
  public_key = "${file("./dummy_keypair/cloud.key.pub")}"
}
