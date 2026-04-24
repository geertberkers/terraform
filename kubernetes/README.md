# Deploying Multi-Database Backend to AKS

These manifests deploy the `multi-db-backend` application to your AKS cluster and expose it via the NGINX Ingress controller on `aks.gb-coding.nl` and `gb-coding.nl`.

## Deployment Steps

### 1. Update Placeholders
Before deploying, open `deployment.yaml` and `secrets.yaml` and replace the placeholder values (like FQDNs and passwords) with the actual values from your Terraform outputs.

### 2. Connect to AKS
Use Azure CLI to get your cluster credentials:
```bash
az aks get-credentials --resource-group rg-terraform-aks-cheap --name cheap-k8s-aks
```

### 3. Apply Manifests
Apply the files in order:
```bash
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

### 4. Verify
Check the status of your pods and ingress:
```bash
kubectl get pods -n multi-db-app
kubectl get ingress -n multi-db-app
```

## Domains
Once successfully deployed, the application will be available at:
- http://aks.gb-coding.nl
- http://gb-coding.nl
