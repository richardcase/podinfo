
# The release version is controlled from pkg/version

EMPTY:=
SPACE:=$(EMPTY) $(EMPTY)
COMMA:=$(EMPTY),$(EMPTY)
NAME:=podinfo
DOCKER_REPOSITORY:=richardcase
DOCKER_IMAGE_NAME:=$(DOCKER_REPOSITORY)/$(NAME)
GITREPO:=github.com/richardcase/podinfo
GITCOMMIT:=$(shell git describe --dirty --always)
VERSION:=$(shell grep 'VERSION' pkg/version/version.go | awk '{ print $$4 }' | tr -d '"')

.PHONY: build
build:
	@echo Cleaning old builds
	@rm -rf build && mkdir -p build/linux/ui
	@echo Building: $(VERSION) ;\
	CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X $(GITREPO)/pkg/version.REVISION=$(GITCOMMIT)" -o build/linux/$(NAME) ./cmd/$(NAME) ;\
	cp -r ui/ build/linux/ui;\

.PHONY: tar
tar: build
	@echo Cleaning old releases
	@rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux.tgz -C build/linux $(NAME) ;\

.PHONY: docker-build
docker-build: tar
	rm -rf build/docker
	mkdir -p build/docker/linux/ ;\
	tar -xzf release/$(NAME)_$(VERSION)_linux.tgz -C build/docker/linux ;\
	cp -r ui/ build/docker/linux/ui;\
	cp Dockerfile build/docker/linux ;\
	cp Dockerfile build/docker/linux/Dockerfile.in ;\

	docker build -t $(DOCKER_IMAGE_NAME):$(GITCOMMIT) build/docker/linux ;\
	docker tag $(DOCKER_IMAGE_NAME):$(GITCOMMIT) $(DOCKER_IMAGE_NAME):$(VERSION) ;\
	docker tag $(DOCKER_IMAGE_NAME):$(GITCOMMIT) $(DOCKER_IMAGE_NAME):$(TAG) ;\
	if [ -z "$(TRAVIS_BUILD_NUMBER)" ]; then
		docker tag $(DOCKER_IMAGE_NAME):$(GITCOMMIT) $(DOCKER_IMAGE_NAME):build-$(TRAVIS_BUILD_NUMBER) ;\
	fi

.PHONY: docker-push
docker-push:
	@echo Pushing: $(VERSION) to $(DOCKER_IMAGE_NAME)
	docker push $(DOCKER_IMAGE_NAME) ;\

.PHONY: clean
clean:
	rm -rf release
	rm -rf build

.PHONY: gcr-build
gcr-build:
	docker build -t gcr.io/$(DOCKER_IMAGE_NAME):$(VERSION) -f Dockerfile.ci .

.PHONY: test
test:
	go test -v -race ./...

.PHONY: dep
dep:
	go get -u github.com/golang/dep/cmd/dep

.PHONY: charts
charts:
	cd charts/ && helm package podinfo/
	cd charts/ && helm package podinfo-istio/
	cd charts/ && helm package loadtest/
	cd charts/ && helm package ambassador/
	cd charts/ && helm package grafana/
	cd charts/ && helm package ngrok/
	mv charts/*.tgz docs/
	helm repo index docs --url https://richardcase.github.io/podinfo --merge ./docs/index.yaml
