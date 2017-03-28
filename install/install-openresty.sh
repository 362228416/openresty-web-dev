#!/bin/bash
apt-get update
apt-get install -y libpcre3 libpcre3-dev
apt-get install -y openssl libssl-dev
cd /tmp
version="1.11.2.2"
name=openresty-$version
file=$name.tar.gz
prefix=/usr/local/openresty
#echo $file
wget https://openresty.org/download/$file
tar zxvf $file
cd $name
./configure
make -j2
make install
ln -s $prefix/nginx/sbin/nginx /usr/local/sbin/openresty
