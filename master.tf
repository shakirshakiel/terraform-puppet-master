resource "openstack_networking_floatingip_v2" "puppet_master_floatingip" {
  pool = "${var.pool}"
}

resource "openstack_compute_floatingip_associate_v2" "puppet_master_float_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.puppet_master_floatingip.address}"
  instance_id = "${openstack_compute_instance_v2.puppet_master.id}"
  fixed_ip = "${openstack_compute_instance_v2.puppet_master.network.0.fixed_ip_v4}"
}

resource "tls_private_key" "master" {
  algorithm = "RSA"
  rsa_bits = "2048"
}

data "template_file" "master" {
  template = "${file("templates/master.tpl")}"

  vars {
    puppet_master_host = "puppet-master-${var.name}.novalocal"
    ssh_key = "${file("~/.ssh/id_rsa.pub")}"
    root_private_key = "${tls_private_key.master.private_key_pem}"
    root_public_key = "${tls_private_key.master.public_key_openssh}"
    puppet_environment = "${var.puppet_environment}"
  }
}

resource "openstack_compute_instance_v2" "puppet_master" {
  name = "puppet-master-${var.name}"
  flavor_name = "${var.flavor}"
  image_name = "${var.image_name}"
  key_pair = "${openstack_compute_keypair_v2.puppet-machine-keypair.name}"
  user_data = "${data.template_file.master.rendered}"

  network {
    name = "${var.network_name}"
  }
}

resource "null_resource" "check_puppet_master" {

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/data/result.json ]; do sleep 1; done"
    ]

    connection {
      timeout = "10m"
      type = "ssh"
      user = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
      host = "${openstack_compute_floatingip_associate_v2.puppet_master_float_ip.floating_ip}"
    }
  }
}

output "master_address" {
  value = "${openstack_compute_floatingip_associate_v2.puppet_master_float_ip.floating_ip}"
}
