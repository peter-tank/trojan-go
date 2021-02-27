package main

import (
	"flag"

	"github.com/p4gefau1t/trojan-go/option"

	_ "github.com/p4gefau1t/trojan-go/component"
	"github.com/p4gefau1t/trojan-go/log"
	_ "github.com/p4gefau1t/trojan-go/log/golog"
	//_ "github.com/p4gefau1t/trojan-go/log/simplelog"

	//the following modules are optional
	//you can comment some of them if you don't need them
	_ "github.com/p4gefau1t/trojan-go/api/service"
	_ "github.com/p4gefau1t/trojan-go/api/control"
	_ "github.com/p4gefau1t/trojan-go/proxy/client"
	_ "github.com/p4gefau1t/trojan-go/tunnel/adapter"
	_ "github.com/p4gefau1t/trojan-go/tunnel/freedom"
	_ "github.com/p4gefau1t/trojan-go/tunnel/socks"
	_ "github.com/p4gefau1t/trojan-go/tunnel/http"
	_ "github.com/p4gefau1t/trojan-go/proxy/forward"
	_ "github.com/p4gefau1t/trojan-go/tunnel/dokodemo"
	_ "github.com/p4gefau1t/trojan-go/proxy/nat"
	_ "github.com/p4gefau1t/trojan-go/tunnel/tproxy"
	_ "github.com/p4gefau1t/trojan-go/proxy/server"
	_ "github.com/p4gefau1t/trojan-go/statistic/memory"
	_ "github.com/p4gefau1t/trojan-go/statistic/mysql"
	_ "github.com/p4gefau1t/trojan-go/tunnel/router"
	_ "github.com/p4gefau1t/trojan-go/version"
	_ "github.com/p4gefau1t/trojan-go/easy"
	_ "github.com/p4gefau1t/trojan-go/url"
	_ "github.com/p4gefau1t/trojan-go/proxy/custom"

	_ "github.com/p4gefau1t/trojan-go/tunnel/transport"
	_ "github.com/p4gefau1t/trojan-go/tunnel/tls"
	_ "github.com/p4gefau1t/trojan-go/tunnel/trojan"
	_ "github.com/p4gefau1t/trojan-go/tunnel/websocket"
	_ "github.com/p4gefau1t/trojan-go/tunnel/simplesocks"
	_ "github.com/p4gefau1t/trojan-go/tunnel/mux"
	_ "github.com/p4gefau1t/trojan-go/tunnel/shadowsocks"
)

func main() {
	flag.Parse()
	for {
		h, err := option.PopOptionHandler()
		if err != nil {
			log.Fatal("invalid options")
		}
		err = h.Handle()
		if err == nil {
			break
		}
	}
}
