echo '-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAyo+hnwRt7lTDzL0P7zmMKVdzPtkkS5LRU/zbslTxPKDD1dV+
x
x
x
x
x
x
xxxxxxxxxxxxx
O3E+YgSLONTxgTRRs3Yj7wUmg3hAyYpUeoON4AwBceGGGnlz0gyg8iEK8cMlHIJp
RfNGwRwF7IDpQgTYcOxRc+ODgKDzymnbTQbp2/5I5qNdKq05P/4=
-----END RSA PRIVATE KEY-----
' > ./sk-key &&
chmod go-rwx ./sk-key &&
ssh-add ./sk-key &&
git clone git@github.com:xxxxxxxxxxxxxxx.git &&
cd xxxxx && git log

cd -

echo '-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAwk4yn8iiSkHIv7skVWvpXS/F04EFl6hLeKP2gcG/yquRvEnr
x
x
x
x
x
x
xxxxxxxxxxxxx
IeziryTytFWvlp4UpJRtTaCH5vwzGw7zNyzyTN1KtGdSwXpYVnbo
-----END RSA PRIVATE KEY-----
' > ./sk-win-key &&
chmod go-rwx ./sk-win-key &&
ssh-add ./sk-win-key &&
git clone git@github.com:recolic/xxxxxxxxxxxxxxxx.git &&
cd xxxxxxxxxxxxxxx && git log
