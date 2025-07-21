# docker insecure v2ray

this is insecure version of docker v2ray: much easier to setup, and supports domain spoofing. 

but as you can see: less secure.

to deploy:

```
sudo docker run -d --restart always --log-opt max-size=1M --name rv -p 443:443 recolic/insecure-v2ray
```

to use:

```
vless://11111111-7b5d-44a1-bb69-6e100bc0083f@YOUR_SERVER_IP:443?path=%2Fteams&security=tls&encryption=none&host=anything.example.com&type=ws&sni=www.paypal.com#TEST-SPOOF-PAYPAL
```

