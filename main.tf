
provider "kubernetes" {
  config_path = "kube_config"
  config_context = "microk8s"
  config_context_cluster = "microk8s-cluster"

  # load_config_file = "false"
  # host = "https://10.0.0.210"
}

resource "kubernetes_namespace" "bricks_namespace" {
  metadata {
    name = "bricks"
  }
}
