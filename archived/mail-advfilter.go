
/*
GPT 5.5
build:
  go build -o advfilter.gi mail-advfilter.go
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o advfilter.gi mail-advfilter.go
usage:
  prefix=/path/to/Maildir
  WATCH_DIR=$prefix/new:$prefix/.bankstatement/new ./advfilter
*/

package main

import (
	"bytes"
	"io"
	"log"
	"mime"
	"net/mail"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"unsafe"
	"encoding/base64"
	"net/http"
	"net/url"
)

func appendFile(path, body string) {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		log.Printf("open %s: %v", path, err)
		return
	}
	defer f.Close()

	if _, err := f.WriteString(body + "\n\n"); err != nil {
		log.Printf("write %s: %v", path, err)
	}
}

func on_new_email(dir, subject, body string) {
	log.Printf("dir=%s subject=%q body_len=%d", dir, subject, len(body))

	http.Get("https://recolic.net/api/telegram-notify.php?b64Content=" + url.QueryEscape(base64.StdEncoding.EncodeToString([]byte("New Mail:<br />" + subject))))

	switch {
	case subject == "Your credit card statement is available":
		appendFile("/tmp/boa.log", body)
	case subject == "Your Venture X Card statement is ready":
		appendFile("/tmp/c1.log", body)
	case strings.HasPrefix(subject, "Your statement for credit card account"):
		appendFile("/tmp/wf.log", body)
	case strings.HasPrefix(subject, "Your automatic payment is scheduled for"):
		appendFile("/tmp/bilt.log", body)
	}

	// BOA Junk: "Your credit card statement is available"
	// C1  Junk: "Your Venture X Card statement is ready"
	// WF Inbox: "Your statement for credit card account ...1111"
	// BltInbox: "Your automatic payment is scheduled for .*"
}

func load_email(path string) (string, string) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", ""
	}

	msg, err := mail.ReadMessage(bytes.NewReader(data))
	if err != nil {
		return "", string(data)
	}

	subj := msg.Header.Get("Subject")
	if s, err := new(mime.WordDecoder).DecodeHeader(subj); err == nil {
		subj = s
	}

	b, _ := io.ReadAll(msg.Body)
	return subj, string(b)
}

func main() {
	dirs := strings.Split(os.Getenv("WATCH_DIR"), ":")

	fd, err := syscall.InotifyInit()
	if err != nil {
		log.Fatal(err)
	}

	m := map[int]string{}
	for _, d := range dirs {
		wd, err := syscall.InotifyAddWatch(fd, d, syscall.IN_MOVED_TO)
		if err != nil {
			log.Fatal(err)
		}
		m[wd] = d
	}

	buf := make([]byte, 65536)
	for {
		n, _ := syscall.Read(fd, buf)
		for i := 0; i < n; {
			ev := (*syscall.InotifyEvent)(unsafe.Pointer(&buf[i]))
			nameStart := i + syscall.SizeofInotifyEvent
			nameEnd := nameStart + int(ev.Len)
			name := strings.TrimRight(string(buf[nameStart:nameEnd]), "\x00")

			if name != "" && ev.Mask&syscall.IN_MOVED_TO != 0 {
				dir := m[int(ev.Wd)]
				subj, body := load_email(filepath.Join(dir, name))
				on_new_email(dir, subj, body)
			}
			i = nameEnd
		}
	}
}
