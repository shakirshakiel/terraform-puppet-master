#!/bin/bash

setenforce Permissive

cat <<EOF >/etc/environment
LANG=en_US.utf-8
LC_CTYPE=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

cat <<EOF >/root/.ssh/authorized_keys
${ssh_key}
EOF

yum install -y https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
yum install -y puppetserver puppet-bolt

sed -i -e 's/User=puppet/User=root/' /usr/lib/systemd/system/puppetserver.service

systemctl start puppetserver

cat <<EOF >/etc/puppetlabs/puppet/puppet.conf
[agent]
server = ${puppet_master_host}
environment = ${puppet_environment}
[master]
autosign = true
user = root
EOF

cat <<EOF >/root/.ssh/id_rsa
${root_private_key}
EOF
chmod 600 /root/.ssh/id_rsa

cat <<EOF >/root/.ssh/id_rsa.pub
${root_public_key}
EOF

systemctl restart puppetserver

yum install -y ruby git lsof
gem install r10k -v 2.6.4

cat <<EOF >/root/r10k.yaml
sources:
  main:
    # where will the control repo be stored?
    remote: 'https://github.com/shakirshakiel/control-repo.git'
    basedir: '/etc/puppetlabs/code/environments'
EOF

r10k deploy environment ${puppet_environment} --puppetfile -c /root/r10k.yaml -v info

mkdir -p /root/.puppetlabs/bolt
cat <<EOF >/root/.puppetlabs/bolt/bolt.yaml
modulepath: /etc/puppetlabs/code/environments/${puppet_environment}/site/
ssh:
  host-key-check: false
  private-key: /root/.ssh/id_rsa
EOF
