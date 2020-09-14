resource "kubernetes_deployment" "bricks_database_deployment" {
  metadata {
    name = "bricks-db"
    namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
    labels = {
      App = "bricksDB"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        App = "bricksDB"
      }
    }

    template {


      metadata {
        labels = {
          App = "bricksDB"
        }
      }

      spec {
        hostname = "bricks-database"
        container {
          image = "mysql:5.6"
          name  = "bricks-db"

          port {
            container_port = 3306
          }

          env = [
            {
              "name" = "MYSQL_ROOT_PASSWORD"
              "value" = "bricksadmin"
            },
            {
              "name" = "MYSQL_DATABASE"
              "value" = "bricks"
            },
            {
              "name" = "MYSQL_USER"
              "value" = "bricks"
            }
          ]

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          # volume_mount {
          #   mount_path = "/var/lib/mysql/"
          #   name = "bricks-data"
          # }
        }

        # volume {
        #   name = "bricks-data"
        #   persistent_volume_claim = {
        #     claim_name = "bricks-volume-claim"
        #   }
        # }
      }
    }
  }
}

resource "kubernetes_service" "bricks_database_service" {
  count = 1
  metadata {
    name = "bricks-database-service"
    namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
  }
  spec {
    selector = {
      App = "${kubernetes_deployment.bricks_database_deployment.spec.0.template.0.metadata.0.labels.App}"
    }
    port {
      # node_port = 32306
      port        = 3306
      target_port = 3306
    }

    type = "NodePort"
  }
}

output "db_service_ip" {
  value = "${kubernetes_service.bricks_database_service.spec.0.cluster_ip}"
}

resource "kubernetes_ingress" "db_ingress" {
  metadata {
    name = "db-ingress"
    namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
  }

  spec {
    backend {
      service_name = "bricks-db-service"
      service_port = 3306
    }

    rule {
      host = "bricks.otacon.local"

      http {
        path {
          backend {
            service_name = "bricks-db-service"
            service_port = 3306
          }

          # path = "/db"
        }
      }
    }

    # tls {
    #   secret_name = "tls-secret"
    # }
  }
}

# resource "kubernetes_persistent_volume_claim" "bricks_database_persistent_volume_claim" {
#   metadata {
#     name = "bricks-volume-claim"
#     namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
#   }
#   spec {
#     storage_class_name = "microk8s-hostpath"
#     access_modes = ["ReadWriteMany"]
#     resources {
#       requests = {
#         storage = "1Gi"
#       }
#     }
#     volume_name = "${kubernetes_persistent_volume.bricks_database_persistent_volume.metadata.0.name}"
#   }
# }
#
# resource "kubernetes_persistent_volume" "bricks_database_persistent_volume" {
#   metadata {
#     name = "bricks-persistent-volume"
#     # namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
#   }
#   spec {
#     storage_class_name = "microk8s-hostpath"
#     capacity = {
#       storage = "2Gi"
#     }
#     access_modes = ["ReadWriteMany"]
#     persistent_volume_source {
#       local {
#         path = "/tmp/data2/"
#       }
#     }
#
#     node_affinity {
#       required {
#         node_selector_term {
#           match_expressions = [
#             {
#               key = "kubernetes.io/hostname"
#               operator = "In"
#               values = ["otacon"]
#             }
#
#           ]
#         }
#       }
#     }
#   }
# }
