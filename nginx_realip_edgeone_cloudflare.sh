#!/bin/bash

# 获取Cloudflare IPv4和IPv6地址段
ipv4_ranges=$(curl -s https://www.cloudflare.com/ips-v4)
ipv6_ranges=$(curl -s https://www.cloudflare.com/ips-v6)

# 获取EdgeOne IPv4和IPv6地址段
edge_one_ipv4_ranges=$(curl -s https://api.edgeone.ai/ips?version=v4)
edge_one_ipv6_ranges=$(curl -s https://api.edgeone.ai/ips?version=v6)

# 定义文件路径
combined_file="/etc/nginx/cloudflare.conf"

# 生成新的IP段配置信息
new_config=""
new_config+="$(echo "$ipv4_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/')"
new_config+="\n"
new_config+="$(echo "$ipv6_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/')"
new_config+="\n"
new_config+="$(echo "$edge_one_ipv4_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/')"
new_config+="\n"
new_config+="$(echo "$edge_one_ipv6_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/')"
new_config+="\n"
new_config+="\nreal_ip_header CF-Connecting-IP;"

# 如果文件不存在，或者文件内容与新的配置不同，则更新文件并重载nginx
if [ ! -f "$combined_file" ] || ! cmp -s <(echo -e "$new_config") "$combined_file"; then
    echo -e "$new_config" > "$combined_file"
    echo "Cloudflare IP段配置已更新"
    nginx -s reload
else
    echo "Cloudflare IP段未变化"
fi
