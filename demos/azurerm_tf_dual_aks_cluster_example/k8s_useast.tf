# Create private key for the kubernetes cluster
resource "tls_private_key" "key_east" {
  algorithm   = "RSA"
}

# Save the private key in the local workspace
resource "null_resource" "save-key-east" {
  triggers = { key = tls_private_key.key_east.private_key_pem }

  # Use 'local-exec' to put the key in local .ssh folder and set perms
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.key_east.private_key_pem}" > ${path.module}/.ssh/id_rsa
      chmod 0600 ${path.module}/.ssh/id_rsa
EOF
  }
}

# Create the resource group for our k8s environment
resource "azurerm_resource_group" "k8s_east" {
  name     = var.resource_group_name_east
  location = var.location_east

  tags = { Environment = var.environment_tag, build = var.build_tag }
}

# Create the k8s cluster
resource "azurerm_kubernetes_cluster" "k8s_east" {
  name                = var.cluster_name_east
  location            = azurerm_resource_group.k8s_east.location
  resource_group_name = azurerm_resource_group.k8s_east.name
  dns_prefix          = var.dns_prefix_east

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = "${trimspace(tls_private_key.key_east.public_key_openssh)} ${var.admin_username}@azure.com"
    }
  }

  default_node_pool {
    name            = "default"
    node_count      = var.agent_count
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  tags = { Environment = var.environment_tag, build = var.build_tag }
}
