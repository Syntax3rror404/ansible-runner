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
RUN pip3 install ansible-tower-cli
RUN pip3 install ansible-base
RUN pip3 install -r /tmp/requirements.txt && \

# Final image
FROM alpine:${ALPINE_VERSION}
RUN apk add --no-cache python3 libffi curl jq
RUN echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

RUN chmod 777 /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]

ENV PATH="/opt/terraform:/opt/tf-felper/tfh/bin:/opt/venv/bin:" VIRTUAL_ENV="/opt/venv"
COPY --from=builder /opt /opt
