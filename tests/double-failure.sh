#!/bin/bash
# Kills the active node, then the next one; checks whether the third node takes over; restores everything.
who() { curl -s -m 1 -D - -o /dev/null http://172.20.0.100/ | tr -d '\r' | awk -F': ' 'tolower($1)=="x-served-by"{print $2}'; }
docker update --restart=no webz-001 webz-002 >/dev/null

echo "##### 1. kill webz-001 (active), wait for webz-002 #####"
docker kill webz-001 >/dev/null
for n in $(seq 1 60); do H=$(who); [ "$H" = "webz-002" ] && break; sleep 1; done
echo "active now: $H"

echo; echo "##### 2. kill webz-002 as well, only webz-003 is left #####"
docker kill webz-002 >/dev/null
sleep 25
docker exec webz-003 pcs status | sed -n '/Stack/,/Daemon/p'
echo "floating IP -> HTTP $(curl -s -m 3 -o /dev/null -w '%{http_code}' http://172.20.0.100/)  served_by='$(who)'"

echo; echo "##### 3. restore both nodes #####"
docker update --restart=unless-stopped webz-001 webz-002 >/dev/null
docker start webz-001 webz-002 >/dev/null
for n in $(seq 1 120); do
  docker exec webz-003 pcs status 2>/dev/null | grep -q 'Online: \[ webz-001 webz-002 webz-003 \]' && break
  sleep 2
done
sleep 10
docker exec webz-003 pcs status | sed -n '/Online/,/Daemon/p'
echo "served_by='$(who)'"
