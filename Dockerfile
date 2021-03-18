FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ENV HOME="/config"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN \
	echo "**** install node repo ****" && \
	apt-get update && \
	apt-get install -y \
	gnupg && \
	curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
	echo 'deb https://deb.nodesource.com/node_12.x bionic main' \
	> /etc/apt/sources.list.d/nodesource.list && \
	curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
	echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
	> /etc/apt/sources.list.d/yarn.list && \
	echo "**** install build dependencies ****" && \
	apt-get update && \
	apt-get install -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
	echo "**** install runtime dependencies ****" && \
	apt-get install -y \
	git \
	jq \
	nano \
	net-tools \
	nodejs \
	sudo \
	yarn && \
	echo "**** install code-server ****" && \
	if [ -z ${CODE_RELEASE+x} ]; then \
	CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
	fi && \
	CODE_VERSION=$(echo "$CODE_RELEASE" | awk '{print substr($1,2); }') && \
	yarn config set network-timeout 600000 -g && \
	yarn --production --verbose --frozen-lockfile global add code-server@"$CODE_VERSION" && \
	yarn cache clean && \
	echo "**** clean up ****" && \
	apt-get purge --auto-remove -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
	echo "**** install code-server ****" && \
	apt-get install -y software-properties-common && \
	add-apt-repository ppa:ondrej/php &&\
	apt-get update &&\
	apt-get install -y \
	nginx \
	memcached \
	php7.4-bcmath \
	php7.4-bz2 \
	php7.4-cgi \
	php7.4-common \
	php7.4-curl \
	php7.4-fpm \
	php7.4-intl \
	php7.4-json \
	php7.4-mbstring \
	php7.4-opcache \
	php7.4-xml \
	php7.4-zip \
	supervisor && \
	apt-get clean && \
	echo "**** configure nginx ****" && \
	rm -f /etc/nginx/conf.d/default.conf && \
	rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY /root /

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY config/php.ini /etc/php/7.4/fpm/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html
RUN mkdir -p /run/php
RUN touch /php.log && chmod 777 /php.log

# Add application
WORKDIR /var/www/html
COPY src/ /var/www/html/

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]