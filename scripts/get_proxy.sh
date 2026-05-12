#!/bin/bash
# 自动检测 WSL 中的宿主机代理并输出 export 语句

HOST_IP=$(ip route show | grep default | awk '{print $3}')
if [ -z "$HOST_IP" ]; then
    # 备选方案：从 resolv.conf 获取
    HOST_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
fi

if [ -n "$HOST_IP" ]; then
    for ip in 127.0.0.1 $HOST_IP; do
        for port in 7897 7890 1080; do
            if timeout 0.5s nc -zv $ip $port >/dev/null 2>&1; then
                PROXY_URL="http://$ip:$port"
                echo "export http_proxy=$PROXY_URL"
            echo "export https_proxy=$PROXY_URL"
            echo "export all_proxy=$PROXY_URL"
            echo "export HTTP_PROXY=$PROXY_URL"
            echo "export HTTPS_PROXY=$PROXY_URL"
            echo "export ALL_PROXY=$PROXY_URL"
            echo "export no_proxy='localhost,127.0.0.1,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8,*.local'"
            echo "export NO_PROXY='localhost,127.0.0.1,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8,*.local'"
            >&2 echo "📡 [Proxy] Detected host proxy at $PROXY_URL"
            exit 0
        fi
        done
    done
fi

>&2 echo "⚠️ [Proxy] No host proxy detected, running without proxy."
exit 1
