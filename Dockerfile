# Build Stage
FROM debian:stable-slim AS build

# Target Architecture
ARG TARGET

# Apt Mirror
ARG DEBIAN_MIRROR
ARG DEBIAN_SECURITY

# Apt Repository
RUN if [ -n "${DEBIAN_MIRROR}" ]; then \
      echo "# Mirror Repository"                                       >  /etc/apt/sources.list; \
      echo "deb ${DEBIAN_MIRROR} stable         main contrib non-free" >> /etc/apt/sources.list; \
      echo "deb ${DEBIAN_MIRROR} stable-updates main contrib non-free" >> /etc/apt/sources.list; \
    fi; \
    if [ -n "${DEBIAN_SECURITY}" ]; then \
      sed -i -e '@.*debian-security.*@d' /etc/apt/sources.list; \
      echo "deb ${DEBIAN_SECURITY} stable/updates main contrib non-free" >> /etc/apt/sources.list; \
    fi

# Install Packages
RUN apt-get update \
 && apt-get install -yqq --no-install-recommends \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      patch \
      unzip \
      wget \
      xz-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Download Build Tools
RUN curl -fsSL -o musl-cross-make-master.zip https://github.com/richfelker/musl-cross-make/archive/master.zip

# Extract Build Tools
RUN unzip -q musl-cross-make-master.zip

# Move Dir
RUN mv musl-cross-make-master musl-cross-gcc

# Working Dir
WORKDIR musl-cross-gcc

# Config
RUN echo "TARGET         = ${TARGET}"                                        >  config.mak
RUN echo 'OUTPUT         = /usr/local'                                       >> config.mak
RUN echo 'DL_CMD         = wget -nv -c -O'                                   >> config.mak
RUN echo 'GNU_SITE       = http://ftpmirror.gnu.org/'                        >> config.mak
RUN echo 'COMMON_CONFIG += CFLAGS="-g0 -Os" CXXFLAGS="-g0 -Os" LDFLAGS="-s"' >> config.mak
RUN echo 'COMMON_CONFIG += --disable-nls'                                    >> config.mak
RUN echo 'GCC_CONFIG    += --enable-languages=c,c++'                         >> config.mak
RUN echo 'GCC_CONFIG    += --disable-libquadmath --disable-decimal-float'    >> config.mak
RUN echo 'GCC_CONFIG    += --disable-multilib'                               >> config.mak
RUN echo 'COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)='               >> config.mak

# Quiet Log
RUN sed -i -e 's@tar zxvf@tar zxf@' Makefile
RUN sed -i -e 's@tar jxvf@tar jxf@' Makefile
RUN sed -i -e 's@tar Jxvf@tar Jxf@' Makefile

# Build
RUN make -j $(nproc) install

# Prod Stage
FROM debian:stable-slim

# Copy Binary
COPY --from=build /usr/local /usr/local
RUN ldconfig
