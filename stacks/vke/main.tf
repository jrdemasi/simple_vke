resource "vultr_kubernetes" "vke-dev" {
    region  = var.region
    label   = "vke-dev"
    version = "v1.28.3+2"

    node_pools {
        node_quantity = 1
        plan          = var.plan
        label         = "vke-dev"
        auto_scaler   = true
        min_nodes     = 1
        max_nodes     = var.autoscaler_max
    }
} 

resource "local_file" "kubeconfig" {
    content  = base64decode(vultr_kubernetes.vke-dev.kube_config)
    filename = "../k8s/vke-dev-kubeconfig.yaml"
}
