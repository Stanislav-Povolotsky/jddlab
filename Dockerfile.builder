FROM ubuntu:24.04 as builder

COPY scripts/installation/prepare.sh /root/scripts/installation/
RUN /root/scripts/installation/prepare.sh
