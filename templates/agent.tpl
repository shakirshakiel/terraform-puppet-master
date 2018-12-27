#!/bin/bash

cat <<EOF >/etc/environment
LANG=en_US.utf-8
LC_CTYPE=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

cat <<EOF >/root/.ssh/authorized_keys
${ssh_key}
${master_ssh_pub_key}
EOF

yum install -y https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
yum install -y puppet

cat <<EOF >>/etc/hosts
${puppet_master_ip} ${puppet_master_host}
EOF

cat <<EOF >/etc/puppetlabs/puppet/puppet.conf
[agent]
server = ${puppet_master_host}
EOF
