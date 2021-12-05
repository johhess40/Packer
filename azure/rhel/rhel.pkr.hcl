/*
This Packer build creates a DNS forwarder
*/


source "azure-arm" "rheldns" {
  azure_tags = {
    Environment = "${var.envTag}"
    Owner       = "${var.ownerTag}"
    vmType      = "${var.vmType}"

  }
  client_id                         = "${var.spConfigs.clientId}"
  client_secret                     = "${var.spConfigs.clientSecret}"
  subscription_id                   = "${var.spConfigs.subId}"
  tenant_id                         = "${var.spConfigs.tenantId}"
  communicator                      = "${var.sshConfigs.comMethod}"
  image_offer                       = "${var.vmConfigs.imageOffer}"
  image_publisher                   = "${var.vmConfigs.imagePublisher}"
  image_sku                         = "${var.vmConfigs.imageSku}"
  location                          = "${var.vmConfigs.location}"
  managed_image_name                = "${var.vmConfigs.imageName}"
  managed_image_resource_group_name = "${var.vmConfigs.ImgRgName}"
  os_type                           = "${var.vmConfigs.osType}"
  shared_image_gallery_destination {
    subscription        = "${var.vmConfigs.sharedImageGallery.subscription}"
    resource_group      = "${var.vmConfigs.sharedImageGallery.resource_group}"
    gallery_name        = "${var.vmConfigs.sharedImageGallery.gallery_name}"
    image_name          = "${var.vmConfigs.sharedImageGallery.image_name}"
    image_version       = "${var.vmConfigs.sharedImageGallery.image_version}"
    replication_regions = "${var.vmConfigs.sharedImageGallery.replication_regions}"
  }

  vm_size      = "${var.vmConfigs.vmSize}"
  ssh_username = "${var.sshConfigs.sshUser}"
  ssh_password = "${var.sshConfigs.sshPass}"

}

build {
  sources = ["source.azure-arm.rheldns"]

  provisioner "ansible" {
    playbook_file = "${var.playbookPath}"
    extra_arguments = [
      "-vvv"
    ]
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }
}
