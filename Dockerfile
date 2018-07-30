# Start from Debian Stretch
FROM debian:stretch
MAINTAINER Clément OUDOT
LABEL name="llng-apache2" \
      version="v0.0.1"

# Change SSO DOMAIN here
ENV SSODOMAIN=example.com \
    DUMBINITVERSION=1.2.0 \
    DEBIAN_FRONTEND=noninteractive

EXPOSE 80 443

COPY docker-entrypoint.sh /


# Update system
RUN apt -y update \
    && apt -y upgrade \
    && apt -y install wget apache2 libapache2-mod-perl2 libapache2-mod-fcgid \
        libapache-session-perl libnet-ldap-perl libcache-cache-perl \
        libdbi-perl perl-modules libwww-perl libcache-cache-perl \
        libxml-simple-perl  libsoap-lite-perl libhtml-template-perl \
        libregexp-assemble-perl libjs-jquery libxml-libxml-perl \
        libcrypt-rijndael-perl libio-string-perl libxml-libxslt-perl \
        libconfig-inifiles-perl libjson-perl libstring-random-perl \
        libemail-date-format-perl libmime-lite-perl libcrypt-openssl-rsa-perl \
        libdigest-hmac-perl libclone-perl libauthen-sasl-perl \
        libnet-cidr-lite-perl libcrypt-openssl-x509-perl libauthcas-perl \
        libtest-pod-perl libtest-mockobject-perl libauthen-captcha-perl \
        libnet-openid-consumer-perl libnet-openid-server-perl \
        libunicode-string-perl libconvert-pem-perl libmouse-perl libplack-perl \
        libglib-perl liblasso-perl yui-compressor dh-systemd libdbd-sqlite3-perl \
        libemail-sender-perl libgd-securityimage-perl libimage-magick-perl \
	libconvert-base32-perl libregexp-common-perl

RUN apt-get -y install vim \
    && apt-get -y install git make devscripts 

RUN cd /root \
    && git clone https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng.git


RUN cd /root/lemonldap-ng \
    && (make debian-install-for-apache || true )
    
RUN sed -i "s/example\.com/${SSODOMAIN}/g" /etc/lemonldap-ng/*  /var/lib/lemonldap-ng/test/index.pl \
    && echo "/var/lib/lemonldap-ng/conf/lmConf-1.js" \
    && sed -i "s/logLevel\s*=\s*warn/logLevel = debug/" /etc/lemonldap-ng/lemonldap-ng.ini \
    && sed -i "s/LogLevel warn/LogLevel debug/" /etc/apache2/apache2.conf

RUN a2ensite handler-apache2.conf portal-apache2.conf manager-apache2.conf test-apache2.conf \
    && a2enmod fcgid perl alias rewrite \
    && rm -rf /tmp/lemonldap-ng-config \
    && rm -fr /var/lib/apt/lists/*

RUN echo "# Install Dumb-init" \
    && wget https://github.com/Yelp/dumb-init/releases/download/v${DUMBINITVERSION}/dumb-init_${DUMBINITVERSION}_amd64.deb \
    && dpkg -i dumb-init_${DUMBINITVERSION}_amd64.deb

    
VOLUME /var/lib/lemonldap-ng/conf

ENTRYPOINT ["dumb-init","--","/docker-entrypoint.sh"]
CMD "/usr/sbin/apache2ctl" "-D" "FOREGROUND"
