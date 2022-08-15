#!/bin/bash -xe
domain=`cat /etc/resolv.conf | grep raintreeinc.internal | awk '{ print substr( $0, 8 ) }'`
environment=`echo $domain | cut -c 1-3`
region=`curl http://169.254.169.254/latest/meta-data/placement/availability-zone | rev | cut -c2- | rev`
case $region in
  us-east-1)
    prefix="use1"
    timedatectl set-timezone America/New_York
    ;;
  us-east-2)
    prefix="use2"
    timedatectl set-timezone America/New_York
    ;;
  us-west-2)
    prefix="usw2"
    timedatectl set-timezone America/Los_Angeles
    ;;
  ap-south-1)
    prefix="aps1"
    timedatectl set-timezone Asia/Kolkata
    ;;
  eu-north-1)
    prefix="eun1"
    timedatectl set-timezone Europe/Stockholm
    ;;
  *)
    prefix="use1"
    timedatectl set-timezone America/New_York
    ;;
esac
servertype="tab"
instanceid=`curl http://169.254.169.254/latest/meta-data/instance-id`
shortid=${instanceid: -4}
strhostname=$prefix$environment$servertype$shortid
hostnamectl set-hostname $strhostname.$domain --static
instanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 create-tags --region us-east-1 --resources $instanceID --tags Key=Name,Value=$strhostname
aws ec2 create-tags --region us-east-1 --resources $instanceID --tags Key=ReadyForUse,Value=True
dnf update
dnf upgrade --refresh
dnf install -y dnf-plugin-system-upgrade
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql13-server
/usr/pgsql-13/bin/postgresql-13-setup initdb
systemctl enable postgresql-13
systemctl start postgresql-13
reboot