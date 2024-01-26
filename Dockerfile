
FROM ubuntu:jammy

# 'jammy' is Ubuntu 22.04 



#    Gradle is downloaded via Gradle Wrapper in Limelight Core so NO need to add here



RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install openjdk-21-jdk wget curl locales ant unzip

#   For Java 8, change above to openjdk-8-jdk and then run following 'apt-get -y update' command and 'update... --set...' command

# RUN apt-get -y update

#   DOES NOT COMPLETE when --list is run
# RUN update-java-alternatives --list

# RUN  update-java-alternatives --set  /usr/lib/jvm/java-1.8.0-openjdk-amd64

RUN java -version

# Configure locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Setup certificates in openjdk-8
# RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

#  https://nodejs.org/en/about/previous-releases

#   * https://deb.nodesource.com/setup_20.x — Node.js 20 "Iron" (current)

#  when run 'npm'   npm notice New minor version of npm available! 10.2.4 -> 10.3.0


# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global npm@10.3.0
    
