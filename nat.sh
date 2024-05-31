#!/bin/bash

user_ip_start="172.16.0.10"
user_ip_end="172.16.0.49"
port_first=10000
port_last=10008
sshn=10009

# 将IP地址范围转换为整数表示
ip_to_int() {
  local IFS
  IFS='.'
  read -r ip1 ip2 ip3 ip4 <<< "$1"
  echo $((ip1*256*256*256 + ip2*256*256 + ip3*256 + ip4))
}

# 将整数表示的IP地址转换为点分十进制表示
int_to_ip() {
  local ip=$1
  local ip1=$((ip / 256 / 256 / 256))
  local ip2=$((ip / 256 / 256 % 256))
  local ip3=$((ip / 256 % 256))
  local ip4=$((ip % 256))
  echo "$ip1.$ip2.$ip3.$ip4"
}

# 获取IP地址范围的整数表示
start_ip_int=$(ip_to_int "$user_ip_start")
end_ip_int=$(ip_to_int "$user_ip_end")

# 循环遍历IP地址范围
for ((ip_int = start_ip_int; ip_int <= end_ip_int; ip_int++)); do
  user_ip=$(int_to_ip "$ip_int")

  # 设置SSH的DNAT规则
  iptables -t nat -A PREROUTING -p tcp --dport $sshn -j DNAT --to-destination "$user_ip":22

  # 设置端口范围的DNAT规则（TCP）
  iptables -t nat -A PREROUTING -p tcp -m tcp --dport $port_first:$port_last -j DNAT --to-destination "$user_ip":"$port_first"-"$port_last"

  # 设置端口范围的DNAT规则（UDP）
  iptables -t nat -A PREROUTING -p udp -m udp --dport $port_first:$port_last -j DNAT --to-destination "$user_ip":"$port_first"-"$port_last"

  # 递增SSH、port_first和port_last的值
  sshn=$((sshn + 10))
  port_first=$((port_first + 10))
  port_last=$((port_last + 10))
done
