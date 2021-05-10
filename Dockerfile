FROM ubuntu:20.04
MAINTAINER Phil Kulin <schors@gmail.com>

ENV NAGIOS_VOLUME          /usr/local/vnagios
ENV NAGIOS_HOME            /usr/local/nagios
ENV NAGIOS_USER            nagios
ENV NAGIOS_UID             800
ENV NAGIOS_GROUP           nagios
ENV NAGIOS_GID             800
#ENV NAGIOSADMIN_USER       nagiosadmin
#ENV NAGIOSADMIN_PASS       nagios
ENV APACHE_RUN_USER        nagios
ENV APACHE_RUN_GROUP       nagios
ENV NAGIOS_TIMEZONE        UTC
ENV DEBIAN_FRONTEND        noninteractive
ENV NAGIOS_BRANCH          nagios-4.4.6
ENV NAGIOS_PLUGINS_BRANCH  release-2.3.3
ENV NRPE_BRANCH            nrpe-4.0.3

RUN apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y                                  && \
        apt-get install -y  --no-install-recommends     \ 
                ca-certificates                         \
                build-essential                         \
                iputils-ping                            \
                dnsutils                                \
                fping                                   \
                git                                     \
                smbclient                               \
                snmp                                    \
                snmpd                                   \
                snmp-mibs-downloader                    \
                unzip                                   \
                mailutils                               \
                libfreetype6-dev                        \
                libpng-dev                              \
                libgd-dev                               \
                libgd-tools                             \
                python3                                 \
                librrd-dev                              \
                libboost-all-dev                        \
                msmtp-mta                               \
                wget                                    \   
                autoconf                                \  
                automake                                \   
                libwww-perl                             \
                libnagios-object-perl                   \
                libnet-snmp-perl                        \
                libnet-snmp-perl                        \
                libnet-tftp-perl                        \
                libnet-xmpp-perl                        \
                libssl-dev                              \
                netcat                                                                                  && \
        groupadd --system -g $NAGIOS_GID $NAGIOS_GROUP                                                  && \
        useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER                               && \
        cd /tmp                                                                                         && \
        git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH                 && \
        cd nagioscore                                                                                   && \
        ./configure                                     \
                --prefix=${NAGIOS_VOLUME}               \
                --exec-prefix=${NAGIOS_HOME}            \
                --datarootdir=${NAGIOS_HOME}/share      \
                --with-httpd_conf=/etc/apache2/conf.d   \
                --with-cgibindir=${NAGIOS_HOME}/sbin    \
                --enable-event-broker                   \
                --with-gd-lib=/usr                      \
                --with-gd-inc=/usr                      \
                --with-command-user=${NAGIOS_USER}      \
                --with-command-group=${NAGIOS_GROUP}    \
                --with-nagios-user=${NAGIOS_USER}       \
                --with-nagios-group=${NAGIOS_GROUP}                                                     && \
        mkdir -p /etc/apache2/conf.d                                                                    && \
        make all                                                                                        && \
        make install                                                                                    && \
        make install-config                                                                             && \
        make install-commandmode                                                                        && \
#       make install-webconf                                                                             && \
        make clean                                                                                      && \
        cd /tmp && rm -Rf nagioscore                                                                    && \
        cd /tmp                                                                                         && \
        git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH        && \
        cd nagios-plugins                                                                               && \
        ./tools/setup                                                                                   && \
        ./configure                                                     \
                --prefix=${NAGIOS_HOME}                                 \
                --with-ipv6                                             \
                --with-ping6-command="/bin/ping6 -n -U -W %d -c %d %s"                                  && \
        make                                                                                            && \
        make install                                                                                    && \
        make clean                                                                                      && \
        mkdir -p /usr/lib/nagios/plugins                                                                && \
        ln -sf ${NAGIOS_HOME}/libexec/utils.pm /usr/lib/nagios/plugins                                  && \
        cd /tmp && rm -Rf nagios-plugins                                                                && \
        cd /tmp                                                                                         && \
        git clone https://github.com/NagiosEnterprises/nrpe.git -b $NRPE_BRANCH                         && \
        cd nrpe                                                                                         && \
        ./configure                                             \
                --with-ssl=/usr/bin/openssl                     \
                --with-ssl-lib=/usr/lib/x86_64-linux-gnu                                                && \
        make check_nrpe                                                                                 && \
        cp src/check_nrpe ${NAGIOS_HOME}/libexec/                                                       && \
        make clean                                                                                      && \
        cd /tmp && rm -Rf nrpe
        apt-get install -y  --no-install-recommends librrd-dev libboost-all-dev                         && \
        cd /tmp                                                                                         && \
        wget https://download.checkmk.com/checkmk/1.5.0p24/mk-livestatus-1.5.0p24.tar.gz  \
                -O mk-livestatus.tar.gz                                                                 && \
        tar -zxpf mk-livestatus.tar.gz                                                                  && \
        cd mk-livestatus-1.5.0p24                                                                       && \
        ./configure --with-nagios4 --prefix=/usr/local/nagios                                           && \
        make install                                                                                    && \
        make clean                                                                                      && \
        cd /tmp && rm -Rf mk-livestatus-1.5.0p24


VOLUME "${NAGIOS_HOME}/var" "${NAGIOS_HOME}/etc" "/tmp"

COPY etc/msmtprc /etc/msmtprc

ENTRYPOINT ["/usr/local/nagios/bin/nagios", "/usr/local/vnagios/etc/nagios.cfg"]


