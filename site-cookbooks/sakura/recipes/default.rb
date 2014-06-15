#
# Cookbook Name:: sakura
# Recipe:: default
#
# Copyright 2014, Yusuke Higaki
#
# All rights reserved - Do Not Redistribute
#

user = Chef::EncryptedDataBagItem.load("user", 'yusuke')

# 日本語化
template "/etc/sysconfig/i18n" do
    owner "root"
    group "root"
    mode 0644
end

# ユーザーを作成する
user user['name'] do
    password user['password']
    supports :manage_home => true
    action :create
end

# wheelグループに追加
group "wheel" do
    action :modify
    members [user['name']]
end

# wheelグループにsudo権限を付与
template "/etc/sudoers" do
    owner "root"
    group "root"
    mode 0440
end

# 鍵認証をできるようにする
directory "/home/" + user['name'] + "/.ssh" do
    owner user['name']
    group user['name']
    mode 0700
    action :create
end

cookbook_file "/home/" + user['name'] + "/.ssh/authorized_keys" do
    owner user['name']
    group user['name']
    mode 0600
end

# ポート番号の変更、パスードログインの禁止、rootログインの禁止
service "sshd" do
    action [:start, :enable]
    supports :status => true, :restart => true, :reload => true
end

template "/etc/ssh/sshd_config" do
    owner "root"
    group "root"
    notifies :reload, 'service[sshd]'
end

# ファイヤーウォールの設定
template "/etc/sysconfig/iptables" do
    owner "root"
    group "root"
end

service "iptables" do
    action [:start, :enable]
    supports :status => true, :restart => true, :reload => true
end

# Apach、PHP、MySqlのインストール
%w{vim-enhanced php mysql-server httpd}.each do |p|
    package p do
    action :install
    end
end

service "httpd" do
    action [:start, :enable]
    supports :status => true, :restart => true, :reload => true
end

# apacheの設定
template "/etc/httpd/conf/httpd.conf" do
    mode 0644
    notifies :restart, 'service[httpd]'
end

# PHPの設定
template "/etc/php.ini" do
    mode 0644
    notifies :restart, 'service[httpd]'
end

# MySQLの設定
service "mysqld" do
    action [:start, :enable]
    supports :status => true, :restart => true, :reload => true
end

template "/etc/my.cnf" do
    mode 0644
    notifies :restart, 'service[mysqld]'
end

# ドキュメントルートをuser['name']ユーザーでもつくれるようにする
execute "chown -R user['name']:user['name'] /var/www/html/" do
    command "chown -R " + user['name'] + ":" + user['name'] + " /var/www/html/"
end

# index.htmlの設置
template "/var/www/html/index.html" do
    owner "root"
    group "root"
    mode 0644
end


