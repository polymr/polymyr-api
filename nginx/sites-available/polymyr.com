
# Redirect all HTTP trafic to HTTPS

server {
    listen 80;
    listen [::]:80;

    server_name polymyr.com www.polymyr.com api.polymyr.com www.api.polymyr.com static.polymyr.com www.static.polymyr.com;

    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /tmp/letsencrypt-auto/;
    }

    location = /.well-known/acme-challenge/ {
        return 404;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {

    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    include snippets/ssl-polymyr.com.conf;
    include snippets/ssl-params.conf;

    server_name polymyr.com www.polymyr.com;

    root /home/jasper/polymyr;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    include snippets/ssl-api.polymyr.com.conf;
    include snippets/ssl-params.conf;

    root /home/hakon/polymyr/polymyr-dev-api/;

    server_name api.polymyr.com www.api.polymyr.com;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8080;
    }
}

proxy_cache_path /data/nginx/cache levels=1:2 keys_zone=static:10m inactive=60m use_temp_path=off max_size=4g;

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    include snippets/ssl-api.polymyr.com.conf;
    include snippets/ssl-params.conf;

    root /home/hakon/polymyr/polymyr-dev-api/Public;

    server_name static.polymyr.com www.static.polymyr.com;

    location / {
        include h5bp/basic.conf;

        tcp_nodelay on;
        keepalive_timeout 65;
        sendfile on;
        tcp_nopush on;
        sendfile_max_chunk 1m;

        proxy_cache static;
        try_files $uri =404;
    }
}