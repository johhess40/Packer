variable "envTag" {
  type = string
}
variable "ownerTag" {
  type = string
}
variable "vmType" {
  type = string
}

variable "playbookPath" {
  type = string
}

variable "spConfigs" {
  type = object({
    clientId     = string
    clientSecret = string
    subId        = string
    tenantId     = string
  })
  sensitive = true
}

variable "sshConfigs" {
  type = object({
    sshUser   = string
    sshPass   = string
    comMethod = string
  })
}

variable "vmConfigs" {
  type = object({
    vmSize         = string
    osType         = string
    ImgRgName      = string
    imageOffer     = string
    imagePublisher = string
    imageSku       = string
    location       = string
    imageName      = string
    namePrefix     = string
    sharedImageGallery = object({
      subscription        = string
      resource_group      = string
      gallery_name        = string
      image_name          = string
      image_version       = string
      replication_regions = list(string)
    })
  })
}