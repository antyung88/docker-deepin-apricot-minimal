FROM debian:bullseye

ENV DEEPIN_MIRROR=https://community-packages.deepin.com/deepin/

ENV DEEPIN_RELEASE=apricot

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        multistrap \
        gnupg && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51 && \
    mkdir -p /rootfs/etc/apt && \
    cp /etc/apt/trusted.gpg /rootfs/etc/apt/trusted.gpg && \
    echo "deb     $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" > /rootfs/etc/apt/sources.list && \
    echo "deb-src $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" >> /rootfs/etc/apt/sources.list

RUN echo '#! /bin/sh\n\
env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y\n\
apt-get clean\n\
find /var/lib/apt/lists -type f -delete\n\
find /var/cache -type f -delete\n\
find /var/log -type f -delete\n\
exit 0\n\
' > /rootfs/cleanup && chmod +x /rootfs/cleanup

RUN echo "[General]\n\
arch=amd64\n\
directory=/rootfs/\n\
cleanup=true\n\
noauth=false\n\
unpack=true\n\
explicitsuite=false\n\
multiarch=\n\
aptsources=Debian\n\
bootstrap=Deepin\n\
[Deepin]\n\
packages=apt\n\
source=$DEEPIN_MIRROR\n\
keyring=debian-archive-keyring\n\
suite=$DEEPIN_RELEASE\n\
" >/deepin.multistrap

RUN multistrap -f /deepin.multistrap

RUN mkdir -p /rootfs/etc/apt && \
    cp /etc/apt/trusted.gpg /rootfs/etc/apt/trusted.gpg && \
    echo "deb     $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" > /rootfs/etc/apt/sources.list && \
    echo "deb-src $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" >> /rootfs/etc/apt/sources.list

RUN chroot ./rootfs /usr/bin/apt-get update && \
    chroot ./rootfs env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    chroot ./rootfs /cleanup 

FROM scratch
COPY --from=0 /rootfs /

ENV SHELL=/bin/bash
ENV LANG=en_US.UTF-8

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        init \
        apt-transport-https \
        ca-certificates \
        dbus-x11 \
        deepin-keyring \
        gnupg \
        libcups2 \
        locales \
        nano \
        procps \
        psmisc && \

    /cleanup && rm /cleanup

CMD ["bash"]
