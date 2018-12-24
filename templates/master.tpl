#!/bin/bash

cat <<EOF >/etc/environment
LANG=en_US.utf-8
LC_CTYPE=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

cat <<EOF >/root/.ssh/authorized_keys
${ssh_key}
EOF

yum install -y https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
yum install -y puppetserver

systemctl start puppetserver

cat <<EOF >/etc/puppetlabs/puppet/puppet.conf
[agent]
server = ${puppet_master_host}
[master]
autosign = true
EOF

systemctl restart puppetserver

yum install -y ruby git
gem install r10k -v 2.6.4

cat <<EOF >/root/r10k.yaml
sources:
  main:
    # where will the control repo be stored?
    remote: 'https://github.com/shakirshakiel/control-repo.git'
    basedir: '/etc/puppetlabs/code/environments'
EOF

r10k deploy environment production --puppetfile -c /root/r10k.yaml -v info