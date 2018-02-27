variable "name" {
  description = "repository name"
}

variable "path" {
  description = "listener rule condition path"
}

variable "cluster" {
  description = "cluster reference"
}

variable "listener" {
  description = "listener reference"
}

variable "priority" {
  description = "load balancer priority"
}

variable "vpc" {
  description = "vpc id"
}
