terraform {
    required_providers {
        databricks = {
            source  = "databricks/databricks"
            configuration_aliases = [ databricks.acc, databricks.wsp ]
        }
    }
}