FROM debian:bullseye-slim

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    lib32gcc-s1 \
    lib32stdc++6 \
    zlib1g:i386 \
    rsync \
    unzip \
    wget \
    locales \
 && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && dpkg-reconfigure --frontend=noninteractive locales \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m csgo

USER csgo

RUN mkdir /home/csgo/Steam && \
    mkdir /home/csgo/server

WORKDIR /home/csgo/Steam

RUN wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxf - \
    && /home/csgo/Steam/steamcmd.sh +quit \
    && mkdir -p /home/csgo/.steam/sdk32 \
    && ln -s /home/csgo/Steam/linux32/steamclient.so /home/csgo/.steam/sdk32/steamclient.so

WORKDIR /home/csgo

COPY server.sh .

CMD [ "/home/csgo/server.sh" ]