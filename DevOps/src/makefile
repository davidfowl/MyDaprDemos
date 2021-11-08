# DOCKER_IMAGE_PREFIX ?= distributed-calculator-
# APPS                ?= node python go csharp react-calculator
	
# include ../docker.mk
# include ../validate.mk

TARGET_DOTNET_PLATFORM = $(TARGET_ARCH)
ifeq ($(TARGET_DOTNET_PLATFORM),amd64)
  TARGET_DOTNET_PLATFORM = x64
endif

.PHONY: build, build_processor, build_provider, build_viewer

build: build_processor, build_provider, build_viewer

build_processor:
	cd processor && dotnet build
	cd processor && dotnet publish -c Release -o out

build_provider:
	cd provider && dotnet build
	cd provider && dotnet publish -c Release -o out

build_viewer:
	cd viewer && dotnet build
	cd viewer && dotnet publish -c Release -o out
