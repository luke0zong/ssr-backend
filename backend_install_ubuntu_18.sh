#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cat << "EOF"
 _      __     ______   _      __  
| | /| / /__ _/ / / /  (_)__  / /__
| |/ |/ / _ `/ / / /__/ / _ \/  '_/
|__/|__/\_,_/_/_/____/_/_//_/_/\_\ 
                                  
EOF
echo "Proxy node server installation script for Ubuntu 18.04 x64"
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
echo "Press Y for continue the installation process, or press any key else to exit."
read is_install
if [[ is_install =~ ^[Y,y,Yes,YES]$ ]]
then
	echo "Bye"
	exit 0
fi
echo "Updatin exsit package..."
apt clean all && apt autoremove -y && apt update && apt upgrade -y && apt dist-upgrade -y
echo "Install necessary package..."
apt install git python-setuptools python-pip build-essential ntpdate htop -y
echo "Setting system timezone..."
cp -f /usr/share/zoneinfo/Asia/Taipei /etc/localtime && ntpdate us.pool.ntp.org
echo "Installing libsodium..."
wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
cd ../ && rm -rf libsodium*
echo "Installing Shadowsocksr server from GitHub..."
mkdir /soft && cd /soft
git clone -b manyuser https://github.com/esdeathlove/shadowsocks.git
cd shadowsocks
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
echo "Generating config file..."
cp apiconfig.py userapiconfig.py
cp config.json user-config.json
sed -i -e "s/'modwebapi'/'glzjinmod'/g" userapiconfig.py
echo -n "Please enter database server's IP address:"
read db_ip
echo -n "DB name:"
read db_name
echo -n "DB username:"
read db_user
echo -n "DB password:"
read db_password
echo -n "Server node ID:"
read node_id
echo "Writting config..."
sed -i -e "s/NODE_ID = 1/NODE_ID = ${node_id}/g" -e "s/MYSQL_HOST = '127.0.0.1'/MYSQL_HOST = '${db_ip}'/g" -e "s/MYSQL_USER = 'ss'/MYSQL_USER = '${db_user}'/g" -e "s/MYSQL_PASS = 'ss'/MYSQL_PASS = '${db_password}'/g" -e "s/MYSQL_DB = 'shadowsocks'/MYSQL_DB = '${db_name}'/g" userapiconfig.py
echo "Running system optimization and enable Google BBR..."
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
cat >> /etc/security/limits.conf << EOF
* soft nofile 51200
* hard nofile 51200
EOF
ulimit -n 51200
cat >> /etc/sysctl.conf << EOF
fs.file-max = 51200
net.core.default_qdisc = fq
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
EOF
sysctl -p
cd /soft/shadowsocks
echo "Installation complete, please run python server.py to test."
