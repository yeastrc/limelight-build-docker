FROM ubuntu:xenial

ENV GRADLE_VERSION 5.6.4

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install openjdk-8-jdk wget curl locales ant unzip

# Configure locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Setup certificates in openjdk-8
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Set path
ENV PATH ${PATH}:/usr/local/gradle-$GRADLE_VERSION/bin

# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global npm@7

# Install gradle
RUN wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip && \
    unzip gradle-$GRADLE_VERSION-bin.zip && \
    rm -f gradle-$GRADLE_VERSION-bin.zip
