.PHONY: cluster deploy submit test clean logs status rollback argo-ui submit-canary test-canary interactive

cluster:
	kind create cluster --name argo-task || true
	kubectl create namespace argo || true
	kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
	kubectl wait --for=condition=available deployment -n argo --all --timeout=180s

	# Grant service account permission to manage services
	kubectl create clusterrolebinding argo-default-rbac \
		--clusterrole=admin \
		--serviceaccount=argo:default || true

deploy:
	kubectl apply -f k8s/

submit:
	argo submit argo/workflow-skeleton.yaml -n argo

submit-canary:
	argo submit argo/workflow-canary.yaml -n argo

test: cluster deploy submit

test-canary: cluster deploy submit-canary

interactive:
	./run-test.sh

clean:
	kind delete cluster --name argo-task

logs:
	argo logs @latest -n argo

status:
	argo list -n argo

rollback:
	argo retry @latest -n argo

argo-ui:
	kubectl -n argo port-forward deployment/argo-server 2746:2746
