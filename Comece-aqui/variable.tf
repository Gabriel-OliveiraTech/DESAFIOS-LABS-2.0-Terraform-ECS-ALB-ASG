variable "default" {
  description = "Default variable for AWS Lab Environment"
  type        = map(string)
    default     = {
        Environment = "dev",
        ManagedBY = "terraform",
        Owner = "gabriel_oliveira"
    }
}