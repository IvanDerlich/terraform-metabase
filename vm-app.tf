resource "openstack_compute_instance_v2" "vm_app" {
  name              = "tf_app"
  image_id          = data.openstack_images_image_v2.ubuntu_2604.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = [openstack_networking_secgroup_v2.tf_sg_app.name]
  availability_zone = "nodos-amd-2022"

  user_data = templatefile("${path.module}/templates/vm-app.init.sh", {
    db_ip              = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
    fe_fip             = openstack_networking_floatingip_v2.tf_fe_fip.address
    fe_url             = "https://${replace(openstack_networking_floatingip_v2.tf_fe_fip.address, ".", "-")}.int.cloud.um.edu.ar/"
    setup_first_name    = var.metabase_setup_first_name
    setup_last_name     = var.metabase_setup_last_name
    setup_email         = var.metabase_setup_email
    setup_password      = var.metabase_setup_password
  })

  network {
    uuid = openstack_networking_network_v2.tf_net.id
  }

  depends_on = [
    openstack_networking_subnet_v2.tf_subnet,
  ]
}