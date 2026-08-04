resource "openstack_compute_instance_v2" "vm_db" {
  name              = "tf_db"
  image_id          = data.openstack_images_image_v2.ubuntu_2604.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_networking_secgroup_v2.tf_sg_db.name]
  availability_zone = "nodos-amd-2022"

  network {
    uuid = openstack_networking_network_v2.tf_net.id
  }

  depends_on = [
    openstack_networking_subnet_v2.tf_subnet,
  ]
}