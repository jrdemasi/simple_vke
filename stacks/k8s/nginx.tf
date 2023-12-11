resource "kubernetes_manifest" "deployment_nginx" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "name" = "nginx"
      "namespace" = "default"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app" = "nginx"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "nginx"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "nginx"
              "name" = "nginx"
              "ports" = [
                {
                  "containerPort" = 80
                },
              ]
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_nginx" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "namespace" = "default"
      "annotations" = {
        "external-dns.alpha.kubernetes.io/hostname" = "${var.hostname}"
      }
      "name" = "nginx"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 80
          "protocol" = "TCP"
          "targetPort" = 80
        },
      ]
      "selector" = {
        "app" = "nginx"
      }
      "type" = "LoadBalancer"
    }
  }
}
