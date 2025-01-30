package main

import (
	"fmt"
	"os"
	"strconv"
)

func main() {
	// Check if there are command-line arguments
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <arguments>")
		return
	}

	// Get the last argument
	lastArg := os.Args[len(os.Args)-1]

	// Extract the last digit from the last argument
	lastDigit, err := strconv.Atoi(string(lastArg[len(lastArg)-1]))
	if err != nil {
		fmt.Println("Error extracting last digit:", err)
		return
	}

	// Print "hello" for n times (n is the last digit number)
	for i := 0; i < lastDigit; i++ {
		fmt.Println("hello")
	}
}
