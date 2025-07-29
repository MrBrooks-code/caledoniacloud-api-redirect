variable "region" {
  description = "The AWS region to deploy the redirection stack."
  type        = string
  default     = "us-east-1"
}

variable "target_domain" {
  description = "Destination domain for the 301 redirect (e.g. new.example.gov)."
  type        = string
  default     = "caledoniacloud.new.example.com"
}

variable "stackname" {
  description = "Name for redirect stack."
  type        = string
  default     = "demo-redirect-stack"
}

variable "domain_name" {
  description = "Cosmetic URL for redirect stack. Must match certificate_arn SAN."
  type        = string
  default     = "demo.caledoniacloud.com"
}

variable "certificate_arn" {
  description = "Certificate ARN for target URL redirect."
  type        = string
  default     = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

variable "profile" {
  description = "AWS profile to use for deployment."
  type        = string
  default     = "cc"
}

variable "disable_execute_api_endpoint" {
  description = "Disable default API endpoint."
  type        = bool
  default     = true
}