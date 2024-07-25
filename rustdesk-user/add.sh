#!/bin/bash
###
### add.sh - add rustdesk user
###
### Usage:
###   add.sh <serviceID> <userID> <months>
###
### Options:
###   <serviceID>       服务ID 需为三位数字
###   <userID>          用户ID 类型 string
###   <months>          租期月份 类型 number
###   -h        Show help message.

# 获取当前日期
current_date=$(date +%Y-%m-%d)

# IP
ip=""

# 目录
template_directory="/opt/rustdesk-user-template/"
user_directory="/opt/rustdesk-user/"

# 生成随机密码
random_key=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c18)

help() {
    awk -F'### ' '/^###/ { print $2 }' "$0"
}

if [[ $# == 0 ]] || [[ $1 == "-h" || $1 == "help" ]]; then
    help
    exit 0
fi

if [[ $1 == [0-9][0-9][0-9] ]] && [[ $3 =~ ^[0-9]+$ ]]; then
        server_folder=${user_directory}/${1}/server-${1}
        api_folder=${user_directory}/${1}/api-${1}
        end_file=${user_directory}/${1}/end
        user_folder=${user_directory}/${1}

        if [[ -d ${user_folder} ]];then
                echo "已存在该目录"
                exit 1
        fi

        # 复制模板 修改路径
        cp -a ${template_directory} ${user_folder}
        mv ${user_directory}/${1}/server-template ${server_folder}
        mv ${user_directory}/${1}/api-template ${api_folder}

        # 设置随机密码
        sed -i 's/template_pwd/'${random_key}'/g' ${server_folder}/docker-compose.yml

        # 设置端口
        sed -i 's/template/'${1}'/g' ${server_folder}/docker-compose.yml
        sed -i 's/template/'${1}'/g' ${api_folder}/docker-compose.yml

        # 设置用户ID
        sed -i 's/template/'${2}'/g' ${end_file}

        # 设置日期
        end_date=$(date -d "$current_date +${3} months" +%Y-%m-%d)
        sed -i 's/2024-01-01/'${end_date}'/g' ${end_file}

        echo -e "ID 服务器: ${ip}:5${1}6
中继服务器: ${ip}:5${1}7
API: http://${ip}:5${1}4
KEY: ${random_key}
用户: ${2}
到期日: ${end_date}"
else
        echo 格式错误
fi
