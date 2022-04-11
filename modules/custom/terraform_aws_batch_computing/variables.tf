# variable "tf_root" {
#   type        = string
#   description = "The deployment environment"
# }

# variable "tf_common_tags" {
#     type        = map
#     description = "Common tags passed in by main.tf"
# }

variable "context" {
  type = object({
    tf_root = string
    resource_group = string
    common_tags = map(string)
  })
  description = "Locals from main"
}