FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ENV HOME="/config" \
  MYSQL_USER=mysql \
  MYSQL_VERSION=8.0 \
  MYSQL_DATA_DIR=/var/lib/mysql \
  MYSQL_RUN_DIR=/run/mysqld \
  MYSQL_LOG_DIR=/var/log/mysql

RUN \
  echo "**** install node repo ****" && \
  apt-get update && \
  apt-get install -y \
  gnupg && \
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo 'deb https://deb.nodesource.com/node_14.x focal main' \
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
  pkg-config \
  python3

RUN echo "**** install runtime dependencies ****" && \
  apt-get install -y \
  git \
  jq \
  nano \
  net-tools \
  nodejs \
  sudo \
  yarn

RUN echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
  CODE_RELEASE=$(curl -sX GET https://registry.yarnpkg.com/code-server \
  | jq -r '."dist-tags".latest' | sed 's|^|v|'); \
  fi && \
  CODE_VERSION=$(echo "$CODE_RELEASE" | awk '{print substr($1,2); }') && \
  npm config set python python3 && \
  yarn config set network-timeout 600000 -g && \
  yarn --production --verbose --frozen-lockfile global add code-server@"$CODE_VERSION" && \
  yarn global add typescript && \
  yarn cache clean

RUN echo "**** install web-server ****" && \
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
  php7.4-mysql \
  php7.4-xml \
  php7.4-zip \
  supervisor && \
  apt-get clean && \
  touch /php.log && \
  chmod 777 /php.log && \
  mkdir -p /run/php

RUN echo "**** install mysql ****" \
  && apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends mysql-server \
  && mkdir -p /var/run/mysqld \
  && mkdir -p ${MYSQL_DATA_DIR} \
  && chmod -R 0700 ${MYSQL_DATA_DIR} \
  && chown -R ${MYSQL_USER}:${MYSQL_USER} ${MYSQL_DATA_DIR} \
  && mkdir -p ${MYSQL_RUN_DIR} \
  && chmod -R 0755 ${MYSQL_RUN_DIR} \
  && chown -R ${MYSQL_USER}:root ${MYSQL_RUN_DIR}

RUN echo "**** clean up ****" && \
  apt-get purge --auto-remove -y \
  build-essential \
  libx11-dev \
  libxkbfile-dev \
  pkg-config && \
  apt-get clean && \
  rm -rf \
  /config/* \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

# add local files
COPY /root /


# ports and volumes
EXPOSE 8443
EXPOSE 80

RUN chmod a+w /etc/nginx/nginx.conf \
  && chmod -R 700 /etc/mysql

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
