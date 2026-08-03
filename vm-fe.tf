resource "openstack_compute_instance_v2" "vm_fe" {
  name              = "tf_fe"
  image_id          = data.openstack_images_image_v2.srv_nginx_ubuntu2404.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = ["default"]
  availability_zone = "nodos-amd-2022"

 network {
    name = "tf-net"
  }

  depends_on = [
    openstack_networking_subnet_v2.tf_subnet,
  ]
}

data "openstack_networking_port_v2" "vm_fe_port" {
  device_id  = openstack_compute_instance_v2.vm_fe.id
  network_id = openstack_compute_instance_v2.vm_fe.network.0.uuid
}

resource "openstack_networking_floatingip_associate_v2" "vm_fe_fip" {
  floating_ip = openstack_networking_floatingip_v2.tf_fe_fip.address
  port_id     = data.openstack_networking_port_v2.vm_fe_port.id
}
