#!/bin/bash

# Cloudflare Bypass Module for Sn1per
# This module implements various techniques to bypass Cloudflare protection

function cloudflare_bypass {
    local target=$1
    local output_dir=$2
    
    echo -e "$OKBLUE[*]$RESET Starting Cloudflare bypass for $target..."
    
    # Check if target is protected by Cloudflare
    if wafw00f $target | grep -q "Cloudflare"; then
        echo -e "$OKBLUE[*]$RESET Target is protected by Cloudflare"
        
        # Method 1: DNS History
        echo -e "$OKBLUE[*]$RESET Checking DNS history..."
        amass enum -passive -d $target -o $output_dir/amass.txt
        
        # Method 2: SSL Certificate History
        echo -e "$OKBLUE[*]$RESET Checking SSL certificate history..."
        curl -s "https://crt.sh/?q=$target&output=json" | jq -r '.[].name_value' | sort -u > $output_dir/crtsh.txt
        
        # Method 3: Cloudflare IP Range Scan
        echo -e "$OKBLUE[*]$RESET Scanning Cloudflare IP ranges..."
        for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
            nmap -p 80,443 --script http-title -oA $output_dir/cloudflare_scan $ip
        done
        
        # Method 4: Subdomain Enumeration
        echo -e "$OKBLUE[*]$RESET Enumerating subdomains..."
        subfinder -d $target -o $output_dir/subfinder.txt
        
        # Method 5: Web Application Scanning with Custom Headers
        echo -e "$OKBLUE[*]$RESET Scanning web application..."
        httpx -l $output_dir/subfinder.txt -o $output_dir/httpx.txt -H "User-Agent: $CLOUDFLARE_USER_AGENT" -timeout $CLOUDFLARE_TIMEOUT -retries $CLOUDFLARE_RETRIES
        
        # Method 6: Directory Bruteforcing
        echo -e "$OKBLUE[*]$RESET Performing directory bruteforce..."
        ffuf -u https://$target/FUZZ -w /usr/share/wordlists/dirb/common.txt -o $output_dir/ffuf.json -of json -H "User-Agent: $CLOUDFLARE_USER_AGENT"
        
        # Combine results
        cat $output_dir/amass.txt $output_dir/crtsh.txt $output_dir/subfinder.txt | sort -u > $output_dir/all_subdomains.txt
        
        echo -e "$OKGREEN[+]$RESET Cloudflare bypass completed. Results saved in $output_dir"
    else
        echo -e "$OKGREEN[+]$RESET Target is not protected by Cloudflare"
    fi
}

# Export the function
export -f cloudflare_bypass 