# docker secure v2ray

this is secure version of docker v2ray, with real TLS cert & random secret: harder to setup, not allowing domain spoofing, but more secure. 

note: this script has built-in washcrack.

- to deploy

```
sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 -e DOMAIN=cheap.my-domain.com -e SECRET_UUID=ec0cba37-926d-4386-b8c1-0a71c06bcebd recolic/secure-v2ray
sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 -e DOMAIN=cheap.my-domain.com -e SECRET_UUID=ec0cba37-926d-4386-b8c1-0a71c06bcebd -e PROXY_PASS=https://azure.microsoft.com/zh-cn recolic/secure-v2ray
```

- to use

```
vless://ec0cba37-926d-4386-b8c1-0a71c06bcebd@cheap.my-domain.com:443?path=%2Fteams&security=tls&encryption=none&host=cheap.my-domain.com&type=ws&sni=cheap.my-domain.com#TEST_V2RAY
```
