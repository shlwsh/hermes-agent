#!/bin/bash
# 自动检测 WSL 中的宿主机代理并输出 export 语句

HOST_IP=$(ip route show | grep default | awk '{print $3}')
if [ -z "$HOST_IP" ]; then
    # 备选方案：从 resolv.conf 获取
    HOST_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
fi

if [ -n "$HOST_IP" ]; then
    for port in 7897 7890 1080; do
        # 使用 timeout 防止 nc 卡死
        if timeout 0.5s nc -zv $HOST_IP $port >/dev/null 2>&1; then
            PROXY_URL="http://$HOST_IP:$port"
            echo "export http_proxy=$PROXY_URL"
            echo "export https_proxy=$PROXY_URL"
            echo "export all_proxy=$PROXY_URL"
            echo "export HTTP_PROXY=$PROXY_URL"
            echo "export HTTPS_PROXY=$PROXY_URL"
            echo "export ALL_PROXY=$PROXY_URL"
            exit 0
        fi
    done
fi

# 如果没检测到，则不输出任何内容
exit 1
