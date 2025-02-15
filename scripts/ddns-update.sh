#!/bin/sh

. /config.sh

# #####################################################################
# functions to get public ip
get_ip4() {
  CURRENT_IP=$(curl -s http://4.ipw.cn/ || curl -s http://myip.ipip.net/s)
  if [ -z $CURRENT_IP ]; then
    dig_ip=$(dig txt ch +short whoami.cloudflare @1.1.1.1)
    if [ "$?" = 0 ]; then
      CURRENT_IP=$(echo $dig_ip | tr -d '"')
    else
      exit 1
    fi
  fi
  echo $CURRENT_IP
}

get_ip6() {
  CURRENT_IP=$(curl -s https://ipv6.icanhazip.com/ || curl -s https://api6.ipify.org)
  if [ -z $CURRENT_IP ]; then
    dig_ip=$(dig txt ch +short whoami.cloudflare @2606:4700:4700::1111)
    if [ "$?" = 0 ]; then
      CURRENT_IP=$(echo $dig_ip | tr -d '"')
    else
      exit 1
    fi
  fi
  echo $CURRENT_IP
}
# #####################################################################
# Step 1: get public IP address
if [ "$RECORD_TYPE" == "A" ]; then
  CURRENT_IP=$(get_ip4)
  PROTO="ip"
elif [ "$RECORD_TYPE" == "AAAA" ]; then
  CURRENT_IP=$(get_ip6)
  PROTO="ipv6"
fi

if [ -z $CURRENT_IP ]; then
  echo "[$(date)]: Public IP not found, check internet connection"
  exit 1
fi
# #####################################################################
# Step 2: check against old ip
OLD_IP=$(cat /old_record_ip)
if [ "$OLD_IP" == "$CURRENT_IP" ]; then
  echo "[$(date)]: IP unchanged, not updating. IP: $CURRENT_IP"
# #####################################################################
# Step 3: Update ddns
else
  update=$(curl -s "https://www.duckdns.org/update?domains=${SUBDOMAINS}&token=${TOKEN}&${PROTO}=${CURRENT_IP}")

  if [ "$update" == "OK" ]; then
    echo "[$(date)]: DDNS update successful...   IP: $CURRENT_IP"
    echo $CURRENT_IP > /old_record_ip
  else
    echo "[$(date)]: DDNS update failed...  Curr IP: $CURRENT_IP"
  fi
fi
