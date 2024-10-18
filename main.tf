##########################################
#       Terraform Proxmox Tutorial       #
##########################################

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_api_url           = var.pm_api_url
  pm_api_token_id      = var.pm_api_token_id
  pm_api_token_secret  = var.pm_api_token_secret
  pm_tls_insecure      = var.pm_tls_insecure
}


# resource is formatted to be "[type]" "[entity_name]"
# Define the VM ID range for the database and app servers
variable "db_vm_id_start" {
  default = 301
}

variable "app_vm_id_start" {
  default = 401
}

# Proxmox VM configuration for Database Servers
resource "proxmox_vm_qemu" "db_servers" {
  count        = 1
  name         = "db-server-${count.index + 1}"
  target_node  = "pve"
  vmid         = var.db_vm_id_start + count.index
  clone        = var.db_template  # Ensure this template has an OS
  agent        = 1
  os_type      = "cloud-init"
  cores        = 2
  memory       = 2048
  sockets      = 1
  cpu          = "host"
  full_clone   = true
  numa         = true
  scsihw       = "virtio-scsi-pci"
  ciuser       = "user"
  cipassword   = "user"

  # Ensure scsi0 is bootable
  bootdisk     = "scsi0"
  boot         = "order=scsi0"

  # Main disk with adequate size for OS
  disk {
    slot       = "scsi0"
    size       = "10G"  # Adjust size as needed for the OS
    type       = "disk"
    storage    = "local-lvm"
    iothread   = false
  }

  # Cloud-init drive for VM initialization
  disk {
    slot       = "ide2"
    type       = "cloudinit"
    storage    = "local-lvm"
  }

  network {
    model      = "virtio"
    bridge     = "vmbr0"
    firewall   = false
  }

  serial {
    id         = 0
  }

  lifecycle {
    ignore_changes = [network]
  }

  ipconfig0 = "ip=192.168.1.13${count.index+1}/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  onboot = true

provisioner "remote-exec" {
    inline = [
      "sleep 60",  # Wait for 60seconds before starting the SSH modifications
      "sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo systemctl restart ssh"
    ]

    connection {
      type        = "ssh"
      user        = "user"
      private_key = file("/home/buffalo/.ssh/id_rsa")
      host        = "192.168.1.131"
      password    = "user"
    }
  }
}

# Proxmox VM configuration for Application Servers
resource "proxmox_vm_qemu" "app_servers" {
  count        = 1
  name         = "app-server-${count.index + 1}"
  target_node  = "pve"
  vmid         = var.app_vm_id_start + count.index
  clone        = var.app_template  # Ensure this template has an OS
  agent        = 1
  os_type      = "cloud-init"
  cores        = 2
  memory       = 2048
  sockets      = 1
  cpu          = "host"
  full_clone   = true
  numa         = true
  scsihw       = "virtio-scsi-pci"
  ciuser       = "user"
  cipassword   = "user"


  # Ensure scsi0 is bootable
  bootdisk     = "scsi0"
  boot         = "order=scsi0"

  # Main disk with adequate size for OS
  disk {
    slot       = "scsi0"
    size       = "10G"  # Adjust size as needed for the OS
    type       = "disk"
    storage    = "local-lvm"
    iothread   = false
  }

  # Cloud-init drive for VM initialization
  disk {
    slot       = "ide2"
    type       = "cloudinit"
    storage    = "local-lvm"
  }

  network {
    model      = "virtio"
    bridge     = "vmbr0"
  }

  serial {
    id         = 0
  }

  lifecycle {
    ignore_changes = [network]
  }

  ipconfig0 = "ip=192.168.1.14${count.index+1}/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  onboot = true

  provisioner "remote-exec" {
    inline = [
      "sleep 60",  # Wait for 60seconds before starting the SSH modifications
      "sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo systemctl restart ssh"
    ]

    connection {
      type        = "ssh"
      user        = "user"
      private_key = file("/home/buffalo/.ssh/id_rsa")
      host        = "192.168.1.141"
      password    = "user"
    }
  }
}

output "db_server_ips" {
  value = [for server in proxmox_vm_qemu.db_servers : split("/", split("=", server.ipconfig0)[1])[0]]
}

output "app_server_ips" {
  value = [for server in proxmox_vm_qemu.app_servers : split("/", split("=", server.ipconfig0)[1])[0]]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory"

  content = <<EOL
[db_servers]
${element(split("/", split("=", proxmox_vm_qemu.db_servers[0].ipconfig0)[1]), 0)} ansible_user=user ansible_ssh_private_key_file=/home/buffalo/.ssh/id_rsa

[app_servers]
${element(split("/", split("=", proxmox_vm_qemu.app_servers[0].ipconfig0)[1]), 0)} ansible_user=user ansible_ssh_private_key_file=/home/buffalo/.ssh/id_rsa
EOL
}

resource "null_resource" "wait_for_db" {
  provisioner "local-exec" {
    command = "sleep 60"  # Wait for 30 seconds before running the playbook
  }
  depends_on = [
    proxmox_vm_qemu.db_servers
  ]
}

resource "null_resource" "ansible_playbook_db" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/inventory ${path.module}/playbooks/install_mysql.yml"
  }
  
  depends_on = [
    null_resource.wait_for_db,
    proxmox_vm_qemu.db_servers
  ]
}

resource "null_resource" "wait_for_app" {
  provisioner "local-exec" {
    command = "sleep 60"  # Wait for 30 seconds before running the playbook
  }
  depends_on = [
    proxmox_vm_qemu.app_servers
  ]
}

resource "null_resource" "ansible_playbook_app" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/inventory ${path.module}/playbooks/install_docker_nginx.yml"
  }
  
  depends_on = [
    null_resource.wait_for_app,
    proxmox_vm_qemu.app_servers
  ]
}

