BOX_NAME := custom/rockylinux-8.10
BOX_FILE := custom_base.box
# Dynamically detect architecture (e.g., x86_64, arm64)
RAW_ARCH := $(shell uname -m)
ifeq ($(RAW_ARCH),x86_64)
    ARCH := amd64
else
    ARCH := $(RAW_ARCH)
endif

.PHONY: add-box remove-box box

box:
	@echo "Creating box $(BOX_NAME) ($(ARCH)) for Virtualbox..."
	@if [ -f $(BOX_FILE) ]; then rm -f $(BOX_FILE); fi
	ENABLE_SYNC=false AUTO_UPDATE=false vagrant up --provision-with packages
	ENABLE_SYNC=false AUTO_UPDATE=false vagrant reload
	ENABLE_SYNC=false AUTO_UPDATE=false vagrant reload --provision-with vbguest
	ENABLE_SYNC=true AUTO_UPDATE=true vagrant reload
	vagrant halt
	vagrant package --output $(BOX_FILE)
	vagrant destroy --force

add-box:
	@echo "Adding box $(BOX_NAME) v$(VERSION) ($(ARCH)) for Virtualbox..."
	vagrant box add $(BOX_NAME) $(BOX_FILE) \
		--provider virtualbox \
		--architecture $(ARCH) \
		--force
	rm -f $(BOX_FILE)

remove-box:
	vagrant box remove $(BOX_NAME) --provider virtualbox