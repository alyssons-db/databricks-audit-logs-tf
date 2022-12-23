variable "databricks_account_id" {
  description = "Account Id that could be found in the bottom left corner of https://accounts.cloud.databricks.com/"
}

variable "prefix" {
  description = "Prefix to be added to resources name"
}

variable "crossaccount_role_name" {
  description = "Name of the cross account role used by Databricks"
}