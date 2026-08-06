variable "key_name" {
  type    = string
  default = "Siderum" // <- reemplazar por el nombre de tu keypair
}

variable "mysql_password" {
  type    = string
  default = "My_sUp3rS3cr3t0" // for testing, don't reuse!
}

variable "metabase_setup_first_name" {
  type    = string
  default = "Johnny"
}

variable "metabase_setup_last_name" {
  type    = string
  default = "Appleseed"
}

variable "metabase_setup_email" {
  type    = string
  default = "nicetoseeyou@email.com"
}

variable "metabase_setup_password" {
  type      = string
  sensitive = true
  default   = "YourStrongPassword123!"
}

