VERSION = $(shell godzil show-version)
CURRENT_REVISION = $(shell git rev-parse --short HEAD)
BUILD_LDFLAGS = "-s -w -X github.com/Songmu/godzil.revision=$(CURRENT_REVISION)"
ifdef update
  u=-u
endif

export GO111MODULE=on

.PHONY: deps
deps:
	go get ${u} -d

.PHONY: devel-deps
devel-deps: deps
	GO111MODULE=off go get ${u} \
	  golang.org/x/lint/golint            \
	  github.com/mattn/goveralls          \
	  github.com/Songmu/godzil/cmd/godzil \
	  github.com/Songmu/goxz/cmd/goxz     \
	  github.com/tcnksm/ghr               \
	  github.com/jessevdk/go-assets-builder

.PHONY: test
test: deps
	go test

.PHONY: lint
lint: devel-deps
	go vet
	golint -set_exit_status

.PHONY: cover
cover: devel-deps
	goveralls

.PHONY: build
build: deps
	go build -ldflags=$(BUILD_LDFLAGS) ./cmd/godzil

.PHONY: install
install: build
	mv godzil "$(shell go env GOPATH)/bin"

.PHONY: bump
bump: devel-deps
	godzil release

.PHONY: crossbuild
crossbuild:
	goxz -pv=v$(VERSION) -build-ldflags=$(BUILD_LDFLAGS) \
      -os=linux,darwin -d=./dist/v$(VERSION) ./cmd/*

.PHONY: upload
upload:
	ghr v$(VERSION) dist/v$(VERSION)

.PHONY: release
release: bump crossbuild upload

.PHONY: assets
assets:
	@echo '// Code generated by make assets. DO NOT EDIT.' > new_assets_gen.go
	@go-assets-builder -p godzil -v templates $$(git ls-files testdata/assets) \
	  >> new_assets_gen.go
