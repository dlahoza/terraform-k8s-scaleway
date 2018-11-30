variable "docker_version" {
  default     = "17.12.1~ce-0~ubuntu"
  description = "Use 17.12.1~ce-0~ubuntu for x86_64 and 17.03.0~ce-0~ubuntu-xenial for arm"
}

variable "k8s_version" {
  default = "stable-1.11"
}

variable "traefik_dashboard_domain" {
  default = "traefik.example.com"
  description = "Domain for Traefik Dashboard"
}

variable "traefik_acme_email" {
  default = "admin@example.com"
  description = "Email for ACME SSL"
}

variable "grafana_domain" {
  default = "grafana.example.com"
  description = "Domain for Grafana"
}

variable "grafana_password" {
  default = "grafana_password"
  description = "Grafana password"
}

variable "weave_passwd" {
  default = "ChangeMe"
}

variable "arch" {
  default     = "x86_64"
  description = "Values: arm arm64 x86_64"
}

variable "region" {
  default     = "ams1"
  description = "Values: par1 ams1"
}

variable "server_type" {
  default     = "START1-S"
  description = "Use C1 for arm, ARM64-2GB for arm64 and C2S for x86_64"
}

variable "server_type_node" {
  default     = "START1-S"
  description = "Use C1 for arm, ARM64-2GB for arm64 and C2S for x86_64"
}

variable "nodes" {
  default = 2
}

variable "ip_admin" {
  type        = "list"
  default     = ["0.0.0.0/0"]
  description = "IP access to services"
}

variable "private_key" {
  type        = "string"
  default     = "~/.ssh/id_rsa"
  description = "The path to your private key"
}
