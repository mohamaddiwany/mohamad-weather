variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
#  default     = "ami-0502e817a62226e03" 

  validation {
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}

variable "subnets" {
    type = list
    default = ["10.30.1.0/24", "10.30.10.0/24"]
}

