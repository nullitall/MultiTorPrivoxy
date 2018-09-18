#!/bin/bash

trap cleanup 1 2 3 6

cleanup()
{
  echo "Caught Signal ... cleaning up."
  rm -rf data privoxy
  killall -v tor privoxy
  echo "Done cleanup ... quitting."
  exit 1
}
set -e

base_socks_port=9050
base_control_port=15000
base_http_port=8118

mkdir data
mkdir privoxy


TOR_INSTANCES="$1"
ip_addr="$2"
if [ ! $TOR_INSTANCES ] || [ $TOR_INSTANCES -lt 1 ]; then
    echo "Please supply an instance count"
    echo "Example: ./priv-tor.sh 5 192.168.1.1"
    exit 1
fi

for i in $(seq $TOR_INSTANCES)
do
	j=$((i+1))
	socks_port=$((base_socks_port+i))
	control_port=$((base_control_port+i))
	http_port=$((base_http_port+i))
	if [ ! -d "data/tor$i" ]; then
		echo "Creating directory data/tor$i"
		mkdir "data/tor$i"
		echo "Creating directory privoxy/privoxy$i"
		mkdir "privoxy/privoxy$i"
		echo "listen-address $ip_addr:$http_port" >> privoxy/privoxy$i/config 
		echo "forward-socks5 / 		localhost:$socks_port	." >> privoxy/privoxy$i/config 
		echo "forward			192.168.*.*/	.">> privoxy/privoxy$i/config
		echo "forward			10.*.*.*/	.">> privoxy/privoxy$i/config 
		echo "forward			127.*.*.*/	.">> privoxy/privoxy$i/config 
	fi

	echo "Running tor --RunAsDaemon 1 --CookieAuthentication 0 --ControlPort $control_port --PidFile tor$i.pid --SocksListenAddress $ip_addr --SocksPort $socks_port --DataDirectory data/tor$i"
	echo "Running privoxy --pidfile privoxy.pid config"
	tor --RunAsDaemon 1 --CookieAuthentication 0 --ControlPort $control_port --PidFile tor$i.pid --SocksPort $socks_port --DataDirectory data/tor$i
	privoxy --pidfile privoxy$i.pid privoxy/privoxy$i/config
done
