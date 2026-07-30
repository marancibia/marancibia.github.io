# Copyright © 2026, Oracle and/or its affiliates.
# All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Autonomous Database Outputs:

output "adb_admin_password" {
  description = "ADB Admin password"
  value       = local.effective_admin_password
  sensitive   = true
}

output "adb_user_name" {
  description = "Workshop user name"
  value       = local.effective_schema_name
}

output "adb_user_password" {
  description = "Workshop user initial password"
  value       = local.effective_user_password
  sensitive   = false
}

output "adb_database_db_connection" {
  value = local.selected_db_connection
}

output "database_fully_qualified_name" {
  value = local.selected_database_fully_qualified_name
}

output "adb_database_private_endpoint_ip" {
  value = local.selected_private_endpoint_ip
}

output "database_actions" {
  value = local.selected_database_actions_url
}

output "graph_studio_url" {
  value = local.selected_graph_studio_url
}

output "machine_learning_ui_url" {
  value = local.selected_machine_learning_ui_url
}

output "apex_url" {
  value = local.selected_apex_url
}

output "askoracle_select_ai_app_url" {
  value = local.selected_askoracle_select_ai_app_url
}
