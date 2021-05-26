FROM fredmassin/self-compiling_seiscomp_vanilla:jakarta

MAINTAINER Fred Massin  <fmassin@sed.ethz.ch>

ENV    WORK_DIR /usr/local/src
ENV INSTALL_DIR /opt/seiscomp3

# Fix Debian  env
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No
ENV FAKE_CHROOT 1

# Setup sysop's user and group id
ENV USER_ID 1000
ENV GROUP_ID 1000

WORKDIR $WORK_DIR
WORKDIR /home/sysop


COPY etc/*.cfg $INSTALL_DIR/etc/
COPY jakarta/etc/*.cfg $INSTALL_DIR/etc/

RUN cd $INSTALL_DIR/../ && \
    wget "https://www.seiscomp.de/seiscomp3/downloader/seiscomp3-jakarta-maps.tar.gz" && \
    tar xzf seiscomp3-jakarta-maps.tar.gz && \
    rm seiscomp3-jakarta-maps.tar.gz 

#RUN wget "https://fdsnws.raspberryshakedata.com/fdsnws/station/1/query?starttime="$(date -u +'%Y-%m-%dT%H:%M:%S')"&format=sc3ml&level=response" -O $INSTALL_DIR/etc/inventory/shakenet.xml
RUN wget "https://fdsnws.raspberryshakedata.com/fdsnws/station/1/query?format=sc3ml&level=response" -O $INSTALL_DIR/etc/inventory/shakenet.xml

RUN chown -R sysop:sysop $INSTALL_DIR/

ADD seiscomp.cnf /etc/mysql/conf.d/


RUN /etc/init.d/mysql start && \
    sleep 5 && \
    mysql -u root -e "CREATE DATABASE seiscomp" && \
    mysql -u root -e "CREATE USER 'sysop'@'localhost' IDENTIFIED BY 'sysop'" && \
    mysql -u root -e "GRANT ALL PRIVILEGES ON * . * TO 'sysop'@'localhost'" && \
    mysql -u root -e "FLUSH PRIVILEGES" && \
    mysql -u root seiscomp <  $INSTALL_DIR/share/db/mysql.sql && \
    su sysop -s /bin/bash -c "source /home/sysop/.profile ; seiscomp start && seiscomp update-config"

USER sysop

RUN echo "seiscomp check" >> /home/sysop/.profile
RUN cd /home/sysop && \
    wget "https://github.com/FMassin/SeisComP-World-Shaded-Imagery-and-Geology/archive/refs/tags/v0.2.tar.gz" -O SCPWSIG.tar.gz && \
    tar xzf SCPWSIG.tar.gz && \
    rm SCPWSIG.tar.gz && \
    ln -s /home/sysop/SeisComP-World-Shaded-Imagery-and-Geology*/bna .seiscomp3/bna

## Start sshd
USER root
RUN passwd -d sysop
RUN sed -i'' -e's/^#PermitRootLogin prohibit-password$/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i'' -e's/^#PasswordAuthentication yes$/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i'' -e's/^#PermitEmptyPasswords no$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config \
    && sed -i'' -e's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
EXPOSE 22
CMD ["sh", "-c", "/usr/sbin/sshd -D & mysqld "]
