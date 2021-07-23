/*
NOTE: To use this file correctly you must do the following
      *Use script with parameters for building only which build you want to run
      **This can be done like so "packer build -only 'build-azure.*' deploycloud.json.pkr.hcl" for running entire Azure build
      **This can be done like so "packer build -only '.azure-arm*' deploycloud.json.pkr.hcl" for only building AWS resources
      **This can be done like so "packer build -only 'build-azure.windowsNode' deploycloud.json.pkr.hcl" for running entire Azure build
*/

variable "azSpConfigs" {
  type = object({
    subId        = string
    clientId     = string
    clientSecret = string
    tenantId = string
  })
  sensitive = true
}

variable "usrDataFile" {
  type = map(object({
    dataFile = string
  }))
  sensitive = true
}

variable "azSshConfigs" {
  type = object({
    sshUser   = string
    sshPass   = string
    comMethod = string
  })
  sensitive = true
}

variable "azWinrmConfigs" {
  type = object({
    winrmUser     = string
    winrmPass     = string
    comMethod     = string
    winrmUseSsl   = string
    winrmInsecure = string
    winrmTimeout  = string
  })
  sensitive = true
}


variable "azVmConfigs" {
  type = map(object({
    vmSize         = string
    osType         = string
    ImgRgName      = string
    imageOffer     = string
    imagePublisher = string
    imageSku       = string
    location       = string
    imageName      = string
    namePrefix     = string
    azureTags = object({
      ApplicationName     = string
      Environment         = string
      DRTier              = string
      SupportResponseSLA  = string
      Location            = string
      WorkloadType        = string
      AppTypeRole         = string
      ProductCostCenter   = string
      NotificationContact = string
      DataProtection      = string
      Owner               = string
    })
  }))
}
##NOTE: This builds the RHEL image with Apache
source "azure-arm" "rhelNode" {
  subscription_id                   = "${var.azSpConfigs.subId}"
  tenant_id                         = "${var.azSpConfigs.tenantId}"
  client_id                         = "${var.azSpConfigs.clientId}"
  client_secret                     = "${var.azSpConfigs.clientSecret}"
  communicator                      = "${var.azSshConfigs.comMethod}"
  image_offer                       = "${var.azVmConfigs["rhel"].imageOffer}"
  image_publisher                   = "${var.azVmConfigs["rhel"].imagePublisher}"
  image_sku                         = "${var.azVmConfigs["rhel"].imageSku}"
  location                          = "${var.azVmConfigs["rhel"].location}"
  managed_image_name                = "${var.azVmConfigs["rhel"].imageName}-{{timestamp}}"
  managed_image_resource_group_name = "${var.azVmConfigs["rhel"].ImgRgName}"
  os_type                           = "${var.azVmConfigs["rhel"].osType}"
  azure_tags                        = "${var.azVmConfigs["rhel"].azureTags}"

  vm_size      = "${var.azVmConfigs["rhel"].vmSize}"
  ssh_username = "${var.azSshConfigs.sshUser}"
  ssh_password = "${var.azSshConfigs.sshPass}"

}
##NOTE:This builds the Windows Server image with IIS
source "azure-arm" "windowsNode" {
  subscription_id                   = "${var.azSpConfigs.subId}"
  tenant_id                         = "${var.azSpConfigs.tenantId}"
  client_id                         = "${var.azSpConfigs.clientId}"
  client_secret                     = "${var.azSpConfigs.clientSecret}"
  communicator                      = "${var.azWinrmConfigs.comMethod}"
  image_offer                       = "${var.azVmConfigs["windows"].imageOffer}"
  image_publisher                   = "${var.azVmConfigs["windows"].imagePublisher}"
  image_sku                         = "${var.azVmConfigs["windows"].imageSku}"
  location                          = "${var.azVmConfigs["windows"].location}"
  managed_image_name                = "${var.azVmConfigs["windows"].imageName}-{{timestamp}}"
  managed_image_resource_group_name = "${var.azVmConfigs["windows"].ImgRgName}"
  os_type                           = "${var.azVmConfigs["windows"].osType}"
  azure_tags                        = "${var.azVmConfigs["windows"].azureTags}"

  vm_size        = "${var.azVmConfigs["windows"].vmSize}"
  winrm_username = "${var.azWinrmConfigs.winrmUser}"
  winrm_password = "${var.azWinrmConfigs.winrmPass}"
  winrm_insecure = "${var.azWinrmConfigs.winrmInsecure}"
  winrm_use_ssl  = "${var.azWinrmConfigs.winrmUseSsl}"
  winrm_timeout  = "${var.azWinrmConfigs.winrmTimeout}"
}

##NOTE: This build only builds for Azure, use GoLang or script to call only this specific build
build {
  name = "build-azure"

  source "source.azure-arm.rhelNode" {
    name = "azRhelNode"
  }

  source "source.azure-arm.windowsNode" {
    name = "azWindowsNode"
  }

  provisioner "ansible" {
    only          = ["azure-arm.azRhelNode"]
    user          = "${var.azSshConfigs.sshUser}"
    playbook_file = "./ansible/playbooks/apacheplay.yml"
    extra_arguments = [
      "-vvv"
    ]
  }

  provisioner "shell" {
    only            = ["azure-arm.azRhelNode"]
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }

  provisioner "powershell" {
    script = "./conf/ConfigureWinRM.ps1"
    only   = ["azure-arm.azWindowsNode"]
  }
  /*
NOTE: The below provisioner will hang for a while before eventually running
      - The provisioner is setup to be run using HTTP
      - Traffic is not necessarily unencrypted using this method
      - This should not be used as a configuration for a production environment
        --> For production environments configure ssl, certs, etc...
*/
  provisioner "ansible" {
    playbook_file = "./ansible/playbooks/winfeatures.yml"
    use_proxy     = false
    user          = "${var.azWinrmConfigs.winrmUser}"
    extra_arguments = [
      "-vvv",
      "--extra-vars", "ansible_password=${var.azWinrmConfigs.winrmPass}"
    ]
    only = ["azure-arm.azWindowsNode"]
  }

  provisioner "powershell" {
    inline = [
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
    only = ["azure-arm.azWindowsNode"]
  }

}



