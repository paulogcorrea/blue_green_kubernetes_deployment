#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Checking green pods..."
kubectl get pods -l release=green -o wide

echo
echo "📦 Getting logs from green pods..."
for pod in $(kubectl get pods -l release=green -o name); do
  echo
  echo "📄 Logs for $pod:"
  kubectl logs "$pod" --tail=20 || echo "⚠️ Failed to fetch logs"
done

echo
echo "🔁 Restart counts:"
kubectl get pods -l release=green -o jsonpath="{range .items[*]}{.metadata.name}{': '}{.status.containerStatuses[0].restartCount}{'\n'}{end}"

echo
echo "🧠 Deployment args for demo-app-green:"
kubectl get deployment demo-app-green -o jsonpath="{.spec.template.spec.containers[0].args}"
echo

echo
echo "🔀 Service selector:"
kubectl get service demo-app -o jsonpa
