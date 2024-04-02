package main

import (
	"fmt"
	"os"
)

func main() {
	// Open the file for writing
	file, err := os.Create("output.txt")
	if err != nil {
		fmt.Println("Error creating file:", err)
		return
	}
	defer file.Close()

	// Print arguments to the file
	for i, arg := range os.Args {
		_, err := file.WriteString(fmt.Sprintf("Argument %d: %s\n", i, arg))
		if err != nil {
			fmt.Println("Error writing to file:", err)
			return
		}
	}

	fmt.Println("Arguments written to output.txt")
}

