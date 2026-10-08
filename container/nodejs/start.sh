#!/bin/sh
export LANG=en_US.UTF-8
export uuid=${uuid}
export vmpt=${vmpt}
# Railway 开启 TCP Proxy 后会自动注入 RAILWAY_TCP_* 变量，未手动设置时自动读取
export vlpt=${vlpt:-$RAILWAY_TCP_APPLICATION_PORT}
export reym=${reym}
export rlyhost=${rlyhost:-$RAILWAY_TCP_PROXY_DOMAIN}
export rlyport=${rlyport:-$RAILWAY_TCP_PROXY_PORT}
export pvk=${pvk}
export pbk=${pbk}
export sid=${sid}
export argo=${argo}
export agn=${agn}
export agk=${agk}
export ippz=${ippz}
export name=${name}
v46url="https://icanhazip.com"

showmode(){
echo "Argosbx脚本项目地址：https://github.com/yonggekkk/argosbx"
echo "---------------------------------------------------------"
echo
}

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "甬哥Github项目 ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "Argosbx一键无交互小钢炮脚本💣 (精简版：vmess-ws + argo)"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

hostname=$(uname -a | awk '{print $2}')
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
mkdir -p "$HOME/agsbx"

checkport(){
case "$1" in
''|*[!0-9]*) return 1;;
esac
[ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

iskey(){
case "$1" in
''|*[!A-Za-z0-9+/=_-]*) return 1;;
esac
[ "${#1}" -ge 40 ] && [ "${#1}" -le 50 ]
}

v4v6(){
v4=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- "$v46url" 2>/dev/null) )
v6=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- "$v46url" 2>/dev/null) )
v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://ip.fm | sed -E 's/.*Location: ([^,]+(, [^,]+)*),.*/\1/' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
v6dq=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k https://ip.fm | sed -E 's/.*Location: ([^,]+(, [^,]+)*),.*/\1/' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
}

insuuid(){
if [ -z "$uuid" ] && [ ! -e "$HOME/agsbx/uuid" ]; then
uuid=$("$HOME/agsbx/xray" uuid)
echo "$uuid" > "$HOME/agsbx/uuid"
elif [ -n "$uuid" ]; then
echo "$uuid" > "$HOME/agsbx/uuid"
fi
uuid=$(cat "$HOME/agsbx/uuid")
echo "UUID密码：$uuid"
}

