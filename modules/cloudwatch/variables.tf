variable "main_args" {
  type = object({
    tf_root = string
    resource_group = string
    common_tags = map(string)
  })
  description = "Locals from main"
}

variable "lambda_function_name" {
    type = string
    description = "The name of the lambda function created in the my_lambda_resources function."
}