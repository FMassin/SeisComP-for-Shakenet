FROM fredmassin/self-compiling_seiscomp_vanilla

MAINTAINER Fred Massin  <fmassin@sed.ethz.ch>

ENV   REPO_PATH https://github.com/SeisComP
ENV    WORK_DIR /usr/local/src
ENV INSTALL_DIR /opt/seiscomp

# Fix Debian  env
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No
ENV FAKE_CHROOT 1

# Setup sysop's user and group id
ENV USER_ID 1000
ENV GROUP_ID 1000

WORKDIR $WORK_DIR
WORKDIR /home/sysop


RUN apt-get update && \
    apt-get install -y \
        xfce4 \
        xfce4-goodies \
        tightvncserver


COPY etc/*.cfg $INSTALL_DIR/etc/

RUN cd $INSTALL_DIR/../ && \
    wget "https://www.seiscomp.de/downloader/seiscomp-maps.tar.gz" && \
    tar xzf seiscomp-maps.tar.gz && \
    rm seiscomp-maps.tar.gz 

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
    su sysop -s /bin/bash -c "source /home/sysop/.profile ; seiscomp start ; seiscomp update-config"

USER sysop

ADD scrc /home/sysop/
RUN echo "source /home/sysop/scrc" >> /home/sysop/.bashrc
RUN cd /home/sysop && \
    wget "https://github.com/FMassin/SeisComP-World-Shaded-Imagery-and-Geology/archive/refs/tags/v0.2.tar.gz" -O SCPWSIG.tar.gz && \
    tar xzf SCPWSIG.tar.gz && \
    rm SCPWSIG.tar.gz && \
    ln -s /home/sysop/SeisComP-World-Shaded-Imagery-and-Geology*/bna .seiscomp/bna

## Start vncserverd
RUN mkdir /home/sysop/.vnc/ 
ADD xstartup /home/sysop/.vnc/
RUN touch /home/sysop/.Xauthority 
RUN echo "sysop" | vncpasswd -f >> /home/sysop/.vnc/passwd
USER root
RUN chmod 600 /home/sysop/.vnc/passwd
RUN chmod +x /home/sysop/.vnc/xstartup
ADD vncserver /etc/init.d/ 
RUN chmod +x /etc/init.d/vncserver



## Start sshd
RUN passwd -d sysop
RUN sed -i'' -e's/^#PermitRootLogin prohibit-password$/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i'' -e's/^#PasswordAuthentication yes$/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i'' -e's/^#PermitEmptyPasswords no$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config \
    && sed -i'' -e's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
EXPOSE 22
CMD ["sh", "-c", "/usr/sbin/sshd -D & mysqld "]
#CMD bash service vncserver start
