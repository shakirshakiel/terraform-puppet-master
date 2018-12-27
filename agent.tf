resource "openstack_networking_floatingip_v2" "puppet_agent_floatingip" {
  count = "${var.agent_num}"
  pool = "${var.pool}"
}

resource "openstack_compute_floatingip_associate_v2" "puppet_agent_float_ip" {
  count = "${var.agent_num}"
  floating_ip = "${element(openstack_networking_floatingip_v2.puppet_agent_floatingip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.puppet_agent.*.id, count.index)}"
  fixed_ip = "${element(openstack_compute_instance_v2.puppet_agent.*.network.0.fixed_ip_v4, count.index)}"
}

data "template_file" "agent" {
  count = "${var.agent_num}"
  template = "${file("templates/agent.tpl")}"

  vars {
    puppet_master_ip = "${openstack_compute_floatingip_associate_v2.puppet_master_float_ip.floating_ip}"
    puppet_master_host = "${openstack_compute_instance_v2.puppet_master.name}.novalocal"
    ssh_key = "${file("~/.ssh/id_rsa.pub")}"
    master_ssh_pub_key = "${file("master-ssh-key/id_rsa.pub")}"
  }
}

resource "openstack_compute_instance_v2" "puppet_agent" {
  count = "${var.agent_num}"
  name = "puppet-agent-${var.name}-${count.index+1}"
  flavor_name = "${var.flavor}"
  image_name = "${var.image_name}"
  key_pair = "${openstack_compute_keypair_v2.puppet-machine-keypair.name}"
  user_data = "${data.template_file.agent.*.rendered[count.index]}"

  network {
    name = "${var.network_name}"
  }
}

output "agent_address" {
  value = "${join(" ", openstack_compute_floatingip_associate_v2.puppet_agent_float_ip.*.floating_ip)}"
}
