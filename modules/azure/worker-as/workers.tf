resource "azurerm_availability_set" "tectonic_workers" {
  name                = "${var.cluster_name}-workers"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  managed             = true

  tags = "${merge(map(
    "Name", "${var.cluster_name}-workers",
    "tectonicClusterID", "${var.cluster_id}"),
    var.extra_tags)}"
}

resource "azurerm_virtual_machine" "tectonic_worker" {
  count                 = "${var.worker_count}"
  name                  = "${var.cluster_name}-worker-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${var.network_interface_ids[count.index]}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.tectonic_workers.id}"

  # boot_diagnostics {
  #   enabled     = true
  #   storage_uri = "${azurerm_storage_account.tectonic_worker.primary_blob_endpoint}"
  # }

  storage_image_reference {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "${var.cl_channel}"
    version   = "latest"
  }
  storage_os_disk {
    name              = "worker-${count.index}-os-${var.storage_id}"
    managed_disk_type = "${var.storage_type}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "linux"
  }
  os_profile {
    computer_name  = "${var.cluster_name}-worker-${count.index}"
    admin_username = "core"
    admin_password = ""
    custom_data    = "${base64encode("${data.ignition_config.worker.rendered}")}"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/core/.ssh/authorized_keys"
      key_data = "${file(var.public_ssh_key)}"
    }
  }
  tags = "${merge(map(
    "Name", "${var.cluster_name}-worker-${count.index}",
    "tectonicClusterID", "${var.cluster_id}"),
    var.extra_tags)}"
  lifecycle {
    ignore_changes = ["storage_data_disk"]
  }
}
