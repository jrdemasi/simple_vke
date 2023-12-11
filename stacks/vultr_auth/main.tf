resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "vultr_user" "k8s_user" {
    name = "K8s User"
    email = var.email
    password = random_password.password.result
    api_enabled = true
    acl = [
      "dns",
    ]
}
