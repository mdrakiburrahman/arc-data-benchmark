# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

variable "SPN_SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
  type        = string
}

variable "SPN_CLIENT_ID" {
  description = "Azure service principal name"
  type        = string
}

variable "SPN_CLIENT_SECRET" {
  description = "Azure service principal password"
  type        = string
}

variable "SPN_TENANT_ID" {
  description = "Azure tenant ID"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# TBD

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Deployment RG name"
  type        = string
  default     = "raki-jake-arc-benchmark-rg"
}

variable "resource_group_location" {
  description = "The location in which the deployment is taking place"
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    Source                                                                     = "terraform"
    Primary_Owner                                                              = "Raki Rahman"
    Secondary_Owner                                                            = "Jake Dern"
    Project                                                                    = "Arc Data Monitoring Benchmark"
    azsecpack                                                                  = "nonprod"
    "platformsettings.host_environment.service.platform_optedin_for_rootcerts" = "true"
  }
}
