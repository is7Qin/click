#!/bin/bash

# 获取当前日期
current_date=$(date +%Y-%m-%d)

# 获取目录列表
directory=$(ls -d /opt/rustdesk-user/*)

# 清空停止列表
echo > /var/log/rustdesk-user/expired.log

# 遍历所有 /opt/rustdesk-user/**/end 文件
for directory_for in ${directory}; do
    # 读取文件内容
    while read -r line1 && read -r line2; do
        username=$line1
        user_date=$line2
        
        # 使用 awk 进行日期比较
        if [[ $(awk -v end_date="$user_date" -v now_date="$current_date" 'BEGIN { if (end_date > now_date) { print "0" } else { print "1" } }') -eq 1 ]]; then
            cd ${directory_for}/server* && docker compose down &>/dev/null
            cd ${directory_for}/api* && docker compose down &>/dev/null
            echo -e "Username: ${username}, Date: ${user_date} (expired)" >> /var/log/rustdesk-user/expired.log
        fi
    done < "${directory_for}/end"
done
