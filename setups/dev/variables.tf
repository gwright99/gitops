variable "environment" {
    type = string
    description = "The deployment environment"
    default = "dev"
}

variable "project" {
    type = string
    description = "The project name"
    default = "learning"
}

variable "default_region" {
    type = string
    description = "The default AWS region"
    default = "us-east-1"
}