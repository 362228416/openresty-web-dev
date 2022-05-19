#!/bin/bash
sudo apt-get update
sudo apt-get install -y libpcre3 libpcre3-dev
sudo apt-get install -y openssl libssl-dev
sudo apt-get install -y openssl zlib1g-dev
cd /tmp
version="1.19.9.1"
name=openresty-$version
file=$name.tar.gz
prefix=/usr/local/openresty
#echo $file
wget https://openresty.org/download/$file
tar zxvf $file
cd $name
./configure --with-http_stub_status_module --with-http_realip_module
make -j2
sudo make install
sudo ln -s $prefix/nginx/sbin/nginx /usr/local/sbin/openresty
