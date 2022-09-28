NAME    := xks-proxy-test-client
VERSION := 1.0.6
RELEASE := 0
SOURCE_BUNDLE := $(NAME)-$(VERSION)-$(RELEASE).txz
PROJECT_ROOTDIR := $(shell basename $(CURDIR))

.PHONY: release
release: build/$(SOURCE_BUNDLE)

build/$(SOURCE_BUNDLE):
	mkdir -p build
	cd .. && tar cJfh $(PROJECT_ROOTDIR)/$@ \
		--exclude=$(PROJECT_ROOTDIR)/.git \
		--exclude=$(PROJECT_ROOTDIR)/.gitignore \
		--exclude=$(PROJECT_ROOTDIR)/Config \
		--exclude=$(PROJECT_ROOTDIR)/mtls \
		--exclude=$(PROJECT_ROOTDIR)/build \
		--exclude=$(PROJECT_ROOTDIR)/.DS_Store \
		$(PROJECT_ROOTDIR)

.PHONY: clean distclean
clean:
	rm -f build/$(SOURCE_BUNDLE)

distclean:
	rm -rf build
