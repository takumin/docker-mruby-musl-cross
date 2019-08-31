#
# Environment Variables
#

TAG ?= takumi/mruby-musl-cross

TARGET ?= x86_64-linux-musl

BUILD_ARGS ?= --build-arg TARGET=$(TARGET)

ifneq (x${no_proxy}x,xx)
BUILD_ARGS += --build-arg no_proxy=${no_proxy}
endif
ifneq (x${NO_PROXY}x,xx)
BUILD_ARGS += --build-arg NO_PROXY=${NO_PROXY}
endif

ifneq (x${ftp_proxy}x,xx)
BUILD_ARGS += --build-arg ftp_proxy=${ftp_proxy}
endif
ifneq (x${FTP_PROXY}x,xx)
BUILD_ARGS += --build-arg FTP_PROXY=${FTP_PROXY}
endif

ifneq (x${http_proxy}x,xx)
BUILD_ARGS += --build-arg http_proxy=${http_proxy}
endif
ifneq (x${HTTP_PROXY}x,xx)
BUILD_ARGS += --build-arg HTTP_PROXY=${HTTP_PROXY}
endif

ifneq (x${https_proxy}x,xx)
BUILD_ARGS += --build-arg https_proxy=${https_proxy}
endif
ifneq (x${HTTPS_PROXY}x,xx)
BUILD_ARGS += --build-arg HTTPS_PROXY=${HTTPS_PROXY}
endif

ifneq (x${DEBIAN_MIRROR}x,xx)
BUILD_ARGS += --build-arg DEBIAN_MIRROR=${DEBIAN_MIRROR}
endif
ifneq (x${DEBIAN_SECURITY}x,xx)
BUILD_ARGS += --build-arg DEBIAN_SECURITY=${DEBIAN_SECURITY}
endif

#
# Default Rules
#

.PHONY: all
all: build

#
# Build Rules
#

.PHONY: build
build:
	@docker build -t $(TAG) $(BUILD_ARGS) .

#
# Running Rules
#

.PHONY: run
run:
	@docker run --rm -i -t $(TAG) bash -il

#
# Clean Rules
#

.PHONY: clean
clean:
	@docker system prune --volumes --force
