FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install wget net-tools build-essential flex bison libtool automake gcc libnet1 libnet1-dev libpcre3 \
libpcre3-dev autoconf libcrypt-ssleay-perl libwww-perl git zlib1g zlib1g-dev libssl-dev libmysqlclient-dev imagemagick \
libyaml-dev libxml2-dev libxslt1-dev openssl libreadline6-dev unzip libcurl4-openssl-dev libapr1-dev libaprutil1-dev \
supervisor gettext-base libdumbnet-dev libpcap-dev python-pip libpcap-dev libdnet libdumbnet-dev luajit wkhtmltopdf \
apt-utils -y

RUN cd /tmp
    && wget https://www.snort.org/downloads/snort/daq-2.0.7.tar.gz \
    && wget https://www.snort.org/downloads/snort/snort-2.9.17.tar.gz \
    && tar xvzf daq-2.0.7.tar.gz \
    && cd daq-2.0.7 \
    && ./configure && make && make install \
    && ldconfig \
    && cd .. \
    && tar xvzf snort-2.9.17.tar.gz \
    && cd snort-2.9.17 \
    && ./configure --enable-sourcefire --disable-open-appid && make && make install

RUN groupadd snort \
    && useradd snort -d /var/log/snort -s /sbin/nologin -c SNORT_IDS -g snort \
    && mkdir -p /var/log/snort \
    && chown snort:snort /var/log/snort -R \
    && mkdir -p /etc/snort \
    && cd /tmp/snort-2.9.17 \
    && cp -r etc/* /etc/snort/

RUN cd /etc/snort \
    && chown -R snort:snort * \
    && mkdir -p /usr/local/lib/snort_dynamicrules \
    && mkdir /etc/snort/rules \
    && touch /etc/snort/rules/so_rules.rules \
    && touch /etc/snort/rules/local.rules \
    && touch /etc/snort/rules/snort.rules \
    && mkdir /etc/snort/rules/iplists \
    && touch /etc/snort/rules/iplists/white_list.rules \
    && touch /etc/snort/rules/iplists/black_list.rules \
    && sed -i \
      -e 's#^var RULE_PATH.*#var RULE_PATH /etc/snort/rules#' \
      -e 's#^var SO_RULE_PATH.*#var SO_RULE_PATH $RULE_PATH/so_rules#' \
      -e 's#^var PREPROC_RULE_PATH.*#var PREPROC_RULE_PATH $RULE_PATH/preproc_rules#' \
      -e 's#^var WHITE_LIST_PATH.*#var WHITE_LIST_PATH $RULE_PATH/iplists#' \
      -e 's#^var BLACK_LIST_PATH.*#var BLACK_LIST_PATH $RULE_PATH/iplists#' \
      -e 's/^\(include $.*\)/# \1/' \
      -e '$a\\ninclude $RULE_PATH/local.rules' \
      -e '$a\\ninclude $RULE_PATH/snort.rules' \
      -e 's!^# \(config logdir:\)!\1 /var/log/snort!' \
      /etc/snort/snort.conf
