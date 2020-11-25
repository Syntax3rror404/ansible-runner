FROM python:3-alpine
MAINTAINER Marcel Zapf <zapfmarcel@live.de>

ADD ./requirements.txt /tmp/requirements.txt
RUN echo "===> Installing GCC..."  && \
    apk add build-base && \
    echo "===> Installing pip requirements file..."  && \
    pip3 install -r /tmp/requirements.txt && \
    echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts
ADD ./entrypoint.sh /tmp/entrypoint.sh
RUN chmod 777 /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]
