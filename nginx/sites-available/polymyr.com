server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /home/jasper/polymyr;
    index index.php;

    server_name polymyr.com www.polymyr.com;
    charset utf-8

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