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
	listenPort, _ := os.LookupEnv("listenPort")
	listenHost, ok := os.LookupEnv("listenHost")
	if !ok {
		listenHost = ""
	}
	listenAddress := listenHost + ":" + listenPort
	r.HandleFunc("/", myHandler)
	r.HandleFunc("/error", errorHandler)
	r.HandleFunc("/crash", crashHandler)
	r.HandleFunc("/dns", dnsHandler)
	r.HandleFunc("/headers", headerHandler)
	r.HandleFunc("/ping", pingHandler)
	r.Handle("/metrics", promhttp.Handler())
	fmt.Printf("Starting application on: %s", listenAddress)
	loggedRouter := handlers.LoggingHandler(os.Stdout, r)
	log.Fatal(http.ListenAndServe(listenAddress, loggedRouter))
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
	fmt.Printf("TEST ERROR MESSAGE")
	fmt.Fprintf(w, "TEST ERROR MESSAGE")
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
