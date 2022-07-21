variable "image_version" {
  type        = string
  description = "Version of image to use."
  default     = "latest"
}

variable "cluster_name" {
  type        = string
  description = "Name of ECS cluster service will run on."
}

variable "desired_count" {
  type        = number
  description = "The number of tasks to run."
  default     = 1
}

variable "task_name" {
  type        = string
  description = "Name of task."
}
