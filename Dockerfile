FROM docker.io/ubuntu:noble AS builder

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y install git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/tt-rss/tt-rss.git /tt-rss

WORKDIR /tt-rss
ARG revision=8ed927dbd2
RUN git pull origin main && git checkout $revision && rm -rf .git

FROM docker.io/ubuntu:noble

EXPOSE 9000/tcp
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /tt-rss

ENV TTRSS_DB_HOST=""
ENV TTRSS_DB_NAME=""
ENV TTRSS_DB_USER=""
ENV TTRSS_DB_PASS=""
ENV TTRSS_SELF_URL_PATH=""

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y install uwsgi-core uwsgi-plugin-php \
    php8.3 php8.3-gd php8.3-pgsql php8.3-mbstring php8.3-intl \
    php8.3-xml php8.3-curl php8.3-zip postgresql-client \
    && rm -rf /var/lib/apt/lists/*

ADD entrypoint.sh /entrypoint.sh
COPY --from=builder /tt-rss /tt-rss
RUN cp /tt-rss/config.php-dist /tt-rss/config.php

RUN chmod -R 777 /tt-rss/cache /tt-rss/feed-icons /tt-rss/lock \
    && useradd -r ttrss \
    && chown -R ttrss /tt-rss

USER ttrss
