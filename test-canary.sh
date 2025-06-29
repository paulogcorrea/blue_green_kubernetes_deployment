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
  --from-file=ansible/deploy-canary.yml \
  --from-file=ansible/scale-canary.yml \
  --from-file=ansible/promote-canary.yml \
  --from-file=ansible/rollback-canary.yml \
  --namespace argo --dry-run=client -o yaml | kubectl apply -f -

echo "> Waiting for Argo deployments to become available..."
kubectl wait --for=condition=available --timeout=180s deployment --namespace argo --all

echo "> Applying blue deployment and service..."
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/demo-app-blue || true

echo "> Testing initial blue deployment..."
echo "Current service selector:"
kubectl get svc demo-app -n argo -o jsonpath='{.spec.selector}'
echo ""

echo "> Submitting canary workflow..."
argo submit argo/workflow-canary.yaml -n argo --watch

echo "> Workflow List:"
argo list -n argo

echo "> Streaming logs:"
argo logs @latest -n argo --follow

echo "> 🔍 Final Diagnostics"
kubectl get pods -n argo
kubectl get deployments -n argo
kubectl get services -n argo

echo "> Final service selector:"
kubectl get svc demo-app -n argo -o jsonpath='{.spec.selector}'
echo ""

echo "> Testing final deployment responses:"
echo "Testing main service (should be canary):"
kubectl run final-test --rm -i --restart=Never --image=curlimages/curl -- sh -c "curl -s http://demo-app:80" || echo "❌ Main service test failed"

echo "> Canary deployment complete! 🎉"
