# 🔄 Zero Downtime Deployment Strategies with Argo Workflows

This project demonstrates **zero-downtime deployment strategies** using:

- ✅ **Blue/Green Deployment** - Instant traffic switch
- ✅ **Canary Deployment** - Gradual traffic shift with monitoring
- ✅ Kubernetes
- ✅ Ansible playbooks
- ✅ Argo Workflows
- ✅ Kind (Kubernetes in Docker)
- ✅ Smoke testing and health monitoring

---

## 📁 Project Structure

```
.
├── argo/
│   ├── workflow-skeleton.yaml       # Blue/Green Argo Workflow definition
│   ├── workflow-canary.yaml         # Canary Argo Workflow definition
│   ├── service-account.yml          # ServiceAccount for workflows
│   ├── rbac-auth.yml                # RBAC permissions for workflow runner
├── ansible/
│   ├── playbook.yml                 # Creates green deployment
│   ├── patch-green.yml              # Patches Service to point to green
│   ├── switch-traffic.yml           # Final switch to green
│   ├── rollback.yml                 # Rollback to blue if green fails
│   ├── deploy-canary.yml            # Creates canary deployment
│   ├── scale-canary.yml             # Scales canary for 50% traffic
│   ├── promote-canary.yml           # Promotes canary to full production
│   ├── rollback-canary.yml          # Rollback canary deployment
├── k8s/
│   ├── deployment-blue.yaml         # Blue deployment definition
│   ├── deployment-green.yaml        # Green deployment definition
│   ├── deployment-canary.yaml       # Canary deployment definition
│   ├── service.yaml                 # Service pointing to current release
│   ├── service-canary.yaml          # Dedicated canary service
├── test.sh                          # Blue/Green test automation
├── test-canary.sh                   # Canary test automation
├── run-test.sh                      # Interactive test selector
```

---

## 🔵🟢 Blue/Green Deployment Strategy

**Zero downtime with instant traffic switch**

### How it works:
1. **Lint** Ansible and YAML files
2. **Deploy green** version alongside blue
3. **Patch service** to point temporarily to green for testing
4. **Wait for green rollout** to complete
5. **Smoke test** green deployment
6. **Switch traffic** permanently to green if tests pass
7. **Rollback** to blue if anything fails

### Benefits:
- ✅ Instant rollback capability
- ✅ Zero downtime
- ✅ Simple traffic switching
- ✅ Clear separation of environments

---

## 🕯️ Canary Deployment Strategy

**Risk mitigation with gradual traffic shift**

### How it works:
1. **Lint** Ansible and YAML files
2. **Deploy canary** version (10% traffic initially)
3. **Smoke test** canary deployment
4. **Monitor metrics** for 30 seconds at 10% traffic
5. **Scale to 50%** traffic split between blue and canary
6. **Monitor metrics** for 60 seconds at 50% traffic
7. **Promote canary** to 100% traffic if all checks pass
8. **Final smoke test** to verify full deployment
9. **Rollback** to blue if any step fails

### Benefits:
- ✅ Gradual risk exposure
- ✅ Real user traffic validation
- ✅ Automated monitoring and rollback
- ✅ Progressive confidence building

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

## 🚀 Usage Options

### Option 1: Interactive Mode (Recommended)

Choose your deployment strategy interactively:

```bash
chmod +x run-test.sh
./run-test.sh
```

This will present you with:
```
🚀 Kubernetes Deployment Strategy Testing
========================================

Please choose which deployment strategy you want to test:

1) Blue-Green Deployment
   - Zero downtime deployment
   - Instant traffic switch
   - Quick rollback capability

2) Canary Deployment
   - Gradual traffic shift (10% → 50% → 100%)
   - Risk mitigation with monitoring
   - Progressive validation

Enter your choice (1 or 2):
```

### Option 2: Direct Execution

**Blue/Green Deployment:**
```bash
chmod +x test.sh
./test.sh
```

**Canary Deployment:**
```bash
chmod +x test-canary.sh
./test-canary.sh
```

### Option 3: Using Makefile

**Interactive mode:**
```bash
make interactive
```

**Blue/Green deployment:**
```bash
make test
```

**Canary deployment:**
```bash
make test-canary
```

**Individual components:**
```bash
make cluster          # Setup Kind cluster and Argo
make deploy           # Deploy Kubernetes manifests
make submit           # Submit blue/green workflow
make submit-canary    # Submit canary workflow
make logs             # View latest workflow logs
make status           # Check workflow status
make clean            # Delete Kind cluster
```

---

## ✅ Verifying Results

### Blue/Green Deployment
Check current service selector:
```bash
kubectl get svc demo-app -n argo -o jsonpath='{.spec.selector}'
```
Should show `"release": "green"` after successful deployment.

