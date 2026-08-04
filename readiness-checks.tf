locals {
  db_init_script = templatefile("${path.module}/templates/vm-db.init.sh", {
    db_password = var.pg_postgres_password
  })

  vm_cloud_init_targets = {
    bastion = {
      instance_id = openstack_compute_instance_v2.vm_bastion.id
      host_ip     = openstack_compute_instance_v2.vm_bastion.network.0.fixed_ip_v4
    }
    fe = {
      instance_id = openstack_compute_instance_v2.vm_fe.id
      host_ip     = openstack_compute_instance_v2.vm_fe.network.0.fixed_ip_v4
    }
    app = {
      instance_id = openstack_compute_instance_v2.vm_app.id
      host_ip     = openstack_compute_instance_v2.vm_app.network.0.fixed_ip_v4
    }
  }
}

resource "terraform_data" "run_vm_db_init_after_upload" {
  depends_on = [
    terraform_data.upload_google_mobility_dump,
    terraform_data.wait_vm_db_cloud_init,
  ]

  triggers_replace = [
    openstack_compute_instance_v2.vm_db.id,
    filesha256("${path.module}/google-mobility.sql.gz"),
    sha256(local.db_init_script),
  ]

  connection {
    type  = "ssh"
    user  = "ubuntu"
    host  = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
    agent = true

    bastion_host = openstack_networking_floatingip_v2.tf_bastion_fip.address
    bastion_user = "ubuntu"
  }

  provisioner "file" {
    content     = local.db_init_script
    destination = "/home/ubuntu/vm-db.init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -euo pipefail",
      "chmod +x /home/ubuntu/vm-db.init.sh",
      "sudo /home/ubuntu/vm-db.init.sh",
    ]
  }
}

resource "terraform_data" "wait_vm_cloud_init" {
  for_each = local.vm_cloud_init_targets

  depends_on = [
    openstack_networking_floatingip_associate_v2.vm_bastion_fip,
  ]

  triggers_replace = [
    each.value.instance_id,
  ]

  connection {
    type  = "ssh"
    user  = "ubuntu"
    host  = each.value.host_ip
    agent = true

    bastion_host = openstack_networking_floatingip_v2.tf_bastion_fip.address
    bastion_user = "ubuntu"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait >/dev/null 2>&1",
    ]
  }
}

resource "terraform_data" "wait_vm_db_cloud_init" {
  depends_on = [
    openstack_networking_floatingip_associate_v2.vm_bastion_fip,
    openstack_compute_instance_v2.vm_db,
  ]

  triggers_replace = [
    openstack_compute_instance_v2.vm_db.id,
  ]

  connection {
    type  = "ssh"
    user  = "ubuntu"
    host  = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
    agent = true

    bastion_host = openstack_networking_floatingip_v2.tf_bastion_fip.address
    bastion_user = "ubuntu"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait >/dev/null 2>&1",
    ]
  }
}

resource "terraform_data" "wait_vm_db_readiness_check" {
  depends_on = [
    terraform_data.run_vm_db_init_after_upload,
  ]

  triggers_replace = [
    terraform_data.run_vm_db_init_after_upload.id,
  ]
}
