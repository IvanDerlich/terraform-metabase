variable "key_name" {
  type    = string
  default = "Siderum" // <- reemplazar por el nombre de tu keypair
}

variable "pg_postgres_password" {
  type    = string
  default = "My_sUp3rS3cr3t0" // for testing, don't reuse!
}

