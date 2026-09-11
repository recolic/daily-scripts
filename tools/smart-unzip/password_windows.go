// created by GPT-6 Astra
package main

import (
	"bytes"
	"fmt"
	"syscall"
	"unsafe"
)

var kernel32 = syscall.NewLazyDLL("kernel32.dll")

// 7z converts its Unicode password to CP_ACP. Invert that conversion, then verify an exact byte round-trip (never accept best-fit substitution).
func passwordArgument(raw []byte) (string, error) {
	if len(raw) == 0 { return "", nil }
	wide := make([]uint16, len(raw)*2+1)
	n, _, _ := kernel32.NewProc("MultiByteToWideChar").Call(0, 0, uintptr(unsafe.Pointer(&raw[0])), uintptr(len(raw)), uintptr(unsafe.Pointer(&wide[0])), uintptr(len(wide)))
	if n == 0 { return "", fmt.Errorf("password cannot be decoded using Windows ANSI code page") }
	back := make([]byte, len(raw)*4+4)
	m, _, _ := kernel32.NewProc("WideCharToMultiByte").Call(0, 0, uintptr(unsafe.Pointer(&wide[0])), n, uintptr(unsafe.Pointer(&back[0])), uintptr(len(back)), 0, 0)
	if m == 0 || !bytes.Equal(raw, back[:m]) { return "", fmt.Errorf("password bytes cannot round-trip through Windows ANSI code page; use Linux 7z") }
	return syscall.UTF16ToString(wide[:n]), nil
}