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
      autoconf \
      automake \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      libtool \
      patch \
      pkg-config \
      unzip \
      xz-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Download Build Tools
RUN curl -fsSL --retry 10 --retry-connrefused -o musl-cross-make-master.tar.gz \
      https://github.com/richfelker/musl-cross-make/archive/master.tar.gz

# Extract Build Tools
RUN tar -xf musl-cross-make-master.tar.gz && rm musl-cross-make-master.tar.gz

# Working Dir
WORKDIR musl-cross-make-master

# Config
RUN echo "TARGET         = ${TARGET}"                          >  config.mak
RUN echo 'OUTPUT         = /usr/local'                         >> config.mak
RUN echo 'DL_CMD         = curl -fsSL'                         >> config.mak
RUN echo 'DL_CMD        += --retry 10'                         >> config.mak
RUN echo 'DL_CMD        += --retry-connrefused'                >> config.mak
RUN echo 'DL_CMD        += -o'                                 >> config.mak
RUN echo 'GNU_SITE       = http://ftpmirror.gnu.org/'          >> config.mak
RUN echo 'COMMON_CONFIG += CFLAGS="-g0 -Os"'                   >> config.mak
RUN echo 'COMMON_CONFIG += CXXFLAGS="-g0 -Os"'                 >> config.mak
RUN echo 'COMMON_CONFIG += LDFLAGS="-s"'                       >> config.mak
RUN echo 'COMMON_CONFIG += --disable-nls'                      >> config.mak
RUN echo 'GCC_CONFIG    += --enable-languages=c,c++'           >> config.mak
RUN echo 'GCC_CONFIG    += --disable-libquadmath'              >> config.mak
RUN echo 'GCC_CONFIG    += --disable-decimal-float'            >> config.mak
RUN echo 'GCC_CONFIG    += --enable-default-pie'               >> config.mak
RUN echo 'GCC_CONFIG    += --enable-default-ssp'               >> config.mak
RUN echo 'COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=' >> config.mak

# Quiet Log
RUN sed -i -e 's@tar zxvf@tar zxf@' Makefile
RUN sed -i -e 's@tar jxvf@tar jxf@' Makefile
RUN sed -i -e 's@tar Jxvf@tar Jxf@' Makefile

# Build
RUN make -j $(nproc) install

WORKDIR ..

RUN curl -fsSL --retry 10 --retry-connrefused -o musl-fts-master.tar.gz \
      https://github.com/pullmoll/musl-fts/archive/master.tar.gz

RUN tar -xf musl-fts-master.tar.gz && rm musl-fts-master.tar.gz

WORKDIR musl-fts-master

RUN ./bootstrap.sh
RUN ./configure --prefix=/usr/local${TARGET} \
      --build=x86_64-alpine-linux-musl --host=${TARGET}
RUN make -j $(nproc) install

# Prod Stage
FROM debian:stable-slim

# Copy Binary
COPY --from=build /usr/local /usr/local
RUN ldconfig
