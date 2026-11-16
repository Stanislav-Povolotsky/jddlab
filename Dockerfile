# check=skip=FromPlatformFlagConstDisallowed
FROM saschpe/android-sdk:35-jdk21.0.4_7 AS android-sdk
ARG ANDROID_BUILD_TOOLS_VERSION=36.1.0
RUN ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION sdkmanager --install "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
RUN ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION && \
    SRCDIR=/opt/android-sdk-linux && \
    DSTDIR=/selected-parts/android-sdk-linux && \
    mkdir -p $DSTDIR/build-tools && \
    cp -r $SRCDIR/platform-tools $DSTDIR/ && \
    cp -r  $SRCDIR/build-tools/$ANDROID_BUILD_TOOLS_VERSION $DSTDIR/build-tools/ && \
    ln -s $ANDROID_BUILD_TOOLS_VERSION $DSTDIR/build-tools/current

# Binary fixtures for the smoke tests (tests/smoke.sh). Platform-independent, so
# they are built once, on amd64 (hermesc is an x86_64 binary).
FROM --platform=linux/amd64 ubuntu:24.04 AS test-fixtures
ARG HERMES_COMPILER_VERSION=0.17.0
ARG DOTNET_FIXTURE_PACKAGE=system.runtime.compilerservices.unsafe/6.0.0
RUN apt-get update && apt-get install -y curl unzip ca-certificates && rm -rf /var/lib/apt/lists/*
COPY tests/fixtures/src /fixtures/src
# React Native Hermes bytecode bundle
RUN mkdir -p /tmp/hermes && cd /tmp/hermes && \
    curl -fsSL -o hermes.tgz https://registry.npmjs.org/hermes-compiler/-/hermes-compiler-$HERMES_COMPILER_VERSION.tgz && \
    tar xzf hermes.tgz && \
    package/hermesc/linux64-bin/hermesc -emit-binary -O -out /fixtures/index.android.bundle /fixtures/src/hermes/index.android.js && \
    rm -rf /tmp/hermes
# A small real .NET assembly (MIT, from NuGet)
RUN mkdir -p /fixtures/dotnet /tmp/nupkg && cd /tmp/nupkg && \
    curl -fsSL -o p.nupkg "https://api.nuget.org/v3-flatcontainer/$(echo $DOTNET_FIXTURE_PACKAGE | cut -d/ -f1)/$(echo $DOTNET_FIXTURE_PACKAGE | cut -d/ -f2)/$(echo $DOTNET_FIXTURE_PACKAGE | tr / .).nupkg" && \
    unzip -q p.nupkg 'lib/netstandard2.0/*.dll' && \
    cp lib/netstandard2.0/*.dll /fixtures/dotnet/Fixture.dll && \
    rm -rf /tmp/nupkg

FROM ubuntu:24.04 AS builder

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
RUN /root/scripts/run/prepare.sh && rm -rf /root/scripts && chmod +x /usr/local/jddlab/entrypoint.sh

COPY --from=builder /root/scripts/installation/installed /

# Allow running the container as an arbitrary (non-root) host UID while keeping
# /root as the single shared HOME (frida/adb configs and .bashrc live there). The
# jddlab launcher maps the host user's UID:GID by default on Linux/macOS so files
# written to /work are owned by the user instead of root. A mapped UID has no
# /etc/passwd entry, so HOME=/root must be world read/write to work for everyone.
RUN chmod -R a+rwX /root

# Optional ADB forwarding to the host ADB server (JDDLAB_ADB_SERVER), see entrypoint.sh
ENTRYPOINT ["/usr/local/jddlab/entrypoint.sh"]
CMD ["bash"]

# Smoke tests (run by CI on every image build; can be run by users too):
#   docker run --rm stanislavpovolotsky/jddlab bash /usr/local/jddlab/tests/smoke.sh
COPY tests/smoke.sh /usr/local/jddlab/tests/smoke.sh
COPY example/simple.apk /usr/local/jddlab/tests/fixtures/simple.apk
COPY tests/fixtures/src/mobsfscan /usr/local/jddlab/tests/fixtures/src/mobsfscan
COPY --from=test-fixtures /fixtures/index.android.bundle /usr/local/jddlab/tests/fixtures/index.android.bundle
COPY --from=test-fixtures /fixtures/dotnet /usr/local/jddlab/tests/fixtures/dotnet

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
