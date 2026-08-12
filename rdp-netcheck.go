// rdp-netcheck measures the network properties that most affect RDP: UDP
// round-trip time, jitter, packet loss/reordering, and bidirectional payload rate.
// It has no dependencies beyond the Go standard library.
//
// Windows RDP host:
//   go run rdp-netcheck.go -mode server -listen :5001
// Linux RDP client:
//   go run rdp-netcheck.go -mode client -server WINDOWS_IP:5001
//
// For a heavier path/load check, for example:
//   go run rdp-netcheck.go -mode client -server WINDOWS_IP:5001 -duration 60s -pps 500 -size 1200
// This sends roughly 4.8 Mbit/s in each direction (payload only). Do not set a
// rate near the connection's capacity: that tests bufferbloat/congestion rather
// than normal RDP usability.
//go build -o ~/tmp/rdp-netcheck-linux ./rdp-netcheck.go
//GOOS=windows GOARCH=amd64 go build -o rdp-netcheck.exe ./rdp-netcheck.go
package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"math"
	"net"
	"os"
	"sort"
	"sync/atomic"
	"time"
)

const (
	magic      uint32 = 0x5244504e // "RDPN"
	headerSize        = 16
)

type packetResult struct {
	seq uint64
	at  time.Time
}

func main() {
	mode := flag.String("mode", "", "server or client")
	listen := flag.String("listen", ":5001", "UDP address on which the server listens")
	server := flag.String("server", "", "UDP server address for client mode, for example 192.0.2.10:5001")
	duration := flag.Duration("duration", 20*time.Second, "client test duration")
	pps := flag.Int("pps", 100, "packets per second sent by the client")
	size := flag.Int("size", 1200, "UDP payload size in bytes, including the 16-byte header")
	flag.Parse()

	switch *mode {
	case "server":
		runServer(*listen)
	case "client":
		if *server == "" || *duration <= 0 || *pps <= 0 || *size < headerSize || *size > 65507 {
			fmt.Fprintln(os.Stderr, "client requires -server; -duration and -pps must be positive; -size must be 16..65507")
			os.Exit(2)
		}
		runClient(*server, *duration, *pps, *size)
	default:
		fmt.Fprintln(os.Stderr, "use -mode server or -mode client")
		flag.PrintDefaults()
		os.Exit(2)
	}
}

func runServer(listen string) {
	addr, err := net.ResolveUDPAddr("udp", listen)
	check(err)
	conn, err := net.ListenUDP("udp", addr)
	check(err)
	defer conn.Close()

	fmt.Printf("RDP netcheck UDP echo server listening on %s\n", conn.LocalAddr())
	fmt.Println("Allow inbound UDP on this port in Windows Firewall if the client is remote.")
	buf := make([]byte, 65535)
	for {
		n, peer, err := conn.ReadFromUDP(buf)
		if err != nil {
			fmt.Fprintln(os.Stderr, "read:", err)
			return
		}
		if n < headerSize || binary.BigEndian.Uint32(buf[:4]) != magic {
			continue
		}
		if _, err := conn.WriteToUDP(buf[:n], peer); err != nil {
			fmt.Fprintln(os.Stderr, "write:", err)
		}
	}
}

