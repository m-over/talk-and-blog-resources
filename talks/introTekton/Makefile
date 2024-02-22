setupDemo: setupKindCluster installTekton 
destroyDemo: destroyKindCluster 

setupKindCluster:
	open -a Docker
	kind create cluster -n tekton-demo

destroyKindCluster:
	kind delete cluster -n tekton-demo 

installTekton:
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
