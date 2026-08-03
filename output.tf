locals {
  bastion_fip = openstack_networking_floatingip_v2.tf_bastion_fip.address
  fe_fip      = openstack_networking_floatingip_v2.tf_fe_fip.address
  site_url    = "https://${replace(openstack_networking_floatingip_v2.tf_fe_fip.address, ".", "-")}.int.cloud.um.edu.ar/"
  fe_ip       = openstack_compute_instance_v2.vm_fe.network.0.fixed_ip_v4
  app_ip      = openstack_compute_instance_v2.vm_app.network.0.fixed_ip_v4
  db_ip       = openstack_compute_instance_v2.vm_db.network.0.fixed_ip_v4
}

output "db_data" {
  value = {
    backup_cmd  = "./db-backup.sh ${local.bastion_fip} ${local.db_ip} ${local.app_ip} /tmp/db.dump"
    restore_cmd = "./db-restore.sh ${local.bastion_fip} ${local.db_ip} ${local.app_ip} /tmp/db.dump"
  }
}

output "vm_ssh" {
  value = {
    app = "ssh -o StrictHostKeyChecking=no -J ubuntu@${local.bastion_fip} ubuntu@${local.app_ip}"
    fe  = "ssh -o StrictHostKeyChecking=no -J ubuntu@${local.bastion_fip} ubuntu@${local.fe_ip}"
    db  = "ssh -o StrictHostKeyChecking=no -J ubuntu@${local.bastion_fip} ubuntu@${local.db_ip}"
  }
}

output "vm_fips" {
  value = {
    bastion_fip = local.bastion_fip
    fe_fip      = local.fe_fip
  }
}

output "vm_ips" {
  value = {
    app_ip = local.app_ip
    db_ip  = local.db_ip
    fe_ip  = local.fe_ip
  }
}

output "vm_urls" {
  value = {
    site_url = local.site_url
  }
}
