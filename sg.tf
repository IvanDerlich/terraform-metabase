# ==============================================================================
# Security Group: Bastion
# ==============================================================================

resource "openstack_networking_secgroup_v2" "tf_sg_bastion" {
  name        = "tf_sg_bastion"
  description = "tf_sg_bastion"
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_bastion_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "Allow ICMP from anywhere to bastion"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.tf_sg_bastion.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_bastion_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow SSH from anywhere to bastion"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.tf_sg_bastion.id
}

# ==============================================================================
# Security Group: Frontend (fe)
# ==============================================================================

resource "openstack_networking_secgroup_v2" "tf_sg_fe" {
  name        = "tf_sg_fe"
  description = "tf_sg_fe"
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_fe_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "Allow ICMP from anywhere to frontend"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.tf_sg_fe.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_fe_ssh_from_bastion" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow SSH from bastion to frontend"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_bastion.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_fe.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_fe_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow HTTP from anywhere to frontend"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.tf_sg_fe.id
}

# ==============================================================================
# Security Group: Application (app)
# ==============================================================================

resource "openstack_networking_secgroup_v2" "tf_sg_app" {
  name        = "tf_sg_app"
  description = "tf_sg_app"
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_app_icmp_from_bastion" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "Allow ICMP from bastion to application"
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_bastion.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_app.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_app_icmp_from_fe" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "Allow ICMP from frontend to application"
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_fe.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_app.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_app_ssh_from_bastion" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow SSH from bastion to application"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_bastion.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_app.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_app_port_3000_from_fe" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow TCP 3000 from frontend to application"
  port_range_min    = 3000
  port_range_max    = 3000
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_fe.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_app.id
}

# ==============================================================================
# Security Group: Database (db)
# ==============================================================================

resource "openstack_networking_secgroup_v2" "tf_sg_db" {
  name        = "tf_sg_db"
  description = "tf_sg_db"
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_db_icmp_from_app" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "Allow ICMP from application to database"
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_app.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_db.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_db_icmp_from_bastion" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "Allow ICMP from bastion to database"
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_bastion.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_db.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_db_ssh_from_bastion" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow SSH from bastion to database"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_bastion.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_db.id
}

resource "openstack_networking_secgroup_rule_v2" "tf_sg_db_mysql_from_app" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "Allow MySQL from application to database"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = openstack_networking_secgroup_v2.tf_sg_app.id
  security_group_id = openstack_networking_secgroup_v2.tf_sg_db.id
}