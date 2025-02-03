# Exercise: Running ArgoCD on K3s

This repository contains a Terraform configuration to deploy a Kubernetes cluster using K3s and a simple ArgoCD deployment. It also contains a Docker Compose configuration to deploy a K3s cluster on a single node, which is useful for development purposes.

## Deploying the k3s cluster

```bash
docker compose up -d
```

## Accessing the cluster

```bash
./kubectl get nodes
```

## Deploying ArgoCD

```bash
# Initialize the Terraform configuration
terraform init

# Deploy Nginx Gateway Fabric and ArgoCD
terraform apply
```

## Accessing ArgoCD

ArgoCD is exposed at `http://localhost`, and the admin password is `example`.

## References

- https://argoproj.github.io/argo-helm/
- https://medium.com/@eleni.grosdouli/argocd-deployment-on-rke2-with-cilium-gateway-api-ab1769cc28a3
