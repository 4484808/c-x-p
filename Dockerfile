FROM node:latest

# 设置各变量
ARG WSPATH= \
    UUID= \
    NEZHA_SERVER= \
    NEZHA_PORT=45555 \
    NEZHA_KEY= \
   #NEZHA_TLS= \
    WEB_DOMAIN= \
    ARGO_DOMAIN= \
    SSH_DOMAIN= \
    ARGO_AUTH= \
    WEB_USERNAME= \
    WEB_PASSWORD=


# 此处不用改，保留即可
ENV NEZHA_SERVER=$NEZHA_SERVER \
    NEZHA_PORT=$NEZHA_PORT \
    NEZHA_KEY=$NEZHA_KEY \
    SSH_DOMAIN=$SSH_DOMAIN

WORKDIR /home/choreouser

COPY files/* /home/choreouser/

RUN apt-get update &&\
    apt-get install -y iproute2 curl &&\
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&\
    dpkg -i cloudflared.deb &&\
    rm -f cloudflared.deb
RUN UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" &&\
    v4=$(curl -s4m6 ip.sb -k) &&\
    v4l=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'` &&\  
    addgroup --gid 10001 choreo &&\
    if echo "$ARGO_AUTH" | grep -q 'TunnelSecret'; then \
      echo "$ARGO_AUTH" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > tunnel.json; \
      echo "\
tunnel: $(echo "$ARGO_AUTH" | grep -oP "(?<=TunnelID:).*(?=})") \n\
credentials-file: /home/choreouser/tunnel.json \n\
protocol: h2mux \n\
\n\
ingress: \n\
  - hostname: $ARGO_DOMAIN \n\
    service: http://localhost:8080 \n\
  - hostname: $WEB_DOMAIN \n\
    service: http://localhost:3000" > tunnel.yml; \
    
      if [ -n "$SSH_DOMAIN" ]; then \
        echo "\
  - hostname: $SSH_DOMAIN \n\
    service: http://localhost:2222 \n\
    originRequest: \n\
      noTLSVerify: true" >> tunnel.yml; \
      fi; \
      
      echo "\
  - service: http_status:404" >> tunnel.yml; \
    else \
      ARGO_TOKEN=$ARGO_AUTH; \
      sed -i "s#ARGO_TOKEN_CHANGE#$ARGO_TOKEN#g" entrypoint.sh; \
    fi &&\
    echo "******************************************* \n\
V2-rayN: \n\
---------------------------- \n\
vless://${UUID}@[2606:4700::]:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${WSPATH}l?ed=2048#Choreo-Vl-$v4l$v4 \n\
---------------------------- \n\
vmess://$(echo "{ \"v\": \"2\", \"ps\": \"Choreo-VM-$v4l$v4\", \"add\": \"2606:4700::\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }" | base64 -w0) \n\
---------------------------- \n\
trojan://${UUID}@[2606:4700::]:443?security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${WSPATH}t?ed=2048#Choreo-TJ-$v4l$v4 \n\
---------------------------- \n\
ss://$(echo "chacha20-ietf-poly1305:${UUID}@[2606:4700::]:443" | base64 -w0)@[2606:4700::]:443#Choreo-SS-$v4l$v4 \n\
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: ${ARGO_DOMAIN} ，路径: /${WSPATH}s?ed=2048 ， 传输层安全: tls ， sni: ${ARGO_DOMAIN} \n\
******************************************* \n\
小火箭: \n\
---------------------------- \n\
vless://${UUID}@[2606:4700::]:443?encryption=none&security=tls&type=ws&host=${ARGO_DOMAIN}&path=/${WSPATH}l?ed=2048&sni=${ARGO_DOMAIN}#Choreo-Vl-$v4l$v4 \n\
---------------------------- \n\
vmess://$(echo "none:${UUID}@[2606:4700::]:443" | base64 -w0)?remarks=Choreo-VM-$v4l$v4&obfsParam=${ARGO_DOMAIN}&path=/${WSPATH}?ed=2048&obfs=websocket&tls=1&peer=${ARGO_DOMAIN}&alterId=0 \n\
---------------------------- \n\
trojan://${UUID}@[2606:4700::]:443?peer=${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=${ARGO_DOMAIN};obfs-uri=/${WSPATH}j?ed=2048#Choreo-TJ-$v4l$v4 \n\
---------------------------- \n\
ss://$(echo "chacha20-ietf-poly1305:${UUID}@[2606:4700::]:443" | base64 -w0)?obfs=wss&obfsParam=${ARGO_DOMAIN}&path=/${WSPATH}s?ed=2048#Choreo-SS-$v4l$v4 \n\
******************************************* \n\
Clash: \n\
---------------------------- \n\
- {name: Choreo-Vl-$v4l$v4, type: vless, server: 2606:4700::, port: 443, uuid: ${UUID}, tls: true, servername: ${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: {path: /${WSPATH}-vless?ed=2048, headers: { Host: ${ARGO_DOMAIN}}}, udp: true} \n\
---------------------------- \n\
- {name: Choreo-VM-$v4l$v4, type: vmess, server: 2606:4700::, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /${WSPATH}-vmess?ed=2048, headers: {Host: ${ARGO_DOMAIN}}}, udp: true} \n\
---------------------------- \n\
- {name: Choreo-TJ-$v4l$v4, type: trojan, server: 2606:4700::, port: 443, password: ${UUID}, udp: true, tls: true, sni: ${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: { path: /${WSPATH}-trojan?ed=2048, headers: { Host: ${ARGO_DOMAIN} } } } \n\
---------------------------- \n\
- {name: Choreo-SS-$v4l$v4, type: ss, server: [2606:4700::], port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: ${ARGO_DOMAIN}, path: /${WSPATH}-shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } } \n\
******************************************* " > list &&\
    sed -i "s#UUID#$UUID#g; s#WSPATH#$WSPATH#g;" config.json &&\
    TLS=${NEZHA_TLS:+'--tls'} &&\
    sed -i "s#NEZHA_SERVER_CHANGE#$NEZHA_SERVER#g; s#NEZHA_PORT_CHANGE#$NEZHA_PORT#g; s#NEZHA_KEY_CHANGE#$NEZHA_KEY#g; s#TLS_CHANGE#$TLS#g; s#WEB_USERNAME_CHANGE#$WEB_USERNAME#g; s#WEB_PASSWORD_CHANGE#$WEB_PASSWORD#g" entrypoint.sh &&\
    sed -i "s#WEB_USERNAME_CHANGE#$WEB_USERNAME#g; s#WEB_PASSWORD_CHANGE#$WEB_PASSWORD#g; s#WEB_DOMAIN_CHANGE#$WEB_DOMAIN#g" server.js &&\
    adduser --disabled-password  --no-create-home --uid 10001 --ingroup choreo choreouser &&\
    usermod -aG sudo choreouser &&\
    chown -R 10001:10001 web.js entrypoint.sh config.json &&\
    chmod +x web.js entrypoint.sh nezha-agent ttyd &&\
    npm install -r package.json

ENTRYPOINT [ "node", "server.js" ]

USER 10001
