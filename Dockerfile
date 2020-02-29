FROM ubuntu:bionic

ARG TOR_VER=0.4.2.6
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
 apt-get -y upgrade && \
 apt-get install -y \
	asciidoc \
	automake \
    ca-certificates \
	docbook-xsl \
	docbook-xml \
    git \
	gcc \
	g++ \
    iptables \
    iproute2 \
	libevent-dev \
	libminiupnpc-dev \
	libseccomp-dev \
	libssl-dev \
	make \
	xmlto \
	zlib1g-dev \
	--no-install-recommends && \
 useradd -m -u 9001 -s /bin/bash tor && \
 mkdir -p /usr/src/ && \
 git clone -b "tor-$TOR_VER" https://git.torproject.org/tor.git  /usr/src/tor

WORKDIR /usr/src/tor

RUN ./autogen.sh && \
 ./configure && \
 make -j4 && \
 make install && \
 chown -R tor:tor /usr/src/tor

COPY ./entrypoint /
COPY ./iptables.rules /tmp/iptables.rules
ENTRYPOINT ["/bin/bash", "/entrypoint"]

EXPOSE 9001 9040 9050 5353/udp

CMD ["/usr/local/bin/tor -f /etc/torrc"]
