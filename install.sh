#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

LANG=en_US.UTF-8
setup_path="/rancher"
getIpAddress="SERVER_IP"
panelPort="888"
panelHttpsPort="8888"

Install_Docker(){
    # step 1: 安装必要的一些系统工具
    yum install -y yum-utils device-mapper-persistent-data lvm2
    # Step 2: 添加软件源信息
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    # Step 3: 更新并安装 Docker-CE
    yum makecache fast
    yum -y install docker-ce
    # Step 4: 开启Docker服务
    service docker start
    # 设置开机启动
    systemctl enable docker
}

Set_Docker(){
    # 设置docker日志大小
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": ["https://za6g16o8.mirror.aliyuncs.com"],
    "log-driver":"json-file",
    "log-opts":{ "max-size" :"50m","max-file":"3"}
}
EOF
    systemctl daemon-reload
    systemctl restart docker
}

Install_NTP() {
    yum install ntp ntpdate -y
    tee /etc/ntp.conf <<-'EOF'
server ntp3.aliyun.com iburst
EOF
    service ntpd restart
    systemctl disable chronyd.service
    chkconfig --level 345 ntpd on
    ntpq -p
}

Set_System(){
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    # 关闭防火墙
    systemctl stop firewalld.service && systemctl disable firewalld.service
}

Install_open_iscsi(){
    yum install iscsi-initiator-utils -y
}

Install_rancher(){
    docker run -d --restart=unless-stopped \
    -p 80:$panelPort -p 443:$panelHttpsPort \
    -v $setup_path:/var/lib/rancher \
    rancher/rancher:latest
}
Install_Main(){
    echo -e "\033[32m=== start install ===\033[0m"
    startTime=`date +%s`
    Install_Docker
    Set_Docker
    Set_System
    Install_open_iscsi
    Install_rancher
}

echo "
+----------------------------------------------------------------------
| Gomsa 7.0 FOR CentOS/Ubuntu/Debian
+----------------------------------------------------------------------
| Copyright © 2019-2099 gomsa(http://www.lece.vip) All rights reserved.
+----------------------------------------------------------------------
| The WebPanel URL will be http://SERVER_IP:8888 when installed.
+----------------------------------------------------------------------
"
while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "Do you want to install rancher to the $setup_path directory now?(y/n): " go;
done

if [ "$go" == 'n' ];then
	exit;
fi

Install_Main

echo -e "=================================================================="
echo -e "\033[32mCongratulations! Installed successfully!\033[0m"
echo -e "=================================================================="
echo  "rancher-Panel: http://${getIpAddress}:${panelPort}"
# echo -e "username: $username"
# echo -e "password: $password"
echo -e "=================================================================="

endTime=`date +%s`
((outTime=($endTime-$startTime)/60))
echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"