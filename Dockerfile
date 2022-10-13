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
ENV USERDIR /home/sysop


RUN apt-get update && \
    apt-get install -y \
        xfce4 \
        xfce4-goodies \
        tightvncserver


COPY Desktop/ $USERDIR/Desktop/
RUN rm $USERDIR/Desktop/Icon*
COPY etc/ $INSTALL_DIR/etc/
RUN rm $INSTALL_DIR/etc/Icon* \
    $INSTALL_DIR/etc/key/Icon*

RUN cd $INSTALL_DIR/../ && \
    wget "https://www.seiscomp.de/downloader/seiscomp-maps.tar.gz" && \
    tar xzf seiscomp-maps.tar.gz && \
    rm seiscomp-maps.tar.gz 

#RUN wget "https://fdsnws.raspberryshakedata.com/fdsnws/station/1/query?starttime="$(date -u +'%Y-%m-%dT%H:%M:%S')"&format=sc3ml&level=response" -O $INSTALL_DIR/etc/inventory/shakenet.xml
RUN wget "https://fdsnws.raspberryshakedata.com/fdsnws/station/1/query?format=sc3ml&level=response" \
    -O $WORK_DIR/shakenet.xml

# Add basic data
RUN wget  -qO- --no-check-certificate \
    'https://docs.google.com/uc?export=download&id=1IxQ-m4toOmtYKnw90f0ldXy4VRN0uX12' \
    |zcat > $WORK_DIR/basic_metadata.xml
RUN /opt/seiscomp/bin/seiscomp exec invextr \
    --rm --chans "AM.*" \
    $WORK_DIR/basic_metadata.xml > $WORK_DIR/basic_metadata_noshakenet.xml
RUN /opt/seiscomp/bin/seiscomp exec scinv merge \
    $WORK_DIR/shakenet.xml \
    $WORK_DIR/basic_metadata_noshakenet.xml \
    -o $INSTALL_DIR/etc/inventory/inventory.xml

RUN cd $USERDIR && \
    wget "https://github.com/FMassin/SeisComP-World-Shaded-Imagery-and-Geology/archive/refs/tags/v0.2.tar.gz" -O SCPWSIG.tar.gz && \
    tar xzf SCPWSIG.tar.gz && \
    rm SCPWSIG.tar.gz && \
    ln -s $USERDIR/SeisComP-World-Shaded-Imagery-and-Geology*/bna .seiscomp/bna

RUN mkdir -p $INSTALL_DIR/var/run/seedlink &&\
    mkfifo $INSTALL_DIR/var/run/seedlink/mseedfifo

ADD Desktop/* $USERDIR/Desktop/
ADD scrc $USERDIR
RUN echo "source /home/sysop/scrc" >> $USERDIR/.bashrc 

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

ADD MyInv2key.py $WORK_DIR/
RUN echo "deb http://deb.obspy.org buster main" >> /etc/apt/sources.list &&\
    wget --quiet -O - https://raw.githubusercontent.com/obspy/obspy/master/misc/debian/public.key | apt-key add - &&\
    apt-get update && \
    apt-get install -y python-obspy 
#RUN sed 's/0\.1." version="0\.1."/0.9" version="0.9"/' $INSTALL_DIR/etc/inventory/inventory.xml  > $WORK_DIR/4keys.xml &&\
#    python $WORK_DIR/MyInv2key.py $WORK_DIR/4keys.xml \
#        $INSTALL_DIR/ 'seedlink:profile_msrtsimul' &&\
#    /bin/bash -c "source /home/sysop/.profile ; seiscomp start ; seiscomp update-config"

USER sysop

## Start vncserverd
RUN mkdir $USERDIR/.vnc/ 
ADD xstartup $USERDIR/.vnc/
RUN touch $USERDIR/.Xauthority 
RUN echo "sysop" | vncpasswd -f >> $USERDIR/.vnc/passwd
USER root
RUN chmod 600 $USERDIR/.vnc/passwd
RUN chmod +x $USERDIR/.vnc/xstartup
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
