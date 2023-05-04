resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}
resource "yandex_vpc_subnet" "develop" {
  name           = var.vpc_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.default_cidr
}


data "yandex_compute_image" "centos" {
  family = "${var.vm_web_os}"
}
resource "yandex_compute_instance" "platform" {
  count = 2
  name        = "${ var.vm_web_platf }-${ var.vm_web_inst }-${count.index}"
#  platform_id = "${var.vm_web_platf}"
resources {
    cores         = var.vm_web_resources.cores
    memory        = var.vm_web_resources.memory
    core_fraction = var.vm_web_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos.image_id
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
  }

  metadata = {
    serial-port-enable = var.vm_metadata.serial-port-enable
    ssh-keys           = "centos:${local.ssh_key}"
  }
}

data "template_file" "config" {
 template = file("./config.yml")
 vars = {
 ssh_key = local.ssh_key
 }
}