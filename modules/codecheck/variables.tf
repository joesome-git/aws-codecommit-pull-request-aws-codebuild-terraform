variable "name" {
  type = string
}
variable "branches" {
  type = list(string)
}

variable "repositories" {
  type = map(any)
}

variable "tags" {
  type = map(any)
}

variable "buildspec" {
  type = string
}
