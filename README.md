# dynamic-proxy
Throw a host header at it and it will proxy to it!
* Implements retries, keepalives (idle/persistent connection pooling) and load balancing when your client can't!
* Optimised nginx Openresty config for speed and high traffic. https://github.com/openresty/docker-openresty
* Dynamic connection pooling to any domain using lookups performed by Kong lua-resty-dns-client https://github.com/Kong/lua-resty-dns-client
** resolves A, AAAA, CNAME and SRV records, including port
** parses /etc/hosts
** parses /resolv.conf and applies LOCALDOMAIN and RES_OPTIONS variables
** caches dns query results in memory
** synchronizes requests (a single request for many requestors, eg. when cached ttl expires under heavy load)
* Supports self-signed SSL using iteration on the-one-cert https://github.com/flotwig/the-one-cert
* Above point allows ALPN, HTTP2 and TLS1.3 from local box or wherever you trust the certificate.

# Build and run
`docker build -t dynamic-proxy . && docker run -p 8080:80 -p 8443:443 dynamic-proxy`

# simple 
client -- plaintext http -- proxy -- https -- intended site

```
$ curl -I -H "Host: httpbin.org" http://127.0.0.1:8080/status/418
HTTP/1.1 418 I'M A TEAPOT
Server: openresty
Date: Thu, 22 Jul 2021 02:57:16 GMT
Content-Length: 135
Connection: keep-alive
x-more-info: http://tools.ietf.org/html/rfc2324
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
```

# secure
client -- https -- proxy -- https -- intended site
ensure your client trusts certs/one-cert.crt

```
$ curl -I https://httpbin.org:8443/status/418 --cacert one-cert.crt --resolve 'httpbin.org:8443:127.0.0.1'
HTTP/2 418 
server: openresty
date: Thu, 22 Jul 2021 02:58:32 GMT
content-length: 135
x-more-info: http://tools.ietf.org/html/rfc2324
access-control-allow-origin: *
access-control-allow-credentials: true
```

# adding more domains for secure mode
Just add the domains to the bottom of certs/openssl.cnf
then run ./run-openssl.sh
and rebuild the container

# more ideas on how to proxy generically for SSL
1. Replace dots with _ (underscores) in the client and prefix to a wildcard DNS domain which you have a real certificate for e.g. *.dynamic-proxy.com
e.g. httpbin_org.dynamic-proxy.com
Just have a *.dynamic-proxy.com cert on the box. Or a domain with a REAL trusted certificate from a real CA!!!
Then in nginx capture the bit with underscores, replace the underscores with dots and use that as the host header and sni for the backend connection
Have a wildcard dns record that takes *.dynamic-proxy.com to the dynamic-alive proxy container (probably 127.0.0.1)

# more ideas
1. You could probably pass in the upstream server port and SSL/TLS requirement as headers you can capture in lua.

# Links and thanks

https://luarocks.org/modules/kong/lua-resty-dns-client
https://github.com/Kong/lua-resty-dns-client
http://kong.github.io/lua-resty-dns-client/modules/resty.dns.client.html#resolve
https://kura.gg/2020/08/30/configuring-upstreams-dynamically-with-dns-in-openresty/

# showing that keepalives are used
 `while true; do curl -I -H "Host: httpbin.org" http://127.0.0.1:8080/status/418; done`

 `upstream_connect_time` 0.0 shows that keepalive is being hit.
```
{ "timestamp": "2021-07-22T03:03:45+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.881, "upstream_connect_time": 0.661, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "52.201.75.114:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:45 [info] 9#9: *44 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:46+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.221, "upstream_connect_time": 0.000, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "52.201.75.114:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:46 [info] 8#8: *48 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:46+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.227, "upstream_connect_time": 0.000, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "18.235.124.214:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:46 [info] 12#12: *51 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:46+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.234, "upstream_connect_time": 0.000, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "18.235.124.214:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:46 [info] 7#7: *54 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:46+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.224, "upstream_connect_time": 0.000, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "18.235.124.214:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:46 [info] 11#11: *57 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:47+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.225, "upstream_connect_time": 0.000, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "18.235.124.214:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:47 [info] 8#8: *60 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:47+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.223, "upstream_connect_time": 0.000, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "52.201.75.114:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
2021/07/22 03:03:47 [info] 8#8: *63 client 172.17.0.1 closed keepalive connection
{ "timestamp": "2021-07-22T03:03:48+00:00", "remote_addr": "172.17.0.1", "body_bytes_sent": 0, "request_time": 0.886, "upstream_connect_time": 0.659, "response_status": 418, "request": "HEAD /status/418 HTTP/1.1", "request_method": "HEAD", "host": "httpbin.org","upstream_addr": "52.201.75.114:443","http_x_forwarded_for": "","http_referrer": "", "http_user_agent": "curl/7.77.0", "http_version": "HTTP/1.1", "nginx_access": true }
```

