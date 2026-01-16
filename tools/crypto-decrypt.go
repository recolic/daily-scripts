package main

/* This program is equivalent to the following openssl command:
 * openssl enc -salt -aes-256-cbc -pbkdf2 -iter 300000 -in plain.txt  -out crypto.bin
 * openssl enc -d    -aes-256-cbc -pbkdf2 -iter 300000 -in crypto.bin -out plain.txt
 * It's specially designed for crypto wallet: decrypt a specific file, output to stdout.
 * go mod init test ; go get golang.org/x/crypto/pbkdf2
 * CGO_ENABLED=0 GOOS=linux   GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o decrypt-linux-amd64
 * CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o decrypt-windows-amd64.exe
 * -- by GPT 5.2
 */

import (
	"bufio"
	"crypto/aes"
	"crypto/cipher"
	"crypto/sha256"
	"errors"
	"fmt"
	"os"
	"strings"

	"golang.org/x/crypto/pbkdf2"
)

const (
	iterCount      = 300000
	ciphertextFile = "crypto.bin"
)

func main() {
	fmt.Fprint(os.Stderr, "Execute: openssl enc -d    -aes-256-cbc -pbkdf2 -iter 300000 -in crypto.bin\n")
	fmt.Fprint(os.Stderr, "decrypt crypto.bin...\npassword: ")
	reader := bufio.NewReader(os.Stdin)
	passwordStr, err := reader.ReadString('\n')
	if err != nil {
		panic(err)
	}
	password := []byte(strings.TrimRight(passwordStr, "\r\n"))

	data, err := os.ReadFile(ciphertextFile)
	if err != nil {
		panic(err)
	}

	if len(data) < 16 || string(data[:8]) != "Salted__" {
		panic(errors.New("not OpenSSL salted format"))
	}

	salt := data[8:16]
	ciphertext := data[16:]

	keyIV := pbkdf2.Key(password, salt, iterCount, 32+16, sha256.New)
	key := keyIV[:32]
	iv := keyIV[32:]

	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err)
	}

	if len(ciphertext)%aes.BlockSize != 0 {
		panic(errors.New("invalid ciphertext length"))
	}

	mode := cipher.NewCBCDecrypter(block, iv)
	mode.CryptBlocks(ciphertext, ciphertext)

	// PKCS#7 unpadding
	paddingLen := int(ciphertext[len(ciphertext)-1])
	if paddingLen == 0 || paddingLen > aes.BlockSize {
		panic(errors.New("bad padding"))
	}
	for i := 0; i < paddingLen; i++ {
		if ciphertext[len(ciphertext)-1-i] != byte(paddingLen) {
			panic(errors.New("bad padding"))
		}
	}

	plaintext := ciphertext[:len(ciphertext)-paddingLen]

	os.Stdout.Write(plaintext)
}

