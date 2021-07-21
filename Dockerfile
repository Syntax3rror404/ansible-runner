ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION} AS builder

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

# Install Terraform CLI
ARG TERRAFORM_VERSION=1.0.2
WORKDIR /opt/terraform
RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o file.zip && \
    unzip file.zip && rm file.zip

# Install TFE_helper
ARG TFHELPER_VERSION=release
WORKDIR /opt/tf-felper
RUN git clone -b ${TFHELPER_VERSION} https://github.com/hashicorp-community/tf-helper.git .

# Install Python requirements
ADD ./requirements.txt /tmp/requirements.txt
WORKDIR /opt/venv
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" VIRTUAL_ENV="/opt/venv"
RUN pip3 install --upgrade pip
RUN pip3 install -r /tmp/requirements.txt

# Final image
FROM alpine:${ALPINE_VERSION}
MAINTAINER Marcel Zapf <zapfmarcel@live.de>
RUN apk add --no-cache python3 libffi curl jq
RUN echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost ansible_python_interpreter=/usr/bin/python3" >> /etc/ansible/hosts && \
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
CMD ["/usr/bin/sudo", "/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/terraform:/opt/tf-felper/tfh/bin:/opt/venv/bin" VIRTUAL_ENV="/opt/venv"
COPY --from=builder /opt /opt
