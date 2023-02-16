package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"runtime"
	"strings"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var count int
var hostname, operatingSystem, architecture string
var imageName, imageTag string
var environment, secret, url, dnsString string
var dnsTestHost []string

func init() {
	hostname, _ = os.Hostname()
	imageName, _ = os.LookupEnv("imageName")
	imageTag, _ = os.LookupEnv("imageTag")
	environment, _ = os.LookupEnv("environment")
	secret, _ = os.LookupEnv("secret")
	secret = strings.TrimSuffix(secret, "\n")
	url, _ = os.LookupEnv("pingService")
	operatingSystem = runtime.GOOS
	architecture = runtime.GOARCH

	dnsString, _ = os.LookupEnv("dnsTestHosts")
	dnsTestHost = strings.Split(dnsString, ",")
}

func main() {

	r := mux.NewRouter()
	listenPort, ok := os.LookupEnv("listenPort")
        if !ok {
                listenPort = "8080"
        }
        listenPortTLS, ok := os.LookupEnv("listenPortTLS")
        if !ok {
                listenPortTLS = "8443"
        }
	listenHost, ok := os.LookupEnv("listenHost")
	if !ok {
		listenHost = ""
	}
	listenAddress := listenHost + ":" + listenPort
	listenAddressTLS := listenHost + ":" + listenPortTLS

        listenMode, ok := os.LookupEnv("listenMode")
        if !ok {
                listenMode = "http"
        }
	r.HandleFunc("/", myHandler).Methods("GET")
	r.HandleFunc("/error", errorHandler)
	r.HandleFunc("/crash", crashHandler).Methods("POST")
	r.HandleFunc("/dns", dnsHandler).Methods("GET")
	r.HandleFunc("/headers", headerHandler).Methods("GET")
	r.HandleFunc("/ping", pingHandler).Methods("GET")
	r.Handle("/metrics", promhttp.Handler())
	loggedRouter := handlers.LoggingHandler(os.Stdout, r)


        if listenMode == "https" {
	  fmt.Printf("Starting HTTPS application on: %s", listenAddressTLS)
	  log.Fatal(http.ListenAndServeTLS(listenAddressTLS, "/etc/cert/tls.crt", "/etc/cert/tls.key", loggedRouter))
        } else {
	  fmt.Printf("Starting HTTP application on: %s", listenAddress)
	  log.Fatal(http.ListenAndServe(listenAddress, loggedRouter))

       }
}

func myHandler(w http.ResponseWriter, r *http.Request) {
	resp, _ := http.Get(url)
	pong, _ := ioutil.ReadAll(resp.Body)

	fmt.Fprintf(w, "%s:%s :: %s :: %s :: %s :: %s :: %s :: %s : %d", imageName, imageTag, environment, secret, operatingSystem, architecture, hostname, pong, count)
	count++
}

func crashHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Bye!")
	os.Exit(1)
}

func errorHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(os.Stderr, "ERROR - an error has occurred\n")
	fmt.Fprintf(w, "Testing Error Message")
}

func dnsHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "DNS Resolver Verification :: %s\n", hostname)
	for _, host := range dnsTestHost {
		fmt.Fprintf(w, "========================================\n")
		ips, err := net.LookupIP(host)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Could not get IPs: %v\n", err)
		}
		for _, ip := range ips {
			fmt.Fprintf(w, "%s. IN A %s\n", host, ip.String())
		}
	}
}

func headerHandler(w http.ResponseWriter, r *http.Request) {
	for k, v := range r.Header {
		fmt.Fprintf(w, "Header[%q] = %q\n", k, v)
	}
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%s-pong", hostname)
}
