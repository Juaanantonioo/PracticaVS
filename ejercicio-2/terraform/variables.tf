variable "db_name" {
  type        = string
  default     = "matomo"
  description = "Nombre de la base de datos de Matomo"
}

variable "db_user" {
  type        = string
  default     = "matomo"
  description = "Usuario de la base de datos"
}

variable "db_password" {
  type        = string
  default     = "matomo_pass"
  description = "Password del usuario de la base de datos"
}

variable "db_root_password" {
  type        = string
  default     = "root_pass"
  description = "Password de root de MariaDB"
}

variable "dockerhub_username" {
  type        = string
  description = "Usuario de Docker Hub que contiene la imagen de Matomo"
}

variable "php_memory_limit" {
  type        = string
  default     = "512M"
  description = "Límite de memoria PHP para Matomo"
}

variable "php_upload_max_filesize" {
  type        = string
  default     = "512M"
  description = "Tamaño máximo de archivo para subida en PHP"
}

variable "php_post_max_size" {
  type        = string
  default     = "512M"
  description = "Tamaño máximo de POST en PHP"
}
