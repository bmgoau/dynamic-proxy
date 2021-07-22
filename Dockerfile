FROM openresty/openresty:1.19.3.2-2-bionic
RUN apt-get update && apt-get install git -y && luarocks install lua-resty-dns-client
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.ssh/id_rsa* && \
    apt-get -y purge lib*-dev && \
    apt-get -y remove --auto-remove locales build-essential && \
    apt-get clean
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY lua/ /etc/nginx/lua/
COPY certs/ /etc/nginx/certs/