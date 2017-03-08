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