func runClient(server string, duration time.Duration, pps, size int) {
	remote, err := net.ResolveUDPAddr("udp", server)
	check(err)
	conn, err := net.DialUDP("udp", nil, remote)
	check(err)
	defer conn.Close()

	fmt.Printf("Testing %s for %s: %d packets/s, %d-byte payload (%0.2f Mbit/s each direction)\n",
		remote, duration, pps, size, float64(pps*size*8)/1_000_000)

	// There is one result slot per transmitted packet. A separate reader lets
	// sending continue even if the reverse path is briefly congested.
	results := make(chan packetResult, 4096)
	var readErr atomic.Value
	go func() {
		buf := make([]byte, 65535)
		for {
			n, err := conn.Read(buf)
			if err != nil {
				if ne, ok := err.(net.Error); ok && ne.Timeout() {
					continue
				}
				readErr.Store(err)
				return
			}
			if n >= headerSize && binary.BigEndian.Uint32(buf[:4]) == magic {
				results <- packetResult{seq: binary.BigEndian.Uint64(buf[8:16]), at: time.Now()}
			}
		}
	}()

	interval := time.Second / time.Duration(pps)
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	started := time.Now()
	deadline := started.Add(duration)
	sentAt := make([]time.Time, 0, int(math.Ceil(duration.Seconds()*float64(pps)))+1)
	rtts := make([]time.Duration, 0, cap(sentAt))
	received := make([]bool, 0, cap(sentAt))
	lastSeq := uint64(0)
	reordered := 0

	record := func(r packetResult) {
		if r.seq >= uint64(len(sentAt)) || received[r.seq] {
			return
		}
		received[r.seq] = true
		rtts = append(rtts, r.at.Sub(sentAt[r.seq]))
		if len(rtts) > 1 && r.seq < lastSeq {
			reordered++
		}
		lastSeq = r.seq
	}

	var seq uint64
	for time.Now().Before(deadline) {
		select {
		case r := <-results:
			record(r)
		case <-ticker.C:
			packet := make([]byte, size)
			binary.BigEndian.PutUint32(packet[:4], magic)
			binary.BigEndian.PutUint64(packet[8:16], seq)
			sentAt = append(sentAt, time.Now())
			received = append(received, false)
			if _, err := conn.Write(packet); err != nil {
				fmt.Fprintln(os.Stderr, "write:", err)
			}
			seq++
		}
	}

	// Permit in-flight UDP packets to return, then collect all available results.
	drain := time.NewTimer(2 * time.Second)
	for {
		select {
		case r := <-results:
			record(r)
		case <-drain.C:
			goto done
		}
	}

done:
	if err, ok := readErr.Load().(error); ok {
		fmt.Fprintln(os.Stderr, "read:", err)
	}
	printSummary(len(sentAt), len(rtts), size, duration, rtts, reordered)
}

func printSummary(sent, got, size int, duration time.Duration, rtts []time.Duration, reordered int) {
	fmt.Println()
	fmt.Printf("Sent: %d   Received: %d   Lost: %d (%.2f%%)   Reordered: %d\n",
		sent, got, sent-got, percent(sent-got, sent), reordered)
	fmt.Printf("Payload rate: %.2f Mbit/s sent, %.2f Mbit/s echoed\n",
		float64(sent*size*8)/duration.Seconds()/1_000_000,
		float64(got*size*8)/duration.Seconds()/1_000_000)
	if got == 0 {
		fmt.Println("No replies. Check the server address, Windows Firewall, routing, and UDP filtering.")
		return
	}

	sort.Slice(rtts, func(i, j int) bool { return rtts[i] < rtts[j] })
	var total time.Duration
	for _, rtt := range rtts {
		total += rtt
	}
	jitter := time.Duration(0)
	for i := 1; i < len(rtts); i++ {
		jitter += absDuration(rtts[i] - rtts[i-1])
	}
	if len(rtts) > 1 {
		jitter /= time.Duration(len(rtts) - 1)
	}
	fmt.Printf("RTT: min %s  avg %s  p50 %s  p95 %s  p99 %s  max %s\n",
		rtts[0].Round(time.Microsecond),
		(total / time.Duration(got)).Round(time.Microsecond),
		percentile(rtts, 0.50).Round(time.Microsecond),
		percentile(rtts, 0.95).Round(time.Microsecond),
		percentile(rtts, 0.99).Round(time.Microsecond),
		rtts[len(rtts)-1].Round(time.Microsecond))
	fmt.Printf("RTT spread indicator (mean adjacent sorted delta): %s\n", jitter.Round(time.Microsecond))
	fmt.Println("RDP guide: <40 ms RTT and near-zero loss is excellent; <80 ms is usually comfortable.")
	fmt.Println("Watch p95/p99: occasional spikes above 100–150 ms or any sustained loss can feel laggy.")
}

func percentile(values []time.Duration, p float64) time.Duration {
	index := int(math.Ceil(p*float64(len(values)))) - 1
	if index < 0 {
		index = 0
	}
	return values[index]
}

func percent(n, total int) float64 {
	if total == 0 {
		return 0
	}
	return float64(n) * 100 / float64(total)
}

func absDuration(v time.Duration) time.Duration {
	if v < 0 {
		return -v
	}
	return v
}

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
