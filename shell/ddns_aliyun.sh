#!/bin/sh

aliddns_ak="111"
aliddns_sk="222"
aliddns_get_public_ip="curl -s http://members.3322.org/dyndns/getip"
aliddns_dns="223.6.6.6"
aliddns_ttl="600"
aliddns_domain="example.cn"
aliddns_name="subdomain"

timestamp=$(date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ")

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c; do
        case $c in
        [a-zA-Z0-9._-]) out="$out$c" ;;
        *) out="$out$(printf '%%%02X' "'$c")" ;;
        esac
    done
    echo -n $out
}

enc() {
    echo -n "$1" | urlencode
}

send_request() {
    local args="AccessKeyId=$aliddns_ak&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddns_sk&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

get_recordid() {
    grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"'
}

query_recordid() {
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$aliddns_subdomain.$aliddns_domain&Timestamp=$timestamp"
}

update_record() {
    send_request "UpdateDomainRecord" "RR=$aliddns_subdomain&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$public_ip"
}

add_record() {
    send_request "AddDomainRecord&DomainName=$aliddns_domain" "RR=$aliddns_subdomain&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$public_ip"
}

#add support */%2A and @/%40 record
case $aliddns_name in
\*)
    aliddns_subdomain=%2A
    ;;
\@)
    aliddns_subdomain=%40
    ;;
*)
    aliddns_subdomain=$aliddns_name
    ;;
esac

public_ip="$($aliddns_get_public_ip)"

#support @ record nslookup
if [ "$aliddns_name" = "@" ]; then
    query_url_info=$(nslookup $aliddns_domain $aliddns_dns 2>&1)
else
    query_url_info=$(nslookup $aliddns_name.$aliddns_domain $aliddns_dns 2>&1)
fi

remode_ip=$(echo "$query_url_info" | grep ^Address | tail -n1 | awk -F\: '{print $NF}' | awk '{print $1}')

if [ -z "$public_ip" ] || [ -z "$remode_ip" ]; then

    logger -t "DDNS" -p "error" "Status:Error,Public IP or Remote IP is empty,Exit!"
    exit 1

fi

# echo -e "public_ip:\t$public_ip"
# echo -e "remode_ip:\t$remode_ip"
if [ "$public_ip" = "$remode_ip" ]; then
    logger -t "DDNS" -p "info" "Status:Skipped,URL=$aliddns_name.$aliddns_domain,Public IP=$public_ip,Remote IP=$remode_ip"
    exit 0
fi

for i in $(seq 1 10); do
    aliddns_record_id=$(query_recordid | get_recordid)
    if [ -z "$aliddns_record_id" ]; then
        # echo $i,sleep 1s
        sleep 1
    else
        # echo quit_func
        return
    fi
done

if [ "$aliddns_record_id" = "" ]; then
    aliddns_record_id=$(add_record | get_recordid)
    # echo "added record $aliddns_record_id"
    logger -t "DDNS" "Status:Add,URL=$aliddns_name.$aliddns_domain,Public IP=$public_ip,RecordID=$aliddns_record_id"
else
    update_record $aliddns_record_id
    # echo "updated record $aliddns_record_id"
    logger -t "DDNS" "Status:Updated,URL=$aliddns_name.$aliddns_domain,Public IP=$public_ip,Remote IP=$remode_ip,RecordID=$aliddns_record_id"

fi
