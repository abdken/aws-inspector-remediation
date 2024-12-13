variable "sns_topic_name" {
  type = string
}

variable "envirnoment" {}
variable "sns_email" {
  type = string
  default = null
}
variable "enable_topic_subscription" {
  type = bool
  default = false
}

variable "prefix" {
  default = "spaceX"
}