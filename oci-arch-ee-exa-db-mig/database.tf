## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_database_cloud_exadata_infrastructure" "exacs_infra" {
  availability_domain = var.availability_domain_name == "" ? data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain_number]["name"] : var.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = var.exacs_infra_display_name
  compute_count       = var.exacs_x8_infra ? var.exacs_infra_compute_count : null
  maintenance_window {
    hours_of_day   = []
    preference     = "NO_PREFERENCE"
    weeks_of_month = [var.exacs_infra_maintenance_window_weeks_of_month]
  }
  shape         = var.exacs_infra_shape
  storage_count = var.exacs_x8_infra ? var.exacs_infra_storage_count : null
  lifecycle {
    ignore_changes = [maintenance_window[0].weeks_of_month]
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_database_cloud_vm_cluster" "exacs_vm_cluster" {
  backup_subnet_id                = oci_core_subnet.subnet_3.id
  cloud_exadata_infrastructure_id = oci_database_cloud_exadata_infrastructure.exacs_infra.id
  cluster_name                    = var.exacs_vm_cluster_name
  compartment_id                  = var.compartment_ocid
  cpu_core_count                  = var.exacs_vm_cluster_cpu_core_count
  ocpu_count                      = var.exacs_vm_cluster_ocpu_count
  data_storage_percentage         = var.exacs_vm_cluster_data_storage_percentage
  display_name                    = var.exacs_vm_cluster_display_name
  gi_version                      = var.exacs_vm_cluster_gi_version == "" ? data.oci_database_gi_versions.gi_version.gi_versions.0.version : var.exacs_vm_cluster_gi_version
  hostname                        = var.exacs_vm_cluster_hostname
  license_model                   = var.exacs_vm_cluster_license_model
  nsg_ids                         = [oci_core_network_security_group.dbclnsg.id]
  ssh_public_keys                 = var.ssh_public_key == "" ? [tls_private_key.public_private_key_pair.public_key_openssh] : [tls_private_key.public_private_key_pair.public_key_openssh, var.ssh_public_key]
  subnet_id                       = oci_core_subnet.subnet_2.id
  lifecycle {
    ignore_changes = [ssh_public_keys, defined_tags]
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_database_db_home" "exacs_db_home" {
  vm_cluster_id = oci_database_cloud_vm_cluster.exacs_vm_cluster.id

  database {
    admin_password      = var.starter_db_admin_password
    db_name             = var.starter_db_name
    character_set       = var.starter_db_character_set
    ncharacter_set      = var.starter_db_n_character_set
    db_workload         = var.starter_db_workload
    pdb_name            = var.starter_db_pdb_name
    db_backup_config {
      auto_backup_enabled = false
    }
    defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  }

  # VM_CLUSTER_BACKUP can also be specified as a source for cloud VM clusters.
  source       = "VM_CLUSTER_NEW"
  db_version   = var.starter_db_version
  display_name = var.starter_db_name

  lifecycle {
    ignore_changes = [defined_tags]
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
} 


