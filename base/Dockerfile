FROM ubuntu:18.04

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus \
      iproute2 iputils-ping iputils-arping net-tools \
      curl ca-certificates vim-tiny less procps \
    && rm -rf /var/lib/apt/lists/*

# Strip systemd units that don't make sense inside a container
RUN find /lib/systemd/system/sysinit.target.wants/ -type l \
      ! -name 'systemd-tmpfiles-setup.service' -delete; \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /lib/systemd/system/local-fs.target.wants/* \
          /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/basic.target.wants/* \
          /lib/systemd/system/anaconda.target.wants/*

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
