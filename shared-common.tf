data "openstack_networking_network_v2" "ext_net" {
  name = "ext_net"
}

data "openstack_images_image_v2" "ubuntu_2604" {
  name        = "ubuntu_2604"
  most_recent = true
}

data "openstack_images_image_v2" "srv_nginx_ubuntu2404" {
  name        = "srv-nginx-ubuntu2404"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 2048
}