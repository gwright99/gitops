variable "main_args" {
  type = object({
    tf_root = string
    resource_group = string
    common_tags = map(string)
  })
  description = "Locals from main"
}