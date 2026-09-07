variable "subscription_id" {
  description = "Azure subscription the environment lives in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "switzerlandnorth"
}

variable "environment" {
  description = "Environment name, used in every resource name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of dev, test, prod."
  }
}

variable "backend_image" {
  description = "Container image for the TrackIt backend, including the tag."
  type        = string

  validation {
    # A floating tag makes a deployment unreproducible: the same configuration
    # yields a different application tomorrow.
    condition     = !endswith(var.backend_image, ":latest")
    error_message = "Pin an explicit image tag. ':latest' is not reproducible."
  }
}

variable "db_administrator_login" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "trackit"
}

variable "db_password" {
  description = <<-EOT
    PostgreSQL administrator password.

    Supply it through the environment, never through a file:
      export TF_VAR_db_password='...'

    There is deliberately no default and no terraform.tfvars in this repository.
    .claude/settings.json denies reading terraform.tfvars and *.tfstate, so the
    value never enters the agent's context.
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters."
  }
}

variable "log_retention_days" {
  description = "How long to keep workspace logs."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}
