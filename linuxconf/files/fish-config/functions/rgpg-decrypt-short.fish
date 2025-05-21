function rgpg-decrypt-short
    base64 -d | openssl enc -d -aes-256-ctr -pbkdf2 -pass pass:(genpasswd rgpg-encrypt-short)
    # -nosalt
end
