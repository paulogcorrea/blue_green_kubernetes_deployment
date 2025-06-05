# 🔄 Blue/Green Zero Downtime Deployment with Argo Workflows

This project demonstrates a **zero-downtime blue/green deployment** strategy using:

- ✅ Kubernetes
- ✅ Ansible playbooks
- ✅ Argo Workflows
- ✅ Kind (Kubernetes in Docker)
- ✅ Smoke testing before traffic switch

---

## 📁 Project Structure

```
.
├── argo/
│   ├── workflow-skeleton.yaml       # Main Argo Workflow definition
│   ├── service-account.yml          # ServiceAccount for workflows
│   ├── rbac-auth.yml                # RBAC permissions for workflow runner
├── ansible/
│   ├── playbook.yml                 # Creates green deployment
│   ├── patch-green.yml              # Patches Service to point to green
│   ├── switch-traffic.yml           # Final switch to green
│   ├── rollback.yml                 # Rollback to blue if green fails
├── k8s/
│   ├── deployment-blue.yaml         # Blue deployment definition
│   ├── deployment-green.yaml        # Green deployment definition
│   ├── service.yaml                 # Service pointing to current release
├── test.sh                          # Automates full test in Kind
```

---

## ✅ What This Workflow Does

1. **Lint** Ansible and YAML files
2. **Deploy green** version alongside blue
3. **Patch service** to point temporarily to green
4. **Wait for green rollout**
5. **Smoke test** green
6. **Switch traffic** permanently if green is good
7. **Rollback** to blue if anything fails

---

## 🛠️ Prerequisites

Before running, install:

- [Docker](https://docs.docker.com)
- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Argo CLI](https://argoproj.github.io/argo-workflows/cli/)
  ```bash
  brew install argo  # macOS
  ```

---

## 🚀 Usage

Run the complete stack in a fresh Kind cluster:

```bash
chmod +x test.sh
./test.sh
```

This script:
- Sets up Kind
- Installs Argo in the `argo` namespace
- Creates deployments and service
- Submits the Argo workflow
- Streams logs and diagnostics

---

## ✅ Verifying the Result

Check current service selector:

```bash
kubectl get svc demo-app -n argo -o jsonpath='{.spec.selector}'
```

Should show `"release": "green"` after a successful run.

---

## 📦 Cleanup

```bash
kind delete cluster --name argo-task
```

---

## 🔐 Namespace Used

All resources are deployed in the `argo` namespace for isolation and compatibility with Argo Workflows.

---

## 📸 Sample Output

```
✔ bluegreen-xyz created
✔ lint → create-green → patch → smoke-test → switch-traffic
```

---