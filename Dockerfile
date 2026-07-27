
#  Docker Image to build limelight-core

#   if existing command not work to build docker image, see https://docs.docker.com/go/buildx/

FROM ubuntu:24.04

# Gradle is downloaded via Gradle Wrapper in Limelight Core so NO need to add here

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    wget curl gnupg ca-certificates locales ant unzip xz-utils

# --- Amazon Corretto apt repo ---
#   Provides JDK 25 (build/run Gradle + all Java 25 projects) and JDK 8
#   (for limelight_submit_import + limelight_submit_import_client_connector).
#   openjdk-25 is not in Ubuntu's archive, and newer Ubuntu releases drop openjdk-8,
#   so one vendor repo serving both versions is the stable choice on 24.04 LTS.
RUN wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" \
      > /etc/apt/sources.list.d/corretto.list

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
      java-25-amazon-corretto-jdk \
      java-1.8.0-amazon-corretto-jdk

# Resolve the real install dirs and pin stable symlinks.
#   `ls -d` exits non-zero if the glob matches nothing, so a bad assumption
#   breaks `docker build` here instead of silently producing a broken JAVA_HOME.
RUN ln -sfn "$(ls -d /usr/lib/jvm/java-25-amazon-corretto*)"  /usr/lib/jvm/corretto-25 && \
    ln -sfn "$(ls -d /usr/lib/jvm/java-1.8.0-amazon-corretto*)" /usr/lib/jvm/corretto-8

# Run the Gradle daemon on JDK 25; Gradle finds JDK 8 as a toolchain
# via /usr/lib/jvm auto-detection (Gradle 9.5.1).
ENV JAVA_HOME=/usr/lib/jvm/corretto-25
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN java -version && ls -1 /usr/lib/jvm

# Configure locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

#  https://nodejs.org/en/about/previous-releases
#   Node.js is installed from the official upstream binary tarball on nodejs.org
#   (the same source the official `node` Docker images use), NOT from a
#   third-party apt repo.  This avoids depending on deb.nodesource.com, whose
#   repo has returned 403 and broken this build.  NODE_VERSION pins the exact
#   release; the tarball already bundles a matching npm, so no separate npm pin.
ARG NODE_VERSION=24.18.0

# Install nodejs, verifying the download two ways before extracting:
#   1. GPG: fetch the Node release team's signing keys, then verify the
#      clearsigned SHASUMS256.txt.asc.  `gpg --decrypt` both checks the
#      signature (fails the build if it can't be verified against a trusted
#      key) and emits the authenticated checksum list.
#   2. SHA-256: check the tarball against that verified checksum list.
# So a corrupted OR tampered download fails here instead of producing a
# silently-bad image.
#
# Signing-key fingerprints are the current Node.js Releasers from the
# nodejs/node README "Release keys" section.  The full set is listed (not just
# the one signer of NODE_VERSION) so a version bump signed by a different
# releaser keeps verifying without editing this list.  The keyserver fetch is
# best-effort per key; the actual security gate is the gpg --decrypt below,
# which fails unless the specific key that signed NODE_VERSION was imported.
RUN set -eux; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in \
      5BE8A3F6C8A5C01D106C0AD820B1A390B168D356 \
      DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
      CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
      C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
      108F52B48DB57BB0CC439B2997B01419BD92F80A \
      655F3B5C1FB3FA8D1A0CA6BDE4A7D232B936D2FD \
      A363A499291CBBC940DD62E41F10027AF002F8B0 \
    ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com  --recv-keys "$key" || \
      echo "WARNING: could not fetch Node signing key $key"; \
    done; \
    curl -fsSLO --proto '=https' --tlsv1.2 \
      "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"; \
    curl -fsSLO --proto '=https' --tlsv1.2 \
      "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc"; \
    gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc; \
    grep " node-v${NODE_VERSION}-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "node-v${NODE_VERSION}-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner; \
    gpgconf --kill all || true; \
    rm -rf "$GNUPGHOME" "node-v${NODE_VERSION}-linux-x64.tar.xz" SHASUMS256.txt SHASUMS256.txt.asc; \
    node --version; npm --version

