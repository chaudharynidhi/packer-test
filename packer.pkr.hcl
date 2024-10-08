packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


variable "region" {
  type    = string
  default = "us-east-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "firstrun-windows" {
  ami_name      = "packer-windows-demo-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "t2.large"
  region        = "${var.region}"

  launch_block_device_mappings {
      device_name = "/dev/sdp"
      encrypted = true
      kms_key_id = "10be92fe-b02f-4242-b3da-f0dff5d5c4b3"
      snapshot_id = "snap-072984d07b06a5322"
      volume_type = "gp2"
      delete_on_termination = false
  }

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-2024.09.11"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  user_data_file = "./bootstrap_win.txt"
  winrm_password = "SuperS3cr3t!!!!"
  winrm_username = "Administrator"
}

build {
  name    = "learn-packer"
  sources = ["source.amazon-ebs.firstrun-windows"]
  

  provisioner "powershell" {
    environment_vars = ["DEVOPS_LIFE_IMPROVER=PACKER"]
    inline           = ["Write-Host \"HELLO NEW USER; WELCOME TO $Env:DEVOPS_LIFE_IMPROVER\"", "Write-Host \"You need to use backtick escapes when using\"", "Write-Host \"characters such as DOLLAR`$ directly in a command\"", "Write-Host \"or in your own scripts.\""]
  }
  provisioner "windows-restart" {
  }
  provisioner "powershell" {
    environment_vars = ["VAR1=A$Dollar", "VAR2=A`Backtick", "VAR3=A'SingleQuote", "VAR4=A\"DoubleQuote"]
    script           = "./tally_instance.ps1"
  }
}