function rgpg-encrypt-short
    openssl enc -aes-256-ctr -pbkdf2 -pass pass:(genpasswd rgpg-encrypt-short) | base64 -w0
    #-nosalt 
end
