FROM ubuntu:bionic as builder

ARG TOR_VER=0.4.2.7
ARG LIBEVENT_VER=2.1.11
ARG OPENSSL_VER=1.1.1d
ARG ZLIB_VER=1.2.11
ARG XZ_VER=5.2.4

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
 apt-get -y upgrade && \
 apt-get install -y \
	automake \
    autopoint \
    build-essential \
    ca-certificates \
    curl \
    git \
	gcc \
	g++ \
	libminiupnpc-dev \
	libseccomp-dev \
    libtool \
    libssl-dev \
	xmlto && \
 mkdir -p /usr/src/

WORKDIR /usr/src/
RUN curl -SL https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VER}-stable/libevent-${LIBEVENT_VER}-stable.tar.gz | tar zxf - && \
  cd libevent-${LIBEVENT_VER}-stable && \
    ./configure \
      --prefix=$PWD/install \
      --disable-shared \ 
      --enable-static \
      --with-pic \
      --disable-samples && \
  make -j$(nproc) && \
  make install

WORKDIR /usr/src/
RUN  curl -SL https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz | tar zxf - && \
  cd openssl-${OPENSSL_VER} && \
  ./config \
    --prefix=$PWD/install no-shared no-dso no-zlib \
    --openssldir=$PWD/install && \
  make -j$(nproc) && \
  make install

WORKDIR /usr/src/
RUN  curl -SL https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz | tar zxf - && \
  cd zlib-${ZLIB_VER} && \
  ./configure \ 
    --prefix=$PWD/install && \
  make -j$(nproc) && \
  make install

WORKDIR /usr/src
RUN curl -SL https://tukaani.org/xz/xz-${XZ_VER}.tar.gz | tar zxf - && \
  cd xz-${XZ_VER} && \
  ./autogen.sh && \
  ./configure \
    --prefix=$PWD/install \
    --disable-shared \
    --enable-static \
    --disable-doc \
    --disable-scripts \
    --disable-xz \
    --disable-xzdec \
    --disable-lzmadec \
    --disable-lzmainfo \
    --disable-lzma-links && \
  make -j$(nproc) && \
  make install

WORKDIR /usr/src
RUN git clone -b "tor-$TOR_VER" https://git.torproject.org/tor.git && \
    cd tor && \
    ./autogen.sh && \
    LIBS="-lssl -lcrypto -lpthread -ldl" ./configure \
    --prefix=$PWD/install \
    --disable-system-torrc \
    --disable-asciidoc \
    --disable-systemd \
    --disable-lzma \
    --with-libevent-dir=/usr/src/libevent-${LIBEVENT_VER}-stable/install \
    --with-openssl-dir=/usr/src/openssl-${OPENSSL_VER}/install \
    --with-zlib-dir=/usr/src/zlib-${ZLIB_VER}/install \
    --enable-static-libevent \
    --enable-static-openssl \
    --enable-static-zlib && \
  make -j$(nproc) && \
  make install

FROM ubuntu:bionic
RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
    iptables \
    iproute2 && \
 useradd -m -u 9001 -s /bin/bash tor

WORKDIR /home/tor

COPY --from=builder /usr/src/tor/install/bin/tor .
COPY --chown=tor:tor ./torrc .
COPY ./entrypoint /
COPY ./iptables.rules /tmp/iptables.rules
COPY ./ip6tables.rules /tmp/ip6tables.rules
ENTRYPOINT ["/bin/bash", "/entrypoint"]

CMD ["./tor -f ./torrc"]
