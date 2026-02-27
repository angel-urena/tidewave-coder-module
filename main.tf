terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.5"
    }
  }
}


variable "agent_id" {
  type        = string
  description = "The ID of the Coder agent to install Tidewave on."
}

variable "port" {
  type        = number
  default     = 9832
  description = "The port for Tidewave to listen on."
}

variable "tidewave_version" {
  type        = string
  default     = "latest"
  description = "The version of Tidewave to install (e.g. \"v0.3.5\")."
}

variable "log_path" {
  type        = string
  default     = "/tmp/tidewave.log"
  description = "Path to the Tidewave log file."
}

variable "install_dir" {
  type        = string
  default     = "/usr/local/bin"
  description = "Directory to install the Tidewave binary."
}

variable "order" {
  type        = number
  default     = null
  description = "The order of the Tidewave app in the UI."
}

variable "group" {
  type        = string
  default     = null
  description = "The group name for the Tidewave app."
}

variable "slug" {
  type        = string
  default     = "tidewave"
  description = "The slug for the Tidewave app."
}

variable "display_name" {
  type        = string
  default     = "Tidewave"
  description = "The display name for the Tidewave app."
}

variable "icon" {
  type        = string
  default     = "/icon/tidewave.svg"
  description = "The icon for the Tidewave app."
}

variable "share" {
  type        = string
  default     = "owner"
  description = "The sharing level for the Tidewave app (owner, authenticated, public)."

  validation {
    condition     = contains(["owner", "authenticated", "public"], var.share)
    error_message = "share must be one of: owner, authenticated, public."
  }
}

variable "subdomain" {
  type        = bool
  default     = true
  description = "Whether to use subdomain routing (recommended for WebSocket support)."
}

variable "debug" {
  type        = bool
  default     = false
  description = "Enable debug logging for Tidewave."
}

variable "allowed_origins" {
  type        = list(string)
  default     = null
  description = "List of allowed origins for Tidewave. Defaults to the dynamically constructed Coder subdomain URL for this workspace."
}

variable "libc" {
  type        = string
  default     = "gnu"
  description = "Linux libc variant (gnu or musl for Alpine)."

  validation {
    condition     = contains(["gnu", "musl"], var.libc)
    error_message = "libc must be one of: gnu, musl."
  }
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  # Strip protocol from the access URL to get the base domain (e.g. "coder.movatic.co")
  access_url_host = replace(data.coder_workspace.me.access_url, /^https?:\/\//, "")

  # Coder subdomain app URL: https://{slug}--{workspace}--{owner}.{host}
  default_origin = "https://${var.slug}--${data.coder_workspace.me.name}--${data.coder_workspace_owner.me.name}.${local.access_url_host}"

  allowed_origins = var.allowed_origins != null ? var.allowed_origins : [local.default_origin]
}

resource "coder_script" "tidewave" {
  agent_id           = var.agent_id
  display_name       = "Tidewave"
  icon               = var.icon
  run_on_start       = true
  start_blocks_login = true

  script = templatefile("${path.module}/scripts/run.sh", {
    install_dir      = var.install_dir
    tidewave_version = var.tidewave_version
    libc             = var.libc
    port             = var.port
    log_path         = var.log_path
    debug            = var.debug
    allowed_origins  = join(",", local.allowed_origins)
  })
}

resource "coder_app" "tidewave" {
  agent_id     = var.agent_id
  slug         = var.slug
  display_name = var.display_name
  url          = "http://localhost:${var.port}"
  icon         = var.icon
  subdomain    = var.subdomain
  share        = var.share
  order        = var.order
  group        = var.group

  healthcheck {
    url       = "http://localhost:${var.port}/about"
    interval  = 5
    threshold = 6
  }
}

output "port" {
  value       = var.port
  description = "The port Tidewave is running on."
}

output "url" {
  value       = "http://localhost:${var.port}"
  description = "The URL to access Tidewave."
}
