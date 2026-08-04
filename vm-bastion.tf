resource "openstack_compute_instance_v2" "vm_bastion" {
  name              = "tf_bastion"
  image_id          = data.openstack_images_image_v2.ubuntu_2604.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_networking_secgroup_v2.tf_sg_bastion.name]
  availability_zone = "nodos-amd-2022"

 network {
   uuid = openstack_networking_network_v2.tf_net.id
  }

  depends_on = [
    openstack_networking_subnet_v2.tf_subnet,
  ]
}

data "openstack_networking_port_v2" "vm_bastion_port" {
  device_id  = openstack_compute_instance_v2.vm_bastion.id
  network_id = openstack_compute_instance_v2.vm_bastion.network.0.uuid
}

resource "openstack_networking_floatingip_associate_v2" "vm_bastion_fip" {
  floating_ip = openstack_networking_floatingip_v2.tf_bastion_fip.address
  port_id     = data.openstack_networking_port_v2.vm_bastion_port.id
}
