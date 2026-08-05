locals {
  vm_cloud_init_targets = {
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

resource "terraform_data" "wait_vm_bastion_cloud_init" {
  depends_on = [
    openstack_networking_floatingip_associate_v2.vm_bastion_fip,
    openstack_compute_instance_v2.vm_bastion,
  ]

  triggers_replace = [
    openstack_compute_instance_v2.vm_bastion.id,
    openstack_networking_floatingip_v2.tf_bastion_fip.address,
  ]

  connection {
    type    = "ssh"
    user    = "ubuntu"
    host    = openstack_networking_floatingip_v2.tf_bastion_fip.address
    agent   = true
    timeout = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait >/dev/null 2>&1 || (echo 'cloud-init failed'; sudo cloud-init status --long || true; echo '--- /var/log/cloud-init-output.log ---'; sudo tail -n 200 /var/log/cloud-init-output.log || true; echo '--- /var/log/cloud-init.log ---'; sudo tail -n 200 /var/log/cloud-init.log || true; echo '--- build-log ---'; sudo cat /home/ubuntu/build-log-*.log 2>/dev/null || true; exit 1)",
    ]
  }
}

resource "terraform_data" "wait_vm_db_cloud_init" {
  depends_on = [
    terraform_data.wait_vm_bastion_cloud_init,
    openstack_compute_instance_v2.vm_db,
  ]

  triggers_replace = [
    openstack_compute_instance_v2.vm_db.id,
  ]

  connection {
    type    = "ssh"
    user    = "ubuntu"
    host    = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
    agent   = true
    timeout = "10m"

    bastion_host = openstack_networking_floatingip_v2.tf_bastion_fip.address
    bastion_user = "ubuntu"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait >/dev/null 2>&1 || { echo '--- build-log ---'; sudo cat /home/ubuntu/build-log-*.log 2>/dev/null || true; exit 1; }",
    ]
  }
}

resource "terraform_data" "wait_vm_cloud_init" {
  for_each = local.vm_cloud_init_targets

  depends_on = [
    terraform_data.wait_vm_bastion_cloud_init,
  ]

  triggers_replace = [
    each.value.instance_id,
  ]

  connection {
    type    = "ssh"
    user    = "ubuntu"
    host    = each.value.host_ip
    agent   = true
    timeout = "10m"

    bastion_host = openstack_networking_floatingip_v2.tf_bastion_fip.address
    bastion_user = "ubuntu"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait >/dev/null 2>&1 || (echo 'cloud-init failed'; sudo cloud-init status --long || true; echo '--- /var/log/cloud-init-output.log ---'; sudo tail -n 200 /var/log/cloud-init-output.log || true; echo '--- /var/log/cloud-init.log ---'; sudo tail -n 200 /var/log/cloud-init.log || true; echo '--- build-log ---'; sudo cat /home/ubuntu/build-log-*.log 2>/dev/null || true; exit 1)",
    ]
  }
}

