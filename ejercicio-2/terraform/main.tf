terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-matomo"
}

# 1) Namespace
resource "kubernetes_namespace" "analytics" {
  metadata {
    name = "analytics"
  }
}

# 2) Secret para las credenciales de la base de datos
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.analytics.metadata[0].name
  }

  type = "Opaque"

  data = {
    MYSQL_ROOT_PASSWORD = var.db_root_password
    MYSQL_DATABASE      = var.db_name
    MYSQL_USER          = var.db_user
    MYSQL_PASSWORD      = var.db_password
  }

  depends_on = [kubernetes_namespace.analytics]
}

# 3) Volúmenes persistentes (hostPath) -> los datos quedan en el host aunque borres el cluster
resource "kubernetes_persistent_volume" "mariadb_pv" {
  metadata {
    name = "mariadb-pv"
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    capacity = {
      storage = "1Gi"
    }

    access_modes = ["ReadWriteOnce"]

    storage_class_name = "standard"
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/Users/juanantonio/k8s-data/mariadb"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mariadb_pvc" {
  metadata {
    name      = "mariadb-pvc"
    namespace = kubernetes_namespace.analytics.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes       = ["ReadWriteOnce"]

    # MUY IMPORTANTE: desactivar StorageClass por defecto
    storage_class_name = ""

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    # Forzamos a usar el PV que creamos a mano
    volume_name = kubernetes_persistent_volume.mariadb_pv.metadata[0].name
  }

  wait_until_bound = true
}

resource "kubernetes_persistent_volume" "matomo_pv" {
  metadata {
    name = "matomo-pv"
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    capacity = {
      storage = "1Gi"
    }

    access_modes = ["ReadWriteOnce"]

    storage_class_name = "standard"
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/Users/juanantonio/k8s-data/matomo"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "matomo_pvc" {
  metadata {
    name      = "matomo-pvc"
    namespace = kubernetes_namespace.analytics.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes       = ["ReadWriteOnce"]

    # También sin StorageClass
    storage_class_name = ""

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.matomo_pv.metadata[0].name
  }

  wait_until_bound = true
}


# 4) Deployment de MariaDB
resource "kubernetes_deployment" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = kubernetes_namespace.analytics.metadata[0].name
    labels = {
      app = "mariadb"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mariadb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }

      spec {
        container {
          name  = "mariadb"
          image = "mariadb:latest"

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }

          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_USER"
              }
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          port {
            container_port = 3306
          }

          volume_mount {
            name       = "mariadb-data"
            mount_path = "/var/lib/mysql"
          }
        }

        volume {
          name = "mariadb-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mariadb_pvc.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.db_credentials]
}

resource "kubernetes_service" "mariadb" {
  metadata {
    name      = "mariadb"
    namespace = kubernetes_namespace.analytics.metadata[0].name
  }

  spec {
    selector = {
      app = "mariadb"
    }

    port {
      port        = 3306
      target_port = 3306
    }
  }
}

# 5) Deployment de Matomo (usa la imagen custom de Docker Hub)
resource "kubernetes_deployment" "matomo" {
  metadata {
    name      = "matomo"
    namespace = kubernetes_namespace.analytics.metadata[0].name
    labels = {
      app = "matomo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "matomo"
      }
    }

    template {
      metadata {
        labels = {
          app = "matomo"
        }
      }

      spec {
        container {
          name  = "matomo"
          image = "${var.dockerhub_username}/matomo-custom:latest"

          env {
            name  = "MATOMO_DATABASE_HOST"
            value = kubernetes_service.mariadb.metadata[0].name
          }
          env {
            name  = "MATOMO_DATABASE_ADAPTER"
            value = "mysql"
          }
          env {
            name  = "MATOMO_DATABASE_TABLES_PREFIX"
            value = "matomo_"
          }

          env {
            name = "MATOMO_DATABASE_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_USER"
              }
            }
          }

          env {
            name = "MATOMO_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_PASSWORD"
              }
            }
          }

          env {
            name = "MATOMO_DATABASE_DBNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "MYSQL_DATABASE"
              }
            }
          }

          env {
            name  = "PHP_MEMORY_LIMIT"
            value = var.php_memory_limit
          }
          env {
            name  = "PHP_UPLOAD_MAX_FILESIZE"
            value = var.php_upload_max_filesize
          }
          env {
            name  = "PHP_POST_MAX_SIZE"
            value = var.php_post_max_size
          }

          port {
            container_port = 80
          }

          volume_mount {
            name       = "matomo-data"
            mount_path = "/var/www/html"
          }
        }

        volume {
          name = "matomo-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.matomo_pvc.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.db_credentials]
}

# 6) Service de Matomo (NodePort 30081 -> mapeado al 8081 del host en kind-config.yaml)
resource "kubernetes_service" "matomo" {
  metadata {
    name      = "matomo"
    namespace = kubernetes_namespace.analytics.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = "matomo"
    }

    port {
      port        = 80
      target_port = 80
      node_port   = 30081
    }
  }
}
