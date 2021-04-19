# Alias this container as builder:
FROM haultrax/elixir-builder:1.10.4-slim as builder

WORKDIR /dispatch_phx

ARG commit="Not specified"
ARG branch="Not specified"
ARG app_version="Not specified"
ARG creator="Not specified"
ARG site=local
ARG token

LABEL git-commit=${commit} \
  git-branch=${branch} \
  version=${app_version} \
  org="Haultrax" \
  creator=${creator} \
  application="dispatch" \
  site=${site}

RUN git config --global url."https://${token}:@github.com/".insteadOf "https://github.com/"

COPY phx .

# Delete all config
RUN rm -rf config

# copy over production config
COPY phx/config/config.exs config/config.exs
COPY phx/config/prod.exs config/prod.exs
COPY phx/config/releases.exs config/releases.exs

# Get and compile dependencies
RUN MIX_ENV=prod mix deps.get
RUN MIX_ENV=prod mix deps.compile

# Compile application
RUN MIX_ENV=prod mix phx.digest
RUN MIX_ENV=prod mix release

###############
### Release ###
###############
FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install erlang-tools erlang-xmerl bash openssl locales -y
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen en_US.UTF-8 && \
  dpkg-reconfigure locales && \
  /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8


ARG PORT=4001
EXPOSE $PORT

ENV PORT=$PORT \
  MIX_ENV=prod \
  REPLACE_OS_VARS=true \
  SHELL=/bin/bash \
  LANG=en_US.UTF-8 \
  LC_CTYPE="en_US.UTF-8"

## Install App
WORKDIR /dispatch_phx
COPY --from=builder /dispatch_phx/_build/prod/rel/dispatch_web .

## RUN
RUN chown -R root: .
USER root
CMD ["bin/dispatch_web", "start"]