---
title: "Per-client nsupdate/RFC2136 DNS Updates when dnsmasq Issues a Lease"
date: 2024-05-18T20:00:00+02:00
---

I have a fairly complicated home network setup. I use bind to provide DNS to the network. I also like to have each host on the network have both forward- and backward-resolvable DNS. The best way to do this - that I found - was to run BIND and configure it to take DNS updates via nsupdate/[RFC2136](https://www.rfc-editor.org/rfc/rfc2136).

OpenWRT *used* to use ISC DHCP, which natively provides a way to have updates sent when a DHCP lease is issued to a client.  Unfortunately, they no longer do (as of the 23.x release series, I believe). Instead, ISC DHCP has been replaced with the very-capable dnsmasq.

Unfortunately, dnsmasq doesn't have support for nsupdate/RFC2136. what it does have is a way to call a script each time a DHCP lease is issued. So let's use that to perform the DNS updates.

Below is the quick script I wrote to do this. The script can be installed by:

1. Writing it to `/usr/local/bin/dnsmasq-nsupdate.sh`.
2. Running `chmod +x /usr/local/bin/dnsmasq-nsupdate.sh` to make the script executable.
3. Appending `dhcp-script=/usr/local/bin/dnsmasq-nsupdate.sh` to `/etc/dnsmasq.conf`
4. In `/etc/init.d/dnsmasq`, there is a block of lines that all begin with `procd_add_jail_mount`. At the end of that block, add this as a new line: `procd_add_jail_mount /usr/local/bin/dnsmasq-nsupdate.sh /usr/bin/logger /usr/bin/nsupdate /lib /usr/lib /etc/dnsmasq-nsupdate`
5. Copy your BIND keyfile to `/etc/dnsmasq-nsupdate/keyfile.key`.
6. Restart dnsmasq: `service dnsmasq restart`.

Finally, there are several alterations you may want or need to make:

* In the quoted strings inside the if blocks, you may want to add `debug` to see why something is not working.
* You may need to add `server` or `zone` configuration to the quoted strings.

In short, if something isn't working, you probably need to adjust the quoted strings. These are commands that you can run directly in `nsupdate`. If something isn't working, I would manually run `nsupdate` and figure out how to make that work, then adjust the script to match.

Please do feel free to contact me with questions. Because this is such a rare use case, I haven't done as good a job with the directions as I usually would.

Here's the script:

```shell
#!/bin/sh

# to use:
# write me to /usr/local/bin/dnsmasq-nsupdate.sh
# chmod +x /usr/local/bin/dnsmasq-nsupdate.sh
# append to /etc/dnsmasq.conf:
# dhcp-script=/usr/local/bin/dnsmasq-nsupdate.sh
# in /etc/init.d/dnsmasq, find the blob of lines that begin "procd_add_jail_mount" and add:
#         procd_add_jail_mount /usr/local/bin/dnsmasq-nsupdate.sh /usr/bin/logger /usr/bin/nsupdate /lib /usr/lib /etc/dnsmasq-nsupdate
# restart dnsmasq

# Borrowed from https://askubuntu.com/questions/557098/bash-command-to-convert-ip-addresses-into-their-reverse-form
reverseip () {
    local IFS
    IFS=.
    set -- $1
    echo $4.$3.$2.$1
}

# Add, old, or del, determines mode
AOD=$1
# Mac address of the lease
MAC=$2
# New IP address
IP_ADDR=$3
RIP=$(reverseip $3)
# Hostname
L_HOSTNAME=$4

FQDN=${L_HOSTNAME}.${DNSMASQ_DOMAIN}
TTL="3600"
KEYFILE=/etc/dnsmasq-nsupdate/keyfile.key

if [ $AOD == "add" ] || [ $AOD == "old" ]
then
    echo "
    update delete ${FQDN} A
    update add ${FQDN} ${TTL} A ${IP_ADDR}

    update delete ${RIP}.in-addr.arpa. PTR
    update add ${RIP}.in-addr.arpa. $TTL PTR ${FQDN}
    send
    " | nsupdate -k $KEYFILE | logger -t dnsmasq-nsupdate
else
    # clear old addresses only
    echo "
    update delete ${FQDN} A

    update delete ${RIP}.in-addr.arpa. PTR
    send
    " | nsupdate -k $KEYFILE | logger -t dnsmasq-nsupdate
fi
```