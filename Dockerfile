FROM centos:7

MAINTAINER Nick Maiorsky <nick.maiorsky@shipwire.com

RUN yum update -y
RUN yum install -y wget \
	&& yum -y group install "Development Tools" 
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm

RUN rpm -ivh jdk-8*-linux-x64.rpm && rm jdk-8*-linux-x64.rpm

ENV JAVA_HOME /usr/java/latest

#
# Maven
#


ENV MAVEN_VERSION=3.3.9
ENV MAVEN_HOME=/opt/mvn

# change to tmp folder
WORKDIR /tmp

# Download and extract maven to opt folder

USER root
RUN wget --no-check-certificate --no-cookies http://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && wget --no-check-certificate --no-cookies http://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz.md5 \
    && echo "$(cat apache-maven-${MAVEN_VERSION}-bin.tar.gz.md5) apache-maven-${MAVEN_VERSION}-bin.tar.gz" | md5sum -c \
    && tar -zvxf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt/ \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/mvn \
    && rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz.md5

# add executables to path
RUN update-alternatives --install "/usr/bin/mvn" "mvn" "/opt/mvn/bin/mvn" 1 && \
    update-alternatives --set "mvn" "/opt/mvn/bin/mvn"

#
# Jenkins Slave
#

ENV HOME /home/jenkins
RUN useradd -c "Jenkins user" -d $HOME -m jenkins

ARG VERSION=2.60

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar


COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod 755 /usr/local/bin/jenkins-slave

VOLUME /home/jenkins_slave
WORKDIR /home/jenkins_slave
USER jenkins

RUN echo $PATH

ENTRYPOINT ["jenkins-slave"]

#
# Purge
#
USER root

RUN rm -rf /sbin/sln \
    ; rm -rf /var/cache/{ldconfig,yum}/*