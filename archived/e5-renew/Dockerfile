FROM archlinux/base
MAINTAINER root@recolic.net

RUN pacman -Sy --noconfirm python python-requests

RUN mkdir /app
COPY . /app
WORKDIR /app

CMD ["/app/e5-renew.py"]