installxray(){
echo
echo "=========启用xray内核========="
if [ ! -e "$HOME/agsbx/xray" ]; then
url="https://github.com/yonggekkk/argosbx/releases/download/argosbx/xray-$cpu"; out="$HOME/agsbx/xray"; (command -v curl >/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/xray"
sbcore=$("$HOME/agsbx/xray" version 2>/dev/null | awk '/^Xray/{print $2}')
echo "已安装Xray正式版内核：$sbcore"
fi
cat > "$HOME/agsbx/xr.json" <<EOF
{
  "log": {
  "loglevel": "none"
  },
  "dns": {
    "servers": [
      "${xsdns}"
      ]
   },
  "inbounds": [
EOF
insuuid
if [ -n "$vlpt" ]; then
mkdir -p "$HOME/agsbx/xrk"
if [ -z "$reym" ]; then
reym=www.apple.com
fi
if [ -z "$name" ]; then
name=agsbx
fi
kbfrom='环境变量(重启不变)'
if [ -z "$pvk" ] || [ -z "$pbk" ] || [ -z "$sid" ]; then
kbfrom='本地生成(重启后会变)'
if [ -e "$HOME/agsbx/xrk/private_key" ]; then
pvk=$(cat "$HOME/agsbx/xrk/private_key")
pbk=$(cat "$HOME/agsbx/xrk/public_key" 2>/dev/null)
sid=$(cat "$HOME/agsbx/xrk/short_id" 2>/dev/null)
fi
if [ -z "$pvk" ] || [ -z "$pbk" ]; then
key_pair=$("$HOME/agsbx/xray" x25519)
pvk=$(echo "$key_pair" | awk -F'[：:]' 'tolower($1) ~ /private ?key/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')
pbk=$(echo "$key_pair" | awk -F'[：:]' 'tolower($1) ~ /(public ?key|password)/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')
fi
if [ -z "$sid" ]; then
sid=$(date +%s%N | sha256sum | cut -c 1-8)
fi
fi
if [ -z "$pvk" ] || [ -z "$pbk" ] || [ -z "$sid" ]; then
echo "Reality密钥获取失败，请检查xray x25519的输出格式" && exit
fi
if ! iskey "$pvk" || ! iskey "$pbk"; then
echo "Reality密钥格式不对：pvk/pbk 应为约43位base64字符串"
echo "当前 pvk=$pvk"
echo "当前 pbk=$pbk"
echo "请删除 pvk/pbk/sid 环境变量让脚本自动生成，或改填正确的值" && exit
fi
echo "$pvk" > "$HOME/agsbx/xrk/private_key"
echo "$pbk" > "$HOME/agsbx/xrk/public_key"
echo "$sid" > "$HOME/agsbx/xrk/short_id"
private_key_x=$pvk
public_key_x=$pbk
short_id_x=$sid
echo "Reality密钥来源：$kbfrom"
if [ "$kbfrom" = '本地生成(重启后会变)' ]; then
echo "如需重启不变，请把下面三个值设为环境变量 pvk / pbk / sid："
echo "  pvk=$pvk"
echo "  pbk=$pbk"
echo "  sid=$sid"
fi
fi
echo "$reym" > "$HOME/agsbx/reym"
echo "$name-" > "$HOME/agsbx/name"
}

addvmessws(){
if [ -n "$vmpt" ]; then
echo "$vmpt" > "$HOME/agsbx/vmpt"
vmpt=$(cat "$HOME/agsbx/vmpt")
echo "Vmess-ws端口：$vmpt"
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
            "tag": "vmess-xr",
            "listen": "::",
            "port": ${vmpt},
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                  "path": "${uuid}-vm"
            }
        },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         },
EOF
fi
}

addreality(){
if [ -n "$vlpt" ]; then
if ! checkport "$vlpt"; then
echo "Vless-tcp-reality-v端口不是有效端口: $vlpt" && exit
fi
echo "$vlpt" > "$HOME/agsbx/vlpt"
vlpt=$(cat "$HOME/agsbx/vlpt")
echo "Vless-tcp-reality-v端口：$vlpt"
echo "Reality伪装域名：$reym"
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
            "tag": "reality-vision",
            "listen": "::",
            "port": ${vlpt},
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "fingerprint": "chrome",
                    "target": "${reym}:443",
                    "serverNames": [
                      "${reym}"
                    ],
                    "privateKey": "$private_key_x",
                    "shortIds": ["$short_id_x"]
                }
            },
          "sniffing": {
          "enabled": true,
          "destOverride": ["http", "tls", "quic"],
          "metadataOnly": false
      }
    },
EOF
fi
}

finalizexray(){
sed -i '${s/,\s*$//}' "$HOME/agsbx/xr.json"
cat >> "$HOME/agsbx/xr.json" <<EOF
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
      "domainStrategy":"${xryx}"
     }
    }
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": [ "::/0", "0.0.0.0/0" ],
        "network": "tcp,udp",
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "direct"
      }
    ]
  }
}
EOF
if ! "$HOME/agsbx/xray" run -test -c "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
echo "Xray配置校验失败，请检查端口与伪装域名设置" && exit
fi
nohup "$HOME/agsbx/xray" run -c "$HOME/agsbx/xr.json" >/dev/null 2>&1 &
}

