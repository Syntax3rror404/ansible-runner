# Final image
FROM alpine:latest
MAINTAINER Marcel Zapf <zapfmarcel@live.de>
RUN apk --update --no-cache add \
        unzip \
        git \
        python3 \
        python3-dev \
        py3-pip \
        gcc \
        make \
        curl \
        musl-dev \
        libffi-dev \
        openssl-dev

# Install Python requirements
ADD ./requirements.txt /tmp/requirements.txt
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
RUN pip3 install --upgrade pip
RUN pip3 install -r /tmp/requirements.txt

RUN apk add --no-cache python3 libffi curl jq
RUN echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost ansible_connection=local">> /etc/ansible/hosts && \
    echo '127.0.0.1 localhost' >> /etc/hosts && \
    echo "===> Install APK packages..."  && \
    apk update && \
    apk add --no-cache \
    openssh-client \
    openssh-keygen \
    openssh \
    git 

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa

RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    passwd -d root && \
    mkdir /root/.ssh && \
    cp /etc/ssh/ssh_host_rsa_key  /root/.ssh/id_rsa && \
    cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys

ADD ./entrypoint.sh /tmp/entrypoint.sh

RUN chmod 777 /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
