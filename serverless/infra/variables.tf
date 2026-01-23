
variable "project_name" {
  description = "Tên dự án / prefix resource"
  type        = string
  default     = "random-six"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "lambda_memory_mb" {
  description = "Lambda memory size (MB)"
  type        = number
  default     = 128
}

variable "lambda_timeout_s" {
  description = "Lambda timeout (seconds)"
  type        = number
  default     = 6
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_handler" {
  description = "Handler entrypoint (file.export)"
  type        = string
  default     = "handler.randomSix"
}

variable "source_dir" {
  description = "Thư mục chứa code Lambda"
  type        = string
  default     = "../" # trỏ lên thư mục cha (nơi có handler.js, package.json)
}

variable "enable_cors" {
  description = "Bật CORS cho HTTP API"
  type        = bool
  default     = true
}
