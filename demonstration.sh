#!/bin/bash 

kind create cluster -n example --config kind_config.yaml
kubectl cluster-info --context kind-example

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo add localstack-charts https://localstack.github.io/helm-charts
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace
helm install localstack localstack-charts/localstack --namespace localstack --create-namespace
helm repo update

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

export NODE_PORT=$(kubectl get --namespace "localstack" -o jsonpath="{.spec.ports[0].nodePort}" services localstack)
export NODE_IP=$(kubectl get nodes --namespace "localstack" -o jsonpath="{.items[0].status.addresses[0].address}")

source $HOME/.bashrc
source $HOME/.bach_profile


kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=secrets/./aws-credentials.txt
kubectl apply -f providers/provider-aws.yaml
kubectl apply -f providers/provider-terraform.yaml

kubectl apply -f provider-configs/provider-config-terraform.yaml
kubectl apply -f provider-configs/provider-config-localstack.yaml