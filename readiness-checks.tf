locals {
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
    db = {
      instance_id = openstack_compute_instance_v2.vm_db.id
      host_ip     = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
    }
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
