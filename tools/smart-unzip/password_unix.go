// created by GPT-6 Astra
//go:build !windows

package main

// exec preserves arbitrary non-NUL argv bytes on Unix. Recent 7z versions also round-trip invalid UTF-8 through their internal text conversion.
func passwordArgument(raw []byte) (string, error) { return string(raw), nil }