variable "tf_root" {
  type        = string
  description = "The deployment environment"
}

variable "tf_common_tags" {
    type        = map
    description = "Common tags passed in by main.tf"
}