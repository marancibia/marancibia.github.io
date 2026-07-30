# Copyright © 2026, Oracle and/or its affiliates.
# All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_core_services" "sgw_services" {
  filter {
    name   = "cidr_block"
    values = ["all-.*-services-in-oracle-services-network"]
    regex  = true
  }
}

data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}

data "oci_database_autonomous_database" "existing_adb" {
  count                  = local.is_update_existing ? 1 : 0
  autonomous_database_id = var.existing_autonomous_database_id
}

locals {
  is_update_existing      = var.adb_operation_mode == "Update an existing Autonomous AI Database by adding the demo Data and AI Application"
  effective_schema_name   = trimspace(var.u_name) != "" ? upper(trimspace(var.u_name)) : "MOVIESTREAM"
  effective_user_password = trimspace(var.u_pwd) != "" ? trimspace(var.u_pwd) : "watchS0meMovies#"
  effective_admin_password = local.is_update_existing ? (
    trimspace(var.existing_db_admin_password) != "" ? var.existing_db_admin_password : var.db_password
  ) : var.db_password
  effective_wallet_password = local.is_update_existing ? (
    trimspace(var.existing_db_wallet_password) != "" ? var.existing_db_wallet_password : local.effective_admin_password
  ) : var.db_password
  effective_db_name = local.is_update_existing ? data.oci_database_autonomous_database.existing_adb[0].db_name : var.db_name
  ad_names          = compact([for ad in data.oci_identity_availability_domains.ADs.availability_domains : ad.name])

  selected_db_connection   = local.is_update_existing ? try(data.oci_database_autonomous_database.existing_adb[0].connection_strings, []) : module.adb.db_connection
  selected_connection_urls = local.is_update_existing ? try(data.oci_database_autonomous_database.existing_adb[0].connection_urls, []) : []
  selected_database_fully_qualified_name = local.is_update_existing ? try(
    trimprefix(split("/graphstudio", lower(local.selected_connection_urls[0].graph_studio_url))[0], "https://"),
    ""
  ) : module.adb.database_fully_qualified_name
  selected_database_actions_url    = local.is_update_existing ? try([local.selected_connection_urls[0].sql_dev_web_url], []) : module.adb.url
  selected_graph_studio_url        = local.is_update_existing ? try([local.selected_connection_urls[0].graph_studio_url], []) : module.adb.graph_studio_url
  selected_machine_learning_ui_url = local.is_update_existing ? try([local.selected_connection_urls[0].machine_learning_notebook_url], []) : module.adb.machine_learning_ui_url
  selected_apex_url                = local.is_update_existing ? try([local.selected_connection_urls[0].apex_url], []) : module.adb.apex_url
  selected_private_endpoint_ip     = local.is_update_existing ? try(data.oci_database_autonomous_database.existing_adb[0].private_endpoint_ip, null) : module.adb.private_endpoint_ip
  selected_askoracle_select_ai_app_url = local.selected_database_fully_qualified_name != "" ? (
    "https://${local.selected_database_fully_qualified_name}/ords/r/${lower(local.effective_schema_name)}/chatdb"
  ) : ""
  conn_db = local.selected_db_connection[0].profiles[1].value

  # Create Autonomous Data Warehouse
  adw_params = local.is_update_existing ? {} : {
    adw = {
      compartment_id          = var.compartment_id
      compute_model           = var.db_compute_model
      effective_compute_count = local.effective_compute_count
      size_in_tbs             = var.db_size_in_tbs
      db_name                 = var.db_name
      u_name                  = local.effective_schema_name
      db_workload             = var.db_workload
      db_version              = var.db_version
      enable_auto_scaling     = var.db_enable_auto_scaling
      is_free_tier            = var.db_is_free_tier
      # license_model             = var.db_license_model
      effective_license_model     = local.effective_license_model
      create_local_wallet         = true
      database_admin_password     = var.db_password
      database_wallet_password    = var.db_password
      data_safe_status            = var.db_data_safe_status
      operations_insights_status  = var.db_operations_insights_status
      database_management_status  = var.db_database_management_status
      is_mtls_connection_required = null
      subnet_id                   = null
      nsg_ids                     = null
      defined_tags                = {}
    },
  }

  # End

}
