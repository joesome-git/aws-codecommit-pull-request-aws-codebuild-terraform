variable "repositories" {
  type = any
}

variable "project_name" {
  type = string
}

variable "buildspec" {
  type = string
}

variable "branches" {
  type = list(string)
}

variable "tags" {
  type = map(any)
}
