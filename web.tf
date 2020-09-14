resource "kubernetes_deployment" "web_deployment" {
  metadata {
    name = "bricks-web"
    namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
    labels = {
      App = "bricksWeb"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        App = "bricksWeb"
      }
    }

    template {
      metadata {
        labels = {
          App = "bricksWeb"
        }
      }

      spec {
        host_aliases = [
          {
            "ip" = "${kubernetes_service.bricks_database_service.spec.0.cluster_ip}"
            "hostnames" = ["bricks-database"]
          }

        ]
        container {
          image = "vinik/bricks:0.1"
          name  = "bricks-web"

          port {
            container_port = 80
          }

          env = [

            {
              "name" = "BRICKS_MYSQL_DB_NAME"
              "value" = "bricks"
            },
            {
              "name" = "BRICKS_MYSQL_DB_HOST"
              "value" = "bricks-database"
            },
            {
              "name" = "BRICKS_MYSQL_DB_PORT"
              "value" = "3306"
            },
            {
              "name" = "BRICKS_MYSQL_DB_PASSWORD"
              "value" = "bricksadmin"
            },
            {
              "name" = "BRICKS_MYSQL_DB_USERNAME"
              "value" = "root"
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

          volume_mount {
            mount_path = "/var/www/site/app/tmp"
            name = "cache"
          }

        }

        volume {
          name = "cache"
        }

      }
    }
  }
}

resource "kubernetes_service" "web_service" {
  # count = 0
  metadata {
    name = "bricks-web-service"
    namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
  }
  spec {
    selector = {
      App = "${kubernetes_deployment.web_deployment.spec.0.template.0.metadata.0.labels.App}"
    }

    # type = "ExternalName"
    # external_name = "foo.otacon.local"

    type = "NodePort"

    port {
      # node_port = 30081
      port        = 80
      target_port = 80
    }

    session_affinity = "ClientIP"
  }
}

resource "kubernetes_ingress" "web_ingress" {
  metadata {
    name = "web-ingress"
    namespace = "${kubernetes_namespace.bricks_namespace.metadata.0.name}"
  }

  spec {
    backend {
      service_name = "bricks-web-service"
      service_port = 80
    }

    rule {
      host = "bricks.otacon.local"

      http {
        path {
          backend {
            service_name = "bricks-web-service"
            service_port = 80
          }

          path = "/"
        }
      }
    }

    # tls {
    #   secret_name = "tls-secret"
    # }
  }
}

output "web_service_ip" {
  value = "${kubernetes_service.web_service.spec.0.cluster_ip}"
}

output "web_ingress" {
  value = "${kubernetes_ingress.web_ingress.spec.0.rule.0.host}"
}
