data "openstack_images_image_v2" "ubuntu_2404" {
  name        = "ubuntu_2404"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 2048
}

resource "openstack_compute_instance_v2" "terraform_vm" {
  name              = "caso3-test machine"
  image_id          = data.openstack_images_image_v2.ubuntu_2404.id
  flavor_id         = data.openstack_compute_flavor_v2.small.id
  key_pair          = var.key_name
  security_groups   = ["default"]
  availability_zone = "nodos-amd-2022"

  network {
    name = "net_umstack"
  }
}