# Create a router that connects internal networks to the external network
resource "openstack_networking_router_v2" "tf_router" {
  name                = "tf-router"  # Name of the router
  admin_state_up      = "true"       # Router is enabled/active
  external_network_id = data.openstack_networking_network_v2.ext_net.id  # Connects to the external/public network
}

# Define a private network
resource "openstack_networking_network_v2" "tf_net" {
  name           = "tf-net"   # Name of the internal network
  admin_state_up = "true"     # Network is enabled/active
  shared         = "false"    # Not shared with other tenants/projects
}

# Create a subnet inside the private network
resource "openstack_networking_subnet_v2" "tf_subnet" {
  name            = "tf-subnet"                        # Subnet name
  network_id      = openstack_networking_network_v2.tf_net.id  # Attach to the tf-net network
  cidr            = "172.19.0.0/24"                    # Subnet range (256 IPs)
  ip_version      = 4                                  # IPv4 subnet
  enable_dhcp     = "true"                             # Enable DHCP for automatic IP assignment
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]             # DNS servers for instances
}

# Attach the subnet to the router (creates the internal interface)
resource "openstack_networking_router_interface_v2" "tf_router_iface_internal" {
  router_id = openstack_networking_router_v2.tf_router.id  # Router to connect
  subnet_id = openstack_networking_subnet_v2.tf_subnet.id  # Subnet to attach
}
