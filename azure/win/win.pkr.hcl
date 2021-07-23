/*
NOTE: This Packer build can be used to create windows images
      - Set Ansible playbook variable to alter image to suit needs
*/

source "azure-arm" "winserv" {
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
    image_version       = "${var.vmConfigs.sharedImageGallery.image_version}-{{timestamp}}"
    replication_regions = "${var.vmConfigs.sharedImageGallery.replication_regions}"
  }

  vm_size      = "${var.vmConfigs.vmSize}"
  winrm_username = "${var.winrmConfigs.winrmUser}"
  winrm_password = "${var.winrmConfigs.winrmPass}"
  user_data_file = "${var.vmConfigs.usrDataFile}"

}

build {
  sources = ["source.azure-arm.winserv"]

    provisioner "powershell" {
    script = "./conf/ConfigureWinRM.ps1"
    only   = ["azure-arm.azWindowsNode"]
  }

  provisioner "ansible" {
    playbook_file = "${var.playbookPath}"
    extra_arguments = [
      "-vvv"
    ]
  }

provisioner "powershell" {
   inline = [
        "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
        "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
   ]
}