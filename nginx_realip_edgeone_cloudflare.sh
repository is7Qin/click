#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# 定义文件路径
combined_file="/etc/nginx/cloudflare.conf"

# 定义重试次数和每次重试的间隔秒数
MAX_RETRIES=10
RETRY_DELAY=2 # seconds

# 函数：获取IP地址段，如果为空则重试
# 参数1: URL
# 参数2: 描述 (用于日志输出)
get_ips_with_retry() {
    local url="$1"
    local description="$2"
    local result=""
    local retries=0

    echo "Fetching $description from $url..." >&2

    while [ -z "$result" ] && [ "$retries" -lt "$MAX_RETRIES" ]; do
        if [ "$retries" -gt 0 ]; then
            echo "Warning: No content from $description (attempt $((retries+1))/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..." >&2
            sleep "$RETRY_DELAY"
        fi

        result=$(curl -s "$url")

        if [ -z "$result" ]; then
            retries=$((retries+1))
        else
            echo "Successfully fetched $description." >&2
            break # 成功获取，跳出循环
        fi
    done

    if [ -z "$result" ]; then
        echo "Error: Failed to get $description from $url after $MAX_RETRIES attempts. Content is still empty." >&2
        return 1 # 返回非零状态码表示失败
    fi

    echo "$result" # 成功获取后，将结果输出到标准输出
    return 0 # 返回零状态码表示成功
}

# 获取Cloudflare IPv4和IPv6地址段
ipv4_ranges=$(get_ips_with_retry "https://www.cloudflare.com/ips-v4" "Cloudflare IPv4") || exit 1
ipv6_ranges=$(get_ips_with_retry "https://www.cloudflare.com/ips-v6" "Cloudflare IPv6") || exit 1

# 获取EdgeOne IPv4和IPv6地址段
edge_one_ipv4_ranges=$(get_ips_with_retry "https://api.edgeone.ai/ips?version=v4" "EdgeOne IPv4") || exit 1
edge_one_ipv6_ranges=$(get_ips_with_retry "https://api.edgeone.ai/ips?version=v6" "EdgeOne IPv6") || exit 1

# 生成新的IP段配置信息
new_config=""

# 使用'printf'代替'echo'，更健壮地处理换行和变量，并避免后续的'\n'
# sed -E 's/(.*)/set_real_ip_from \1;/' 确保每一行都被转换
printf '%s\n' "$ipv4_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/' >> new_config_temp.txt
printf '%s\n' "$ipv6_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/' >> new_config_temp.txt
printf '%s\n' "$edge_one_ipv4_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/' >> new_config_temp.txt
printf '%s\n' "$edge_one_ipv6_ranges" | sed -E 's/(.*)/set_real_ip_from \1;/' >> new_config_temp.txt
printf '\nreal_ip_header CF-Connecting-IP;\n' >> new_config_temp.txt

new_config=$(cat new_config_temp.txt)
rm new_config_temp.txt

# 如果文件不存在，或者文件内容与新的配置不同，则更新文件并重载nginx
# 使用 diff -q 来比较文件，效率更高且避免加载整个文件到内存
if [ ! -f "$combined_file" ] || ! diff -q "$combined_file" <(echo -e "$new_config") >/dev/null; then
    echo -e "$new_config" > "$combined_file"
    echo "Cloudflare/EdgeOne IP段配置已更新"
    nginx -t && nginx -s reload # 先测试配置，再重载
else
    echo "Cloudflare/EdgeOne IP段未变化"
fi
