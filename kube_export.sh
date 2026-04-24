mkdir -p ~/.kube
KUBECONFIG=~/.kube/config:~/multi-cloud-free-tier/terraform/aks-config.yaml kubectl config view --flatten > ~/.kube/config.merged
mv ~/.kube/config.merged ~/.kube/config
chmod 600 ~/.kube/config
