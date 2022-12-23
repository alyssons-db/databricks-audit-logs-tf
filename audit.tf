resource "databricks_mws_credentials" "log_writer" {
  provider = databricks.acc
  account_id       = var.databricks_account_id
  credentials_name = "Usage Delivery"
  role_arn         = aws_iam_role.logdelivery.arn
}

resource "databricks_mws_storage_configurations" "log_bucket" {
  provider = databricks.acc
  account_id                 = var.databricks_account_id
  storage_configuration_name = "Usage Logs"
  bucket_name                = aws_s3_bucket.logdelivery.bucket
}

resource "databricks_mws_log_delivery" "audit_logs" {
  provider = databricks.acc
  account_id               = var.databricks_account_id
  credentials_id           = databricks_mws_credentials.log_writer.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.log_bucket.storage_configuration_id
  delivery_path_prefix     = "audit-logs"
  config_name              = "Audit Logs"
  log_type                 = "AUDIT_LOGS"
  output_format            = "JSON"
}


## adds notebook to repo
resource "databricks_repo" "audit" {
  provider  = databricks.wsp
  url       = "https://github.com/andyweaves/databricks-audit-logs.git" 
}

## creates DLT pipeline

resource "databricks_pipeline" "this" {
  provider    = databricks.wsp
  development = false
  name        = "Audit Logs Analysis"
  target      = "audit_logs"

  configuration = {
    INPUT_PATH  = "s3://${aws_s3_bucket.logdelivery.id}/audit-logs/"
    OUTPUT_PATH = "s3://${aws_s3_bucket.logdelivery.id}/log-output/"
    CONFIG_FILE = "/Workspace${databricks_repo.audit.path}/configuration/audit_logs.json"
  }

  cluster {
    label       = "default"
    num_workers = 1
    aws_attributes {
      instance_profile_arn = aws_iam_instance_profile.this.arn
    }
  }

  library {
    notebook {
      path = "${databricks_repo.audit.path}/notebooks/dlt_audit_logs"
    }
  }
}