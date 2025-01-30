package main

/*
Msauth Setup Guide:
1. Setup VM
     VM is fresh installed android-x86 + microsoft authenticator x86_64 apk + no-UEFI, need screen lock before setup msauth apk.
     qemu-system-x86_64 -drive file=/mnt/fsdisk/android-vm/android-msauth-x86-bios-pswd0000.qcow2,if=virtio -cpu host -smp 4 -m 6G --enable-kvm -net nic,model=virtio-net-pci -net user,hostfwd=tcp::25582-:5555 -vnc :18
     Enable "stay awake" in developer options
     Manually start your microsoft authenticator, login, keep it maximized, don't touch it.
2. Build this httpd program with `go build xxx.go`
3. Start httpd daemon and enjoy.
*/

import (
	"fmt"
	"log"
	"net/http"
    "os"
	"os/exec"
	"strings"
)

func writeScript() error {
    // Define the multi-line string
    bashText := `#!/bin/bash
code="$1"
echo "$code" | grep '^[0-9][0-9]$' > /dev/null || ! echo "ERROR: Expect 2 digits input" || exit 1

if adb devices | grep localhost:25582 > /dev/null; then
    :
else
    adb connect localhost:25582
    adb devices | grep localhost:25582 || ! echo "ERROR ADB unable to connect" || exit 1
fi

sleep 1 ## Make sure code arrives
adb shell input text $code
sleep 0.5
adb shell input keyevent KEYCODE_ENTER
adb shell input keyevent KEYCODE_ENTER
adb shell input keyevent KEYCODE_ENTER
echo OK

## Make sure leftovers get cleaned up
nohup bash -c "sleep 5 ; adb shell input keyevent KEYCODE_ENTER ; adb shell input tap 632 408 ; adb shell input keyevent KEYCODE_ENTER ; adb shell input tap 632 408" & disown
`

    file, err := os.OpenFile("/tmp/.msauth-adb-type-code.sh", os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
    if err != nil {
        return fmt.Errorf("failed to open file: %v", err)
    }
    defer file.Close()

    // Write the multi-line string to the file
    _, err = file.WriteString(bashText)
    if err != nil {
        return fmt.Errorf("failed to write to file: %v", err)
    }

    return nil
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	// Extract the number from the request path
	path := r.URL.Path
	numStr := strings.TrimPrefix(path, "/")
	num := strings.TrimSuffix(numStr, "/")

	// Validate if the number is valid
	if num == "" {
		http.Error(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Execute the shell script with the number as an argument
	cmd := exec.Command("bash", "/tmp/.msauth-adb-type-code.sh", num)
	output, err := cmd.CombinedOutput()

	// Write the script output as the HTTP response
	w.Header().Set("Content-Type", "text/plain")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "ScriptRet: %v\n%s", err, output)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s", output)
}

func main() {
    if err := writeScript(); err != nil {
        return
    }

	// Register the handler for incoming HTTP requests
	http.HandleFunc("/", handleRequest)

	// Start the HTTP server on localhost:30410
	port := ":30410"
	fmt.Printf("Starting server on %s\n", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("Server error:", err)
	}
}

