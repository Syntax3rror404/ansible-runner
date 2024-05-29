ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION} AS builder

# Install app dependencies
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
ARG TERRAFORM_VERSION=1.8.2
WORKDIR /opt/terraform
RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o file.zip && \
    unzip file.zip && rm file.zip

# Install Packer
ARG PACKER_VERSION=1.10.3
WORKDIR /opt/terraform
RUN curl https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -o file.zip && \
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
RUN pip3 install --upgrade pip && \
    pip3 install -r /tmp/requirements.txt

# Install MinIO Client
WORKDIR /usr/local/bin
RUN curl -O https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc

# Final image
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Syntax3rror404"

# Install runtime dependencies
RUN apk add --no-cache python3 libffi curl jq xorriso sshpass \
    openssh-client openssh-keygen openssh git && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa

# Create non-root user with specific UID/GID
RUN addgroup -g 65532 appgroup && \
    adduser -u 65532 -S appuser -G appgroup -h /home/appuser

# Copy from builder
COPY --from=builder /opt /opt
COPY --from=builder /usr/local/bin/mc /usr/local/bin/mc

# Adjust permissions to allow the non-root user access
RUN chown -R appuser:appgroup /opt && \
    mkdir /home/appuser/.ssh && \
    cp /etc/ssh/ssh_host_rsa_key /home/appuser/.ssh/id_rsa && \
    cp /etc/ssh/ssh_host_rsa_key.pub /home/appuser/.ssh/authorized_keys && \
    chown -R appuser:appgroup /home/appuser/.ssh

ADD ./entrypoint.sh /tmp/entrypoint.sh
RUN chmod 755 /tmp/entrypoint.sh && chown appuser:appgroup /tmp/entrypoint.sh

USER 65532

ENTRYPOINT ["/tmp/entrypoint.sh"]
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]

ENV PYTHONPATH "${PYTHONPATH}:/opt/venv/bin/python"
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/terraform:/opt/tf-felper/tfh/bin:/opt/venv/bin" VIRTUAL_ENV="/opt/venv"
