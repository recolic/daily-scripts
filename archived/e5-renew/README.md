# E5 auto-renew

This docker image is not intended for others' deploy. You should modify `e5-renew.py` and `rtoken.txt` as [this article](https://blog.432100.xyz/index.php/archives/50/) says, and re-build the image by yourself.

```
docker build -f Dockerfile -t local/e5 .
docker run -tid --name e5renew --restart=always local/e5
```

https://web.archive.org/web/20200415000558/https://blog.432100.xyz/index.php/archives/50/

## recolic deploy note

startup.sh

```
# M365 E5 renew, require internet
# bgrun /var/log/e5-renew.log /root/e5-renew/e5-renew.py
```


