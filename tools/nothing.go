// build: GOOS=windows GOARCH=amd64 go build -o nothing.exe nothing.go
package main

import "fmt"
import "time"

func main() { fmt.Println("sleeping forever..."); for { time.Sleep(24 * time.Hour) } }
