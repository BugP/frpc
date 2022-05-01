#! /usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin: ~ /bin
export PATH

# fonts color
Green= " \033[32m "
Red= " \033[31m "
Yellow= " \033[33m "
GreenBG= " \033[42;37m "
RedBG= " \033[41;37m "
Font= " \033[0m "
# fonts color

# variable
WORK_PATH= $( dirname $( readlink -f $0 ) )
FRP_NAME=frpc
FRP_VERSION=0.42.0
FRP_PATH=/usr/local/frp
PROXY_URL= " https://ghproxy.com/ "

# check frpc
if [ -f  " /usr/local/frp/ ${FRP_NAME} " ] || [ -f  " /usr/local/frp/ ${FRP_NAME} .ini " ] || [ -f  " /lib/systemd/system/ ${FRP_NAME} .service " ] ; then
    echo -e " ${Green} ========================================================================= ${Font} "
    echo -e " ${RedBG}当前已退出脚本. ${Font} "
    echo -e " ${Green}检查到服务器已安装${Font}  ${Red}${FRP_NAME}${Font} "
    echo -e " ${Green}请手动确认和删除${Font}  ${Red} /usr/local/frp/ ${Font}  ${Green}目录下的${Font}  ${Red}${FRP_NAME}${Font}  ${Green}和${Font}  ${Red} / ${FRP_NAME} .ini ${Font}  ${Green}文件以及${Font}  ${Red} /lib/systemd/system/ ${FRP_NAME} .service ${Font}  ${Green}文件,再次执行本脚本. ${Font} "
    echo -e " ${Green}参考命令如下: ${Font} "
    echo -e " ${Red} rm -rf /usr/local/frp/ ${FRP_NAME}${Font} "
    echo -e " ${Red} rm -rf /usr/local/frp/ ${FRP_NAME} .ini ${Font} "
    echo -e " ${Red} rm -rf /lib/systemd/system/ ${FRP_NAME} .service ${Font} "
    echo -e " ${Green} ========================================================================= ${Font} "
    exit 0
fi

while  !  test -z " $( ps -A | grep -w ${FRP_NAME} ) " ;  do
    FRPCPID= $( ps -A | grep -w ${FRP_NAME}  | awk ' NR==1 {print $1} ' )
    kill -9 $FRPCPID
done

# check pkg
if  type apt-get > /dev/null 2>&1  ;  then
    if  !  type wget > /dev/null 2>&1  ;  then
        apt-get install wget -y
    fi
    if  !  type curl > /dev/null 2>&1  ;  then
        apt-get install curl -y
    fi
fi

if  type yum > /dev/null 2>&1  ;  then
    if  !  type wget > /dev/null 2>&1  ;  then
        yum install wget -y
    fi
    if  !  type curl > /dev/null 2>&1  ;  then
        yum install curl -y
    fi
fi

# check network
GOOGLE_HTTP_CODE= $( curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w " %{http_code} "  " https://www.google.com " )
PROXY_HTTP_CODE= $( curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w " %{http_code} "  " ${PROXY_URL} " )

# check arch
if [ $( uname -m )  =  " x86_64 " ] ;  then
    PLATFORM=amd64
fi

if [ $( uname -m )  =  " aarch64 " ] ;  then
    PLATFORM=arm64
fi

FILE_NAME=frp_ ${FRP_VERSION} _linux_ ${PLATFORM}

# download
if [ $GOOGLE_HTTP_CODE  ==  " 200 " ] ;  then
    wget -P ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v ${FRP_VERSION} / ${FILE_NAME} .tar.gz -O ${FILE_NAME} .tar.gz
else
    if [ $PROXY_HTTP_CODE  ==  " 200 " ] ;  then
        wget -P ${WORK_PATH}  ${PROXY_URL} https://github.com/fatedier/frp/releases/download/v ${FRP_VERSION} / ${FILE_NAME} .tar.gz -O ${FILE_NAME} .tar.gz
    else
        echo -e " ${Red}检测GitHub Proxy 代理失效开始使用官方地址下载${Font} "
        wget -P ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v ${FRP_VERSION} / ${FILE_NAME} .tar.gz -O ${FILE_NAME} .tar.gz
    fi
fi
tar -zxvf ${FILE_NAME} .tar.gz

mkdir -p ${FRP_PATH}
mv ${FILE_NAME} / ${FRP_NAME}  ${FRP_PATH}

# configure frpc.ini
cat > ${FRP_PATH} / ${FRP_NAME} .ini << EOF
[common]
server_addr = frp.freefrp.net
server_port = 7000
token = freefrp.net
[web1_ ${RANDOM} ]
type = http
local_ip = 192.168.1.2
local_port = 5000
custom_domains = yourdomain ${RANDOM} .com
EOF

# configure systemd
cat > /lib/systemd/system/ ${FRP_NAME} .service << EOF
[Unit]
Description=Frp Server Service
After=network.target syslog.target
Wants=network.target
[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frp/ ${FRP_NAME} -c /usr/local/frp/ ${FRP_NAME} .ini
[Install]
WantedBy=multi-user.target
EOF

# finish install
systemctl daemon-reload
sudo systemctl start ${FRP_NAME}
sudo systemctl enable  ${FRP_NAME}

# clean
rm -rf ${WORK_PATH} / ${FILE_NAME} .tar.gz ${WORK_PATH} / ${FILE_NAME}  ${FRP_NAME} _linux_install.sh

echo -e " ${Green} ==================================================================== ${Font} "
echo -e " ${Green}安装成功,请先修改${FRP_NAME} .ini 文件,确保格式及配置正确无误! ${Font} "
echo -e " ${Red} vi /usr/local/frp/ ${FRP_NAME} .ini ${Font} "
echo -e " ${Green}修改完毕后执行以下命令重启服务: ${Font} "
echo -e " ${Red} sudo systemctl restart ${FRP_NAME}${Font} "
echo -e " ${Green} ==================================================================== ${Font} "