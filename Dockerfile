FROM ubuntu:18.04

LABEL maintainer="plein@purestorage.com"

# Set up buildtime environment. ARG is only used in build time, not run time
# The user we will run as.
ARG USER=iridium
ARG PASSWORD=iridium
ARG IUID=7777

ENV SSH_PORT=7777 

# Versions etc for building the dockerfile
# Version of s5cmd
ARG  S5CMDVERSION=1.0.0
# Used by git to download the Gist I host of a file we need
ARG  RUNUTILGIST=841f3e5ce73da9a3bea7e7d31fdb7651
# helps apt run better non-interactively
ARG  DEBIAN_FRONTEND=noninteractive

# Set up apt and get various things we need. Set time to Central. This can be overridden in the docker-compose.yaml or via docker run CLI
RUN apt-get update && \	
    apt install -y tzdata curl wget git pv iperf3 fio bash-completion iputils-ping openssh-server openssh-client && \
    ln -fs /usr/share/zoneinfo/America/Chicago /etc/localtime && mkdir /run/sshd

# Install tools
#
# Workaround for NFSometer setup later
RUN rmdir /usr/local/bin && ln -s /usr/bin /usr/local/bin
# Install s5cmd
RUN curl -L https://github.com/peak/s5cmd/releases/download/v${S5CMDVERSION}/s5cmd_${S5CMDVERSION}_Linux-64bit.tar.gz | tar xzf - && \
    mv s5cmd /usr/local/bin/
# Install util.sh "run" command that makes pretty output like you are typing. Useful for demos.
RUN git clone https://gist.github.com/${RUNUTILGIST}.git && mv /${RUNUTILGIST}/util.sh /usr/local/bin/ && chmod +x /usr/local/bin/util.sh && \
    rm -rf /${RUNUTILGIST}
# Install python packages for NFSometer - tzdata already installed above
#RUN apt install -y time python-setuptools python-mako python-matplotlib python-numpy nfs-common
# NFSometer version, if we decide to use it
#ARG  NFSOMETERVERSION=1.9
# Install NFSometer https://wiki.linux-nfs.org/wiki/index.php/NFSometer
#RUN curl -L http://www.linux-nfs.org/~dros/nfsometer/releases/nfsometer-${NFSOMETERVERSION}.tar.gz | tar xzf - && \
#    cd /nfsometer-${NFSOMETERVERSION} && python setup.py install && cd / && rm -rf /nfsometer-${NFSOMETERVERSION}

#RUN apt-get -y upgrade 
RUN apt-get clean && rm -rf /var/lib/apt/lists/

RUN echo "source /usr/local/bin/util.sh" >> ~root/.bashrc
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~root/.bashrc

RUN adduser --uid "$IUID" --shell /bin/bash --disabled-login --gecos "" "$USER" \
    && mkdir /home/$USER/.ssh && ssh-keygen -t rsa -f "/home/$USER/.ssh/id_rsa" -N "" && chown -R $USER:$USER /home/$USER/.ssh \
    && cp /home/iridium/.ssh/id_rsa /home/iridium/.ssh/authorized_keys && echo "$USER:$PASSWORD" | chpasswd
     

EXPOSE ${SSH_PORT}/tcp
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