### Canary Deployment
Check current service selector:
```bash
kubectl get svc demo-app -n argo -o jsonpath='{.spec.selector}'
```
Should show `"release": "canary"` after successful promotion.

Check deployment status:
```bash
kubectl get deployments -n argo
kubectl get services -n argo
```

---

## 🔍 Monitoring and Debugging

### View Workflow Progress
```bash
argo list -n argo
argo logs @latest -n argo --follow
```

### Check Pod Status
```bash
kubectl get pods -n argo
```

### Test Service Responses
```bash
# Test main service
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -- curl -s http://demo-app:80

# Test canary service (if deployed)
kubectl run test-canary --rm -i --restart=Never --image=curlimages/curl -- curl -s http://demo-app-canary:80
```

---

## 📦 Cleanup

```bash
kind delete cluster --name argo-task
# or
make clean
```

---

## 🔐 Security Notes

- All resources are deployed in the `argo` namespace for isolation
- RBAC is configured with minimal required permissions
- Service accounts are properly configured for Argo Workflows
- ConfigMaps are used to securely pass Ansible playbooks to containers

---

## 📊 Workflow Comparison

| Feature | Blue/Green | Canary |
|---------|------------|--------|
| **Deployment Speed** | Fast | Gradual |
| **Risk Level** | Medium | Low |
| **Resource Usage** | 2x during switch | 1.1x - 1.5x |
| **Rollback Speed** | Instant | Instant |
| **Traffic Validation** | Pre-switch only | Continuous |
| **Complexity** | Simple | Moderate |
| **Best For** | Quick releases, identical environments | High-risk changes, user-facing features |

---

## 📸 Sample Output

**Blue/Green Workflow:**
```
✔ bluegreen-xyz created
✔ lint → create-green → patch-service-green → wait-for-green → smoke-test → switch-traffic
```

**Canary Workflow:**
```
✔ canary-deployment-abc created
✔ lint → deploy-canary → wait-for-canary → smoke-test-canary → monitor-canary-10pct → scale-canary-50pct → monitor-canary-50pct → promote-canary → final-smoke-test
```

---

## 🔄 CI/CD Integration

The project includes GitHub Actions workflow (`.github/workflows/ci.yml`) that:

- Triggers on pushes to `main` branch
- Sets up Kind cluster automatically
- Installs required dependencies
- Runs blue/green deployment tests
- Provides build status and deployment verification

### GitHub Actions Features:
- ✅ Automatic dependency installation
- ✅ Cross-platform support (Linux, macOS, Windows)
- ✅ Parallel job execution
- ✅ Artifact collection
- ✅ Status reporting

---

## 🔧 Troubleshooting

### Common Issues

**1. Argo CLI not found:**
```bash
# Install Argo CLI
brew install argo  # macOS
# or download from GitHub releases
```

**2. Kind cluster creation fails:**
```bash
# Check Docker is running
docker info

# Clean up existing clusters
kind delete cluster --name argo-task
```

**3. Workflow fails during execution:**
```bash
# Check workflow status
argo list -n argo

# Get detailed logs
argo logs <workflow-name> -n argo

# Check pod events
kubectl describe pod <pod-name> -n argo
```

**4. Service not responding:**
```bash
# Check deployment status
kubectl get deployments -n argo
kubectl rollout status deployment/demo-app-blue -n argo

# Check service endpoints
kubectl get endpoints -n argo
```

**5. Permission issues:**
```bash
# Verify RBAC setup
kubectl get clusterrolebinding argo-default-rbac

# Check service account
kubectl get serviceaccount argo-workflow -n argo
```

### Debug Commands

```bash
# View all resources in argo namespace
kubectl get all -n argo

# Check ConfigMap contents
kubectl describe configmap ansible-playbooks -n argo

# Port forward to access Argo UI
kubectl -n argo port-forward deployment/argo-server 2746:2746
# Then visit: https://localhost:2746

# Check workflow events
kubectl get events -n argo --sort-by='.lastTimestamp'
```

---

## 🚀 Advanced Usage

### Custom Configuration

Modify deployment parameters by editing:
- `k8s/*.yaml` - Kubernetes resource definitions
- `ansible/*.yml` - Deployment automation logic
- `argo/*.yaml` - Workflow orchestration

### Extending the Project

1. **Add more environments:** Create additional deployment manifests
2. **Implement metrics:** Integrate with Prometheus/Grafana
3. **Add notifications:** Configure Slack/email alerts
4. **Database migrations:** Add database schema update steps
5. **Multi-cluster:** Extend to deploy across multiple clusters

### Production Considerations

- Replace `hashicorp/http-echo` with your actual application
- Implement proper health checks and readiness probes
- Configure resource limits and requests
- Set up monitoring and alerting
- Implement proper secret management
- Configure network policies for security
- Set up backup and disaster recovery procedures

---