installargo(){
if [ -n "$argo" ] && [ -n "$vmpt" ]; then
echo
echo "=========启用Cloudflared-argo内核========="
if [ ! -e "$HOME/agsbx/cloudflared" ]; then
argocore=$({ command -v curl >/dev/null 2>&1 && curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared || wget -qO- https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared; } | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载Cloudflared-argo最新正式版内核：$argocore"
url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"; out="$HOME/agsbx/cloudflared"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/cloudflared"
fi
argoport=$(cat "$HOME/agsbx/vmpt" 2>/dev/null)
echo "Vmess" > "$HOME/agsbx/vlvm"
echo "$argoport" > "$HOME/agsbx/argoport.log"
if [ -n "${agn}" ] && [ -n "${agk}" ]; then
argoname='固定'
nohup "$HOME/agsbx/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${agk}" >/dev/null 2>&1 &
echo "${agn}" > "$HOME/agsbx/sbargoym.log"
echo "${agk}" > "$HOME/agsbx/sbargotoken.log"
else
argoname='临时'
nohup "$HOME/agsbx/cloudflared" tunnel --url http://localhost:$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > "$HOME/agsbx/argo.log" 2>&1 &
fi
echo "申请Argo${argoname}隧道中……请稍等"
sleep 8
if [ -n "${agn}" ] && [ -n "${agk}" ]; then
argodomain=$(cat "$HOME/agsbx/sbargoym.log" 2>/dev/null)
else
argodomain=$(grep -a trycloudflare.com "$HOME/agsbx/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [ -n "${argodomain}" ]; then
echo "Argo${argoname}隧道申请成功"
else
echo "Argo${argoname}隧道申请失败，请稍后再试"
fi
sleep 5
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' || pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1 ; then
echo "Argosbx脚本进程启动成功，安装完毕" && sleep 2
else
echo "Argosbx脚本进程未启动，安装失败" && exit
fi
fi
}

ins(){
if [ -n "$vmpt" ] && ! checkport "$vmpt"; then
echo "Vmess-ws端口不是有效端口: $vmpt" && exit
fi
webport=${PORT:-3000}
if [ -n "$vmpt" ] && [ "$vmpt" = "$webport" ]; then
echo "Vmess-ws端口 $vmpt 与Node网页端口 PORT=$webport 冲突，请更换" && exit
fi
if [ -n "$vlpt" ] && [ "$vlpt" = "$webport" ]; then
echo "Vless-reality端口 $vlpt 与Node网页端口 PORT=$webport 冲突，请更换" && exit
fi
if [ -n "$vmpt" ] && [ -n "$vlpt" ] && [ "$vmpt" = "$vlpt" ]; then
echo "Vmess-ws端口与Vless-reality端口不能相同：$vmpt" && exit
fi
v4v6
installxray
addvmessws
addreality
finalizexray
installargo
}

argosbxstatus(){
echo "=========当前内核运行状态========="
procs=$(find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null)
if echo "$procs" | grep -Eq 'agsbx/x' || pgrep -f 'agsbx/x' >/dev/null 2>&1; then
echo "Xray：运行中"
else
echo "Xray：未启用"
fi
if echo "$procs" | grep -Eq 'agsbx/c' || pgrep -f 'agsbx/c' >/dev/null 2>&1; then
echo "Argo：运行中"
else
echo "Argo：未启用"
fi
}

cip(){
ipbest(){
serip=$( (command -v curl >/dev/null 2>&1 && (curl -s4m5 -k "$v46url" 2>/dev/null || curl -s6m5 -k "$v46url" 2>/dev/null) ) || (command -v wget >/dev/null 2>&1 && (timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null || timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) ) )
if echo "$serip" | grep -q ':'; then
server_ip="[$serip]"
else
server_ip="$serip"
fi
echo "$server_ip" > "$HOME/agsbx/server_ip.log"
}
ipchange(){
v4v6
if [ -z "$v4" ]; then
vps_ipv4='无IPV4'
vps_ipv6="$v6"
location="$v6dq"
elif [ -n "$v4" ] && [ -n "$v6" ]; then
vps_ipv4="$v4"
vps_ipv6="$v6"
location="$v4dq"
else
vps_ipv4="$v4"
vps_ipv6='无IPV6'
location="$v4dq"
fi
echo
argosbxstatus
echo
echo "=========当前服务器本地IP情况========="
echo "本地IPV4地址：$vps_ipv4"
echo "本地IPV6地址：$vps_ipv6"
echo "服务器地区：$location"
echo
sleep 2
if [ "$ippz" = "4" ]; then
if [ -z "$v4" ]; then ipbest; else server_ip="$v4"; echo "$server_ip" > "$HOME/agsbx/server_ip.log"; fi
elif [ "$ippz" = "6" ]; then
if [ -z "$v6" ]; then ipbest; else server_ip="[$v6]"; echo "$server_ip" > "$HOME/agsbx/server_ip.log"; fi
else
ipbest
fi
}
ipchange
rm -rf "$HOME/agsbx/jh.txt"
uuid=$(cat "$HOME/agsbx/uuid")
server_ip=$(cat "$HOME/agsbx/server_ip.log")
sxname=$(cat "$HOME/agsbx/name" 2>/dev/null)
echo "*********************************************************"
echo "Argosbx脚本输出节点配置如下："
echo
cfip() { echo $((RANDOM % 13 + 1)); }

# vmess-ws 直连节点
if grep vmess-xr "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
if [ -n "$RAILWAY_PROJECT_ID" ]; then
echo "提示：Railway容器无公网入站IP，Vmess-ws直连节点不可用，已跳过；请启用 argo 使用Vmess-ws-argo节点"
echo
else
echo "💣【 Vmess-ws 】节点信息如下："
vmpt=$(cat "$HOME/agsbx/vmpt")
vm_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vm-ws-$hostname\", \"add\": \"$server_ip\", \"port\": \"$vmpt\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"www.bing.com\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vm_link" >> "$HOME/agsbx/jh.txt"
echo "$vm_link"
echo
fi
fi

# reality 节点
if grep reality-vision "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
vlpt=$(cat "$HOME/agsbx/vlpt")
public_key_x=$(cat "$HOME/agsbx/xrk/public_key" 2>/dev/null)
short_id_x=$(cat "$HOME/agsbx/xrk/short_id" 2>/dev/null)
reym=$(cat "$HOME/agsbx/reym" 2>/dev/null)
echo "💣【 Vless-tcp-reality-vision 】节点信息如下："
if [ -n "$rlyhost" ] && [ -n "$rlyport" ]; then
echo "注：地址与端口取自Railway TCP Proxy，须与容器内监听端口 $vlpt 对应"
vl_link="vless://$uuid@$rlyhost:$rlyport?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=tcp&headerType=none#${sxname}vl-reality-vision-$hostname"
else
echo "提示：未设置 rlyhost/rlyport（也未检测到Railway TCP Proxy变量），以下为占位符，请在Railway开启TCP Proxy（内部端口填 $vlpt）后重新部署"
echo "容器内监听端口：$vlpt"
vl_link="vless://$uuid@RAILWAY_TCP_PROXY_HOST:RAILWAY_TCP_PROXY_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=tcp&headerType=none#${sxname}vl-reality-vision-$hostname"
fi
echo "$vl_link" >> "$HOME/agsbx/jh.txt"
echo "$vl_link"
echo
fi

# argo 节点
argodomain=$(cat "$HOME/agsbx/sbargoym.log" 2>/dev/null)
[ -z "$argodomain" ] && argodomain=$(grep -a trycloudflare.com "$HOME/agsbx/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ -n "$argodomain" ]; then
echo "💣【 Vmess-ws-tls-argo 】节点信息如下："
echo "注：默认地址 yg数字.ygkkk.dpdns.org 可自行更换优选IP域名"
vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-443\", \"add\": \"yg1.ygkkk.dpdns.org\", \"port\": \"443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link1" >> "$HOME/agsbx/jh.txt"
vmatls_link2="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-8443\", \"add\": \"yg2.ygkkk.dpdns.org\", \"port\": \"8443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link2" >> "$HOME/agsbx/jh.txt"
vmatls_link3="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2053\", \"add\": \"yg3.ygkkk.dpdns.org\", \"port\": \"2053\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link3" >> "$HOME/agsbx/jh.txt"
vmatls_link4="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2083\", \"add\": \"yg4.ygkkk.dpdns.org\", \"port\": \"2083\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link4" >> "$HOME/agsbx/jh.txt"
vmatls_link5="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2087\", \"add\": \"yg5.ygkkk.dpdns.org\", \"port\": \"2087\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link5" >> "$HOME/agsbx/jh.txt"
vmatls_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2096\", \"add\": \"[2606:4700::0]\", \"port\": \"2096\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link6" >> "$HOME/agsbx/jh.txt"
echo
echo "💣【 Vmess-ws-argo (非TLS) 】节点信息如下："
vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-80\", \"add\": \"yg6.ygkkk.dpdns.org\", \"port\": \"80\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link7" >> "$HOME/agsbx/jh.txt"
vma_link8="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-8080\", \"add\": \"yg7.ygkkk.dpdns.org\", \"port\": \"8080\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link8" >> "$HOME/agsbx/jh.txt"
vma_link9="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-8880\", \"add\": \"yg8.ygkkk.dpdns.org\", \"port\": \"8880\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link9" >> "$HOME/agsbx/jh.txt"
vma_link10="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2052\", \"add\": \"yg9.ygkkk.dpdns.org\", \"port\": \"2052\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link10" >> "$HOME/agsbx/jh.txt"
vma_link11="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2082\", \"add\": \"yg10.ygkkk.dpdns.org\", \"port\": \"2082\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link11" >> "$HOME/agsbx/jh.txt"
vma_link12="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2086\", \"add\": \"yg11.ygkkk.dpdns.org\", \"port\": \"2086\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link12" >> "$HOME/agsbx/jh.txt"
vma_link13="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2095\", \"add\": \"[2400:cb00:2049::0]\", \"port\": \"2095\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link13" >> "$HOME/agsbx/jh.txt"

sbtk=$(cat "$HOME/agsbx/sbargotoken.log" 2>/dev/null)
if [ -n "$sbtk" ]; then
nametn="Argo固定隧道token：$sbtk"
fi
argoshow=$(
echo "Argo隧道端口正在使用Vmess-ws主协议端口：$(cat $HOME/agsbx/argoport.log 2>/dev/null)
Argo域名：$argodomain
$nametn

1、💣443端口的Vmess-ws-tls-argo节点(优选IP与443系端口随便换)
${vmatls_link1}

2、💣80端口的Vmess-ws-argo节点(优选IP与80系端口随便换)
${vma_link7}
"
)
fi
echo "---------------------------------------------------------"
echo "$argoshow"
echo
echo "---------------------------------------------------------"
echo "聚合节点信息，请进入 $HOME/agsbx/jh.txt 文件目录查看或者运行 cat $HOME/agsbx/jh.txt 查看"
echo "========================================================="
showmode
}

# ===== 主入口 =====
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' && ! pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1; then
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/agsbx/c|/agsbx/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null && echo "Killed $PID ($TARGET)" || echo "Could not kill $PID ($TARGET)"; fi; fi; done
kill -15 $(pgrep -f 'agsbx/x' 2>/dev/null) $(pgrep -f 'agsbx/c' 2>/dev/null) >/dev/null 2>&1

v4orv6(){
if [ -z "$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
if [ -n "$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
xsdns="[2001:4860:4860::8888]"
xryx="ForceIPv6v4"
else
xsdns="8.8.8.8"
xryx="ForceIPv4v6"
fi
}
v4orv6
echo "CPU架构：$cpu"
echo "Argosbx脚本未安装，开始安装…………" && sleep 2
ins
cip
echo
else
echo "Argosbx脚本已安装"
echo
argosbxstatus
echo
showmode
exit
fi
