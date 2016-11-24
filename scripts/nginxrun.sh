#!/bin/bash -e

# this script is setup as the entry-point to the nginx container
# it serves anything in /assets from the local file-system
# the Dockerfile.nginx adds /public/assets to /www/assets for this reason
# anything else is proxied back to the rails app
# the rails app host IP is a k8s service
# (we know the IP because k8s injects the env for us)

cat<<end-of-nginx-config > /etc/nginx/nginx.conf
worker_processes 1;
daemon off;
error_log /dev/stdout info;
events { worker_connections 1024; }

http {

    sendfile on;

    include /etc/nginx/mime.types;

    access_log /dev/stdout;

    gzip              on;
    gzip_http_version 1.0;
    gzip_proxied      any;
    gzip_min_length   500;
    gzip_disable      "MSIE [1-6]\.";
    gzip_types        text/plain text/xml text/css
                      text/comma-separated-values
                      text/javascript
                      application/x-javascript
                      application/atom+xml;

    # List of backend servers
    upstream app_servers {
        server ${APP_SERVICE_HOST}:${APP_SERVICE_PORT};
    }

    server {
        client_max_body_size 100M;
        listen 80;

        location ~ ^/(assets)/  {
          root /www;
        }

        location / {

            proxy_pass         http://app_servers;
            proxy_redirect     off;
            proxy_set_header   Host \$host;
            proxy_set_header   X-Real-IP \$remote_addr;
            proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host \$server_name;
            proxy_connect_timeout       600;
            proxy_send_timeout          600;
            proxy_read_timeout          600;
            send_timeout                600;

        }
    }
}
end-of-nginx-config

nginx