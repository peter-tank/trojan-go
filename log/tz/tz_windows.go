// +build windows

package tz

import (
	"fmt"
	"os"
	"strings"
	"time"

	_ "time/tzdata"
)

func init() {
	// Force try to load tzdata from go builder embedded first
	out := strings.TrimSpace(os.Getenv("TZ"))

	if out != "" {
		if loc, err := time.LoadLocation(out); err == nil {
			time.Local = loc
		} else {
			de("LoadLocation failed for %s: %v", out, err)
		}
	}

	return
}

func de(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
}
