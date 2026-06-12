
#  Docker Image to build limelight-core

#   if existing command not work to build docker image, see https://docs.docker.com/go/buildx/

FROM ubuntu:24.04

# Gradle is downloaded via Gradle Wrapper in Limelight Core so NO need to add here

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    wget curl gnupg ca-certificates locales ant unzip

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
#   * https://deb.nodesource.com/setup_24.x — Node.js 24

# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global npm@11.12.1

