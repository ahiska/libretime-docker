FROM debian:buster

MAINTAINER "gui@odc.live"

ENV HOSTNAME localhost
ENV DEBIAN_FRONTEND noninteractive
ENV XDG_RUNTIME_DIR 0
ENV LIBRE_V 3.0.0-alpha.9

COPY pkgs_list.apt /pkgs_list.apt

RUN apt-get update && apt-get install --no-install-recommends -y apt-utils && \
      apt-get install --no-install-recommends -y $(cat /pkgs_list.apt)


RUN mkdir /src && cd /src && \
      url="https://github.com/ahiska/libretime/archive/$LIBRE_V.tar.gz" && \
      file=$(curl $url | sed 's/.* href="//' | sed 's/">.*//') && \
      curl $file -o libretime.tar.gz && tar xzvf libretime.tar.gz

WORKDIR "/src" 

RUN locale-gen --purge en_US.UTF-8 && \
      update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

COPY systemctl.py /usr/bin/systemctl

RUN test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl

COPY pkgs_list.apt /pkgs_list.apt

RUN apt-get install --no-install-recommends -y $(cat /pkgs_list.apt)

COPY scripts/libre_start.sh /libre_start.sh

COPY scripts/preparation.sh /preparation.sh

RUN /preparation.sh

ADD scripts/start.sh /

# useful for passing liquidsoap configs down the line
RUN mkdir /liquidsoap && \
      cp -r /usr/local/lib/python3.7/dist-packages/liquidsoap/* /liquidsoap

WORKDIR /

VOLUME ["/etc/airtime", "/var/lib/postgresql/10/main", "/srv/airtime/stor", \
  "/srv/airtime/watch", "/usr/local/lib/python3.7/dist-packages/airtime_playout-1.0-py3.7.egg/liquidsoap/"]

EXPOSE 80 8000

CMD /start.sh && exec /usr/bin/systemctl
