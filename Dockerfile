
#  Docker Image to build limelight-core  

#   if existing command not work to build docker image, see https://docs.docker.com/go/buildx/

FROM ubuntu:jammy

# 'jammy' is Ubuntu 22.04 

# Gradle is downloaded via Gradle Wrapper in Limelight Core so NO need to add here

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install openjdk-21-jdk wget curl locales ant unzip

RUN java -version

# Configure locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

#  https://nodejs.org/en/about/previous-releases

#   * https://deb.nodesource.com/setup_20.x — Node.js 20 "Iron" (current)

# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global npm@10.3.0
    
