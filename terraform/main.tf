provider "local" {}

resource "local_file" "ssh_config" {
  filename = "${path.module}/ssh_config"
  content = <<-EOT
    Host vagrant
      HostName 127.0.0.1
      Port 2222
      User vagrant
      StrictHostKeyChecking no
      PasswordAuthentication no
      IdentityFile "${path.module}/.vagrant/machines/default/virtualbox/private_key"
  EOT
}

resource "null_resource" "vagrant" {
  provisioner "local-exec" {
    command = "vagrant init geerlingguy/ubuntu2004 && vagrant up"
    working_dir = "${path.module}"
  }
}

resource "null_resource" "ansible_provisioner" {
  provisioner "local-exec" {
    command     = "ansible-playbook -i ../hosts ../playbook.yaml"
    working_dir = path.module
  }
}