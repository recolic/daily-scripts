// Usage: GOOS=linux GOARCH=arm64 go build naive-shell.go
// ./naive-shell --port 30405 --token abc
// curl -X POST -H "token: abc" --data 'echo "Hello from bash!"' http://localhost:30405/
package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
)

func main() {
	port := flag.Int("port", 8080, "Port to listen on")
	token := flag.String("token", "", "Token for authentication")
	flag.Parse()

	if *token == "" {
		fmt.Println("Token is required")
		os.Exit(1)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Only POST allowed", http.StatusMethodNotAllowed)
			return
		}
		if r.Header.Get("token") != *token {
			http.Error(w, "Forbidden", http.StatusForbidden)
			return
		}

		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}
		defer r.Body.Close()

		// create temp file
		tmpFile, err := os.CreateTemp("/tmp", "naive-shell-*.sh")
		if err != nil {
			http.Error(w, "Server error", http.StatusInternalServerError)
			return
		}
		defer os.Remove(tmpFile.Name())
		tmpFile.Write(body)
		tmpFile.Chmod(0755)
		tmpFile.Close()

		cmd := exec.Command("/bin/bash", tmpFile.Name())
		output, err := cmd.CombinedOutput()
		if err != nil {
			// still return output and error
			w.WriteHeader(http.StatusOK)
			w.Write(output)
			w.Write([]byte("\nError: " + err.Error()))
			return
		}

		w.Write(output)
	})

	addr := fmt.Sprintf(":%d", *port)
	fmt.Println("Listening on", addr)
	http.ListenAndServe(addr, nil)
}

