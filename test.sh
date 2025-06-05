#!/usr/bin/env bash
set -euo pipefail

echo "> Checking Argo CLI..."
if ! command -v argo &> /dev/null; then
  echo "> Installing Argo CLI..."
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    brew install argo
  else
    curl -sLO https://github.com/argoproj/argo-workflows/releases/latest/download/argo-linux-amd64
    chmod +x argo-linux-amd64
    sudo mv argo-linux-amd64 /usr/local/bin/argo
  fi
fi

if kind get clusters | grep -q argo-task; then
  echo "> Deleting existing kind cluster..."
  kind delete cluster --name argo-task
fi

echo "> Creating kind cluster..."
kind create cluster --name argo-task

echo "> Installing Argo Workflows..."
kubectl create namespace argo || true
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.10/install.yaml

kubectl create clusterrolebinding argo-default-rbac \
  --clusterrole=admin \
  --serviceaccount=argo:default || true

echo "> Creating ConfigMap for Ansible playbooks..."
kubectl create configmap ansible-playbooks \
  --from-file=ansible/rollback.yml \
  --from-file=ansible/patch-green.yml \
  --from-file=ansible/playbook.yml \
  --from-file=ansible/switch-traffic.yml \
  --namespace argo --dry-run=client -o yaml | kubectl apply -f -

echo "> Waiting for Argo deployments to become available..."
kubectl wait --for=condition=available --timeout=180s deployment --namespace argo --all

echo "> Applying blue deployment and service..."
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/demo-app-blue || true

echo "> Applying green deployment..."
kubectl apply -f k8s/deployment-green.yaml

echo "> Submitting workflow..."
argo submit argo/workflow-skeleton.yaml -n argo --watch

echo "> Workflow List:"
argo list -n argo

echo "> Streaming logs:"
argo logs @latest -n argo --follow

echo "> 🔍 Diagnostics"
kubectl get pods -n argo

LATEST=$(argo list -n argo --no-headers | head -n1 | awk '{print $1}')
POD=$(kubectl get pods -n argo -l workflows.argoproj.io/workflow="$LATEST" -o jsonpath="{.items[0].metadata.name}")

echo "> Inspecting pod: $POD"
kubectl exec -n argo "$POD" -c main -- ls -alh /src/ansible || echo "❌ Could not inspect ansible directory inside pod"
