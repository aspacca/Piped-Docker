echo "Enter an url for the Frontend (eg: https://piped.kavin.rocks):" && read -r frontend_url
echo "Enter an url for the Backend (eg: https://pipedapi.kavin.rocks):" && read -r backend_url
echo "Enter an hostname for the Proxy (eg: https://pipedproxy.kavin.rocks):" && read -r proxy_url
echo "Enter the reverse proxy you would like to use (either caddy or nginx):" && read -r reverseproxy

rm -rf config/
rm -f docker-compose.yml

cp -r template/ config/

frontend_schema=$(echo "$frontend_url"| awk -F[/:] '{print $1}')
backend_schema=$(echo "$backend_url"| awk -F[/:] '{print $1}')
proxy_schema=$(echo "$proxy_url"| awk -F[/:] '{print $1}')

frontend_hostname=$(echo "$frontend_url"| awk -F[/:] '{print $4}')
backend_hostname=$(echo "$backend_url"| awk -F[/:] '{print $4}')
proxy_hostname=$(echo "$proxy_url"| awk -F[/:] '{print $4}')

frontend_port=$(echo "$frontend_url"| awk -F[/:] '{print $5}'| { read -d '' port; [ -z "$port" ] && { [ "$frontend_schema" = "https" ] && echo "443" || echo "80"; } || echo "$port"; })
backend_port=$(echo "$backend_url"| awk -F[/:] '{print $5}'| { read -d '' port; [ -z "$port" ] && { [ "$backend_schema" = "https" ] && echo "443" || echo "80"; } || echo "$port"; })
proxy_port=$(echo "$proxy_url"| awk -F[/:] '{print $5}'| { read -d '' port; [ -z "$port" ] && { [ "$proxy_schema" = "https" ] && echo "443" || echo "80"; } || echo "$port"; })

nginx_ports=$(printf "$frontend_port\n$backend_port\n$proxy_port\n"|uniq|while read -r port; do printf "            - \"$port:$port\"\\\n"; done)

case $OSTYPE in
    darwin*)
      function ased(){
        sed -i '' "$@"
      }
      ;;
    freebsd*)
      function ased(){
        sed -i '' "$@"
      }
      ;;
    linux*)
      function ased(){
        sed -i "$@"
      }
      ;;
esac

ased "s@FRONT_URL@$frontend_url@g" config/*
ased "s@BACKEND_URL@$backend_url@g" config/*
ased "s@PROXY_URL@$proxy_url@g" config/*

ased "s@FRONTEND_HOSTNAME@$frontend_hostname@g" config/*
ased "s@BACKEND_HOSTNAME@$backend_hostname@g" config/*
ased "s@PROXY_HOSTNAME@$proxy_hostname@g" config/*

ased "s@FRONTEND_PORT@$frontend_port@g" config/*
ased "s@BACKEND_PORT@$backend_port@g" config/*
ased "s@PROXY_PORT@$proxy_port@g" config/*

ased "s@NGINX_PORTS@$nginx_ports@g" config/*

# The openj9 image does not support aarch64
if [[ "$(uname -m)" == "aarch64" ]]; then
    ased "s/piped:latest/piped:hotspot/g" config/*
fi

mv config/docker-compose.$reverseproxy.yml docker-compose.yml
