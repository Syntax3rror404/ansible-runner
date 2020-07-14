FROM debian:buster
MAINTAINER Marcel Zapf <zapfmarcel@live.de>

RUN echo "===> Installing required toolcain "  && \
    apt-get update -y                         && \
    DEBIAN_FRONTEND=noninteractive               \
    apt-get install -y sudo python python-yaml openssh-client openssh-server\
                        curl gcc python-pip python-dev libffi-dev libssl-dev openssh-client && \
    apt-get -y --purge remove python-cffi          && \
    pip install --upgrade pycrypto cffi pywinrm    && \
    echo "===> Installing Ansible over pip "   && \
    pip install ansible                 && \
    echo "===> Removing unused resources "                  && \
    apt-get -f -y --auto-remove remove \
                 gcc python-pip python-dev libffi-dev libssl-dev  && \
    apt-get clean                                                 && \
    rm -rf /var/lib/apt/lists/*  /tmp/*                           && \
    echo "==> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts
ADD ./entrypoint.sh /tmp/entrypoint.sh
RUN chmod 777 /tmp/docker-entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]
