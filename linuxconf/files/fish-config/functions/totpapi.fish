function totpapi
if test -n "$argv[1]"
curl -X POST https://recolic.net/res/river/rauth/secdump.php --data $argv[1]
else
echo "Usage: totpapi (rsec TOTP_CARD_SEED_*)"
end
end
