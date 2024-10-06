FROM ubuntu:22.04 as builder

COPY scripts/installation/prepare.sh /root/scripts/installation/
RUN /root/scripts/installation/prepare.sh

COPY scripts/installation /root/scripts/installation/
ARG DOCKER_IMAGE_BUILD_VERSION=local
RUN DOCKER_IMAGE_BUILD_VERSION=$DOCKER_IMAGE_BUILD_VERSION /root/scripts/installation/install.all.sh

FROM ubuntu:22.04

ENV PATH="/usr/local/python-venv/bin:$PATH"
WORKDIR /work
COPY scripts/run/prepare.sh /root/scripts/run/
RUN /root/scripts/run/prepare.sh && rm -rf /root/scripts

COPY --from=builder /root/scripts/installation/installed /