variable "environment" {
  type        = string
  description = "The deployment environment"
}

variable "project" {
  type        = string
  description = "The project name"
}

variable "tag_for_bucket" {
    type    = string
    description = "Some custom tag for the bucket"
}