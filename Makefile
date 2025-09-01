## Deploys the k3d cluster and services.
.PHONY: deploy
deploy:
	./scripts/build-and-deploy.sh

## Teardown k3d cluster ressources.
.PHONY: destroy
destroy:
	k3d cluster delete zeek

## Run tests to ensure zeek logs are exported.
.PHONY: test
test:
	cd tests; go test -count=1 -v ./...