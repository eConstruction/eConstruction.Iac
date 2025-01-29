
resource "null_resource" "update_helm_repo" {
  provisioner "local-exec" {
    command = "helm repo add argoproj https://argoproj.github.io/argo-helm && helm repo update"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.1.2"

  depends_on = [null_resource.update_helm_repo]

  values = [file("${path.module}/values.yaml")]
}
