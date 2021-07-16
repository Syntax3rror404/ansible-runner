FROM python:3-alpine
MAINTAINER Marcel Zapf <zapfmarcel@live.de>

ADD ./requirements.txt /tmp/requirements.txt
ADD ./entrypoint.sh /tmp/entrypoint.sh

ARG CRYPTOGRAPHY_DONT_BUILD_RUST=1

RUN echo "===> Installing GIT..."  && \
    apk add git && \
    echo "===> Installing ssh-client..."  && \
    apk add openssh-client && \
    apk add openssh-keygen && \
    echo "===> Installing Terraform..."  && \
    wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip && \
    unzip terraform_0.13.5_linux_amd64.zip && \
    rm -rf terraform_0.13.5_linux_amd64.zip && \
    mv terraform /usr/local/bin/terraform && \
    chmod +x /usr/local/bin/terraform && \
    echo "===> Installing musl-dev..."  && \
    apk add musl-dev && \
    echo "===> Installing openssl-dev..."  && \
    apk add openssl-dev && \
    echo "===> Installing ffi-dev..."  && \
    apk add libffi-dev && \
    echo "===> Installing GCC..."  && \
    apk add build-base && \
    echo "===> Installing pip requirements file..."  && \
    pip3 install -r /tmp/requirements.txt && \
    echo "===> Remove unneeded resources after build..."  && \
    apk del build-base && \
    echo "===> Remove unneeded sources after build..."  && \
    rm -rf /src && echo "OK" && \
    echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

RUN chmod 777 /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]
