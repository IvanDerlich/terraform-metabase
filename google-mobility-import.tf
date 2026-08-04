locals {
  google_mobility_dump_path = "${path.module}/google-mobility.sql.gz"
}

resource "terraform_data" "upload_google_mobility_dump" {
  depends_on = [
    terraform_data.wait_vm_db_cloud_init,
  ]

  triggers_replace = [
    openstack_compute_instance_v2.vm_db.id,
    filesha256(local.google_mobility_dump_path),
    sha256(local.db_init_script),
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
    agent       = true

    bastion_host = openstack_networking_floatingip_v2.tf_bastion_fip.address
    bastion_user = "ubuntu"
  }

  provisioner "file" {
    source      = local.google_mobility_dump_path
    destination = "/home/ubuntu/google-mobility.sql.gz"
  }
}
