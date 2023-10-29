#!/bin/sh

## setup vserver
prot="v""le""ss"
cat << EOF > /etc/opt/config.json
{
	"log": {"access": "/dev/null","error": "/dev/null","loglevel": "none"},
	"inbounds": [
	{
			"listen": "127.0.0.1",
			"port": 9008,
			"protocol": "$prot",
			"settings": {"clients": [{"id": "$UUID"}],"decryption": "none"},
			"streamSettings": {"network": "ws","wsSettings": {"path": "$WSPATH"}}
	}
	],
	"outbounds": [{"protocol": "freedom"}],
	"dns": {"servers": ["1.1.1.1","8.8.8.8","localhost"]}
}
EOF

## setup nginx
cat << EOF > /etc/nginx/conf.d/default.conf
server {
    listen ${PORT} default_server;
    listen [::]:${PORT} default_server;
    access_log off;
    location / {
        root   /var/www/hls.js;
        index  index.html;
    }
    location ${WSPATH} {
    if (\$http_upgrade != "websocket") {
        return 404;
    }
    proxy_pass http://127.0.0.1:9008;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
  }
}
EOF

## start service
vserver run -c /etc/opt/config.json > /dev/null 2>&1 &
nginx -g "daemon off;"