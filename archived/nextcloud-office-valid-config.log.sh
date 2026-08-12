## prod

root@drive-reco /s/n/apps# docker exec -u 33 -ti rdrive ./occ  config:list richdocuments
{
    "apps": {
        "richdocuments": {
            "installed_version": "8.7.7",
            "enabled": "yes",
            "types": "filesystem,prevent_group_restriction",
            "wopi_url": "https:\/\/drive.recolic.cc\/custom_apps\/richdocumentscode\/proxy.php?req=",
            "disable_certificate_verification": "yes",
            "wopi_callback_url": "http:\/\/drive.recolic.cc",
            "public_wopi_url": "https:\/\/drive.recolic.cc"
        }
    }
}
root@drive-reco /s/n/apps# docker exec -u 33 -ti rdrive ./occ richdocuments:activate-config --callback-url  https://drive.recolic.cc
✓ Set callback url to https://drive.recolic.cc
Checking configuration
🛈 Configured WOPI URL: https://drive.recolic.cc/custom_apps/richdocumentscode/proxy.php?req=
🛈 Configured public WOPI URL: https://drive.recolic.cc
🛈 Configured callback URL: https://drive.recolic.cc

✓ Fetched /hosting/discovery endpoint
✓ Valid mimetype response
✓ Valid capabilities entry
✓ Fetched /hosting/capabilities endpoint
✓ Detected WOPI server: Collabora Online Development Edition 25.04.7.2

Collabora URL (used for Nextcloud to contact the Collabora server):
  https://drive.recolic.cc/custom_apps/richdocumentscode/proxy.php?req=
Collabora public URL (used in the browser to open Collabora):
  https://drive.recolic.cc
Callback URL (used by Collabora to connect back to Nextcloud):
  https://drive.recolic.cc

--

## test

docker run -d -p 8080:80 nextcloud

/var/www/html/occ richdocuments:activate-config --callback-url  http://localhost:80
/var/www/html/occ config:app:set --value "http://localhost:80/custom_apps/richdocumentscode/proxy.php?req=" richdocuments wopi_url
/var/www/html/occ config:app:set --value "http://localhost:8080/custom_apps/richdocumentscode/proxy.php?req=" richdocuments public_wopi_url

root@091ac578ea5f:/var/www/html# /var/www/html/occ config:list richdocuments
{
    "apps": {
        "richdocuments": {
            "installed_version": "9.0.2",
            "enabled": "yes",
            "types": "filesystem,prevent_group_restriction",
            "wopi_url": "http:\/\/localhost:80\/custom_apps\/richdocumentscode\/proxy.php?req=",
            "disable_certificate_verification": "yes",
            "wopi_callback_url": "http:\/\/localhost:80",
            "public_wopi_url": "http:\/\/localhost:8080\/custom_apps\/richdocumentscode\/proxy.php?req=",
            "doc_format": "ooxml"
        }
    }
}

# should work but doesn't work. Instead:
# 1. don't modify any config
# 2. just run socat, forward localhost:8080 to localhost:80
