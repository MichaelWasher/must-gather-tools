FROM quay.io/fedora:34

ADD ./performance.sh /usr/bin/gather
RUN yum install -y rsync oc &&
    chmod +x /usr/bin/gather
ENTRYPOINT /usr/bin/gather
