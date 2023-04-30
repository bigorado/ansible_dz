###cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "default_cidr2" {
  type        = list(string)
  default     = ["10.1.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}


variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network & subnet name"
}

variable "vpc_name2" {
  type        = string
  default     = "develop2"
  description = "VPC network & subnet name"
}


#SSH ключ
variable "ssh_key" {
  type        = string
  description = "Path to the ssh key file"
  default     = "~/.ssh/id_ed25519"
}

variable "vm_metadata" {
  type = map
  default = {
    serial-port-enable = 1
#    ssh-key            = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDSFLz5Ihh8FI+W2VZSFyIj5qEEbb/A3hQykKWjK2sth"
  }
}


#Замена перемекнных

variable "vm_db_os" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "ubuntu-2004-lts"
}

variable "vm_db_inst" {
  type        = string
  default     = "netology-develop-platform-db"
  description = "netology-develop-platform-db"
}

variable "vm_db_platf" {
  type        = string
  default     = "standard-v1"
  description = "standard-v1"
}

variable "vm_web_os" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "ubuntu-2004-lts"
}

variable "vm_web_inst" {
  type        = string
  default     = "netology-develop-platform-web"
  description = "netology-develop-platform-web"
}

variable "vm_web_platf" {
  type        = string
  default     = "standard-v1"
  description = "standard-v1"
}

variable "vm_web_resources" {
  type = map
  default = {
    cores          = 2
    memory         = 1
    core_fraction  = 5
  }
}

variable "vm_db_resources" {
  type = map
  default = {
    cores          = 2
    memory         = 2
    core_fraction  = 20
  }
}
