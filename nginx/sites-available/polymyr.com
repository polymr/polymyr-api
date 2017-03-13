proxy_cache_path /data/nginx/cache levels=1:2 keys_zone=static:10m inactive=60m use_temp_path=off max_size=4g;

server {
    listen 80;
    listen [::]:80;

    root /home/jasper/polymyr;
    index index.php;

    server_name polymyr.com www.polymyr.com;
    charset utf-8;

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
    listen 80;
    listen [::]:80;

    server_name api.polymyr.com www.api.polymyr.com;
    charset utf-8;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8080;
    }
}

server {
    listen 80;
    listen [::]:80;

    root /home/hakon/polymyr/polymyr-dev-api/Public/;

    server_name static.polymyr.me www.static.polymyr.me;
    charset utf-8;

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