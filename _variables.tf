# TODO: Add your module variables here

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
