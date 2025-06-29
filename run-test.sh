#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Kubernetes Deployment Strategy Testing"
echo "========================================"
echo ""
echo "Please choose which deployment strategy you want to test:"
echo ""
echo "1) Blue-Green Deployment"
echo "   - Zero downtime deployment"
echo "   - Instant traffic switch"
echo "   - Quick rollback capability"
echo ""
echo "2) Canary Deployment"
echo "   - Gradual traffic shift (10% → 50% → 100%)"
echo "   - Risk mitigation with monitoring"
echo "   - Progressive validation"
echo ""

while true; do
    read -p "Enter your choice (1 or 2): " choice
    case $choice in
        1)
            echo ""
            echo "🔵🟢 Starting Blue-Green Deployment Test..."
            echo "=========================================="
            exec ./test.sh
            ;;
        2)
            echo ""
            echo "🕯️ Starting Canary Deployment Test..."
            echo "===================================="
            exec ./test-canary.sh
            ;;
        *)
            echo "❌ Invalid choice. Please enter 1 for Blue-Green or 2 for Canary."
            ;;
    esac
done
