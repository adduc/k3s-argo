## Inputs

variable "argocd_admin_password_hash" {
  type        = string
  description = <<-EOT
    The password for the ArgoCD admin user.

    This is a hash of the password, generated using:

    ```bash
    htpasswd -nbBC 10 "" $PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/'
    ```
  EOT
}

## Required Providers

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "alekc/kubectl"
    }
  }
}

## Provider Configuration

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/kubeconfig.yaml"
}

## Resources

# Gateway API CRDs deploy using Helm
# - Required for Nginx Gateway Fabric
# @see https://artifacthub.io/packages/helm/portefaix-hub/gateway-api-crds

resource "helm_release" "gateway-api" {
  name       = "gateway-api"
  repository = "https://charts.portefaix.xyz/"
  chart      = "gateway-api-crds"
  version    = "1.2.0"
}

# Nginx Gateway Fabric deploy using Helm
# @see https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/
# @see https://github.com/nginx/nginx-gateway-fabric/pkgs/container/charts%2Fnginx-gateway-fabric
# Compatibility matrix between Nginx Gateway Fabric and Gateway API versions
# @see https://github.com/nginx/nginx-gateway-fabric/blob/v1.5.1/README.md#technical-specifications

resource "helm_release" "nginx-gateway-fabric" {
  depends_on = [helm_release.gateway-api]
  name       = "nginx-gateway-fabric"
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  version    = "1.5.0"

  values = [
    yamlencode({
      service = {
        type = "NodePort"
        ports = [
          {
            nodePort   = 30080 # external port
            port       = 80    # service port for internal traffic
            targetPort = 80    # target port within the pod
            protocol   = "TCP"
            name       = "http"
          }
        ]
      }
    })
  ]
}

# ArgoCD deploy using Helm

resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.22"

  values = [
    # @see https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/values.yaml
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }

        secret = {
          "argocdServerAdminPassword" = var.argocd_admin_password_hash
        }
      }
      crds = {
        keep = false
      }
    })
  ]
}

# Gateway API requires a Gateway to be created to be able to route traffic

resource "kubectl_manifest" "gateway" {
  depends_on = [helm_release.gateway-api]

  # @see https://gateway-api.sigs.k8s.io/
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "nginx-gateway-fabric"
    }
    spec = {
      gatewayClassName = "nginx"
      listeners = [
        {
          name     = "http"
          port     = 80
          protocol = "HTTP"
        }
      ]
    }
  })
}

# We can now create an HTTPRoute to route traffic to the ArgoCD service

resource "kubectl_manifest" "httproute_argo" {
  depends_on = [kubectl_manifest.gateway, helm_release.argocd]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "argo-cd"
    }
    spec = {
      parentRefs = [{
        name        = "nginx-gateway-fabric"
        sectionName = "http"
      }]
      rules = [{
        backendRefs = [{
          name = "argo-cd-argocd-server"
          port = 80
        }]
      }]
    }
  })
}
