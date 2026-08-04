FROM saschpe/android-sdk:35-jdk21.0.4_7 as android-sdk
ARG ANDROID_BUILD_TOOLS_VERSION=36.1.0
RUN ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION sdkmanager --install "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
RUN ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION && \
    SRCDIR=/opt/android-sdk-linux && \
    DSTDIR=/selected-parts/android-sdk-linux && \
    mkdir -p $DSTDIR/build-tools && \
    cp -r $SRCDIR/platform-tools $DSTDIR/ && \
    cp -r  $SRCDIR/build-tools/$ANDROID_BUILD_TOOLS_VERSION $DSTDIR/build-tools/ && \
    ln -s $ANDROID_BUILD_TOOLS_VERSION $DSTDIR/build-tools/current

FROM ubuntu:24.04 as builder

COPY scripts/installation/prepare.sh /root/scripts/installation/
RUN /root/scripts/installation/prepare.sh

COPY --from=android-sdk /selected-parts/android-sdk-linux /root/scripts/installation/installed/usr/local/android-sdk-linux/
#COPY --from=android-sdk /opt/android-sdk-linux/platforms/android-35/android.jar /root/scripts/installation/installed/usr/local/android-sdk-linux/platforms/android-35/android.jar

COPY scripts/installation /root/scripts/installation/
# Version in '1.2.3' format or 'local' for local build
ARG DOCKER_IMAGE_BUILD_VERSION=local
# Build mode: 'full' or 'versions' (to collect only versions without installation)
ARG DOCKER_IMAGE_BUILD_MODE=full
RUN DOCKER_IMAGE_BUILD_VERSION=$DOCKER_IMAGE_BUILD_VERSION DOCKER_IMAGE_BUILD_MODE=$DOCKER_IMAGE_BUILD_MODE /root/scripts/installation/install.all.sh

FROM ubuntu:24.04

ENV PATH="/usr/local/python-venvs/bin:/usr/local/python-venv/bin:$PATH:/usr/local/android-sdk-linux/platform-tools:/usr/local/android-sdk-linux/build-tools/current"

WORKDIR /work
COPY scripts/run/ /
RUN /root/scripts/run/prepare.sh && rm -rf /root/scripts

COPY --from=builder /root/scripts/installation/installed /

# Allow running the container as an arbitrary (non-root) host UID while keeping
# /root as the single shared HOME (frida/adb configs and .bashrc live there). The
# jddlab launcher maps the host user's UID:GID by default on Linux/macOS so files
# written to /work are owned by the user instead of root. A mapped UID has no
# /etc/passwd entry, so HOME=/root must be world read/write to work for everyone.
RUN chmod -R a+rwX /root

# Host-side helpers shipped INSIDE the image. The jddlab launcher copies this tree out
# of the image into ~/.jddlab/mcp/current (via `docker cp`) to run the MCP server and
# install AI skills - so the host files always match the image and no separate download
# is needed. Layout mirrors the install roots: current/{mcp,skills,tools,VERSION}.
COPY mcp     /usr/local/jddlab/host/mcp
COPY skills  /usr/local/jddlab/host/skills
COPY tools   /usr/local/jddlab/host/tools
COPY VERSION /usr/local/jddlab/host/VERSION
# The real (full) launcher lives in the image too, so the thin launcher a user
# downloads once stays tiny and the real logic is refreshed by `docker pull`.
COPY launcher/jddlab     /usr/local/jddlab/host/jddlab
COPY launcher/jddlab.cmd /usr/local/jddlab/host/jddlab.cmd