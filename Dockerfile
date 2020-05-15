FROM ubuntu:18.04

LABEL maintainer="plein@purestorage.com"

ARG  S5CMDVERSION=1.0.0
ARG  RUNUTILGIST=841f3e5ce73da9a3bea7e7d31fdb7651
ARG  NFSOMETERVERSION=1.9
ARG  DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \	
    apt install -y tzdata curl wget git pv iperf3 fio bash-completion iputils-ping && \
    ln -fs /usr/share/zoneinfo/America/Chicago /etc/localtime

# Install tools
#
# Workaround for python setup later
RUN rmdir /usr/local/bin && ln -s /usr/bin /usr/local/bin
# Install s5cmd
RUN curl -L https://github.com/peak/s5cmd/releases/download/v${S5CMDVERSION}/s5cmd_${S5CMDVERSION}_Linux-64bit.tar.gz | tar xzf - && \
    mv s5cmd /usr/local/bin/
# Install util.sh "run" command that makes pretty output like you are typing. Useful for demos.
RUN git clone https://gist.github.com/${RUNUTILGIST}.git && mv /${RUNUTILGIST}/util.sh /usr/local/bin/ && chmod +x /usr/local/bin/util.sh && \
    rm -rf /${RUNUTILGIST}
# Install python packages for NFSometer - tzdata already installed above
RUN apt install -y time python-setuptools python-mako python-matplotlib python-numpy nfs-common
# Install NFSometer https://wiki.linux-nfs.org/wiki/index.php/NFSometer
RUN curl -L http://www.linux-nfs.org/~dros/nfsometer/releases/nfsometer-${NFSOMETERVERSION}.tar.gz | tar xzf - && \
    cd /nfsometer-${NFSOMETERVERSION} && python setup.py install && cd / && rm -rf /nfsometer-${NFSOMETERVERSION}

#RUN apt-get -y upgrade 
RUN apt-get clean && rm -rf /var/lib/apt/lists/

RUN echo "source /usr/local/bin/util.sh" >> ~root/.bashrc
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~root/.bashrc

# hack to let this run in the background without failing
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"   

