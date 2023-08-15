#!/bin/bash

target="$1"
mkdir "$1"
cd "$1"

echo "Starting Recon"
echo "$1" | subfinder  | anew subs.txt
echo "$1" | shuffledns -w "../resolvers.txt" -w resolved.txt | anew subs.txt
echo "$1" | assetfinder -subs-only | anew subs.txt | wc -l

## DNS RESOLUTION
puredns resolve subs.txt -r ../resolvers.txt -w resolved.txt | wc -l 
dnsx -l resolved.txt -json -o dns.json | jq -r '.a[]?' | anew ips.txt | wc -l

## PORTS SCANS
nmap -T4 -vv -iL "ips.txt" --top-ports 3000 -n -open -oX nmap.xml
tew -x nmap.xml -dnsx dns.json --vhost -o hostport.txt | httpx -sr -srd responses -json -o http.json

cat http.json | jq -r '.url' | sed -e 's/:443$//g' | sort -u http.txt

## CRAWLING
gospider -S http.txt --json | grep "{" | jq -r '.output?' | tee crawl.txt

## Javascript Pulling
cat crawl.txt | grep '\.js' | httpx -sr -srd js

echo "FINISH"
