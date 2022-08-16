#!/bin/bash

# Disable selinux
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config

# Install the AWS CLI and prerequisite packages for later
dnf install -y unzip sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python-utils jq git rpm-build make wget
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install -i /usr/local/aws-cli -b /usr/local/bin
rm -rf ./awscliv2.zip
rm -rf ./aws

# Steup the nvme share to be usable as swap and add it to fstab
parted /dev/nvme1n1 mklabel gpt
parted -a opt /dev/nvme1n1 mkpart primary linux-swap 0% 100%
mkswap /dev/nvme1n1p1
swapon /dev/nvme1n1p1
swapid=`blkid -s PARTUUID -o value /dev/nvme1n1p1`
fstabinfo="UUID=$swapid\tswap\tswap\tdefaults\t0\t0"
echo -e "$fstabinfo" >> /etc/fstab

# Set hostname on system
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
domain=`cat /etc/resolv.conf | grep raintreeinc.internal | awk '{ print substr( $0, 8 ) }'`
environment=`echo $domain | cut -c 1-3`
region=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone | rev | cut -c2- | rev`
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
instanceid=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
shortid=${instanceid: -4}
strhostname=$prefix$environment$servertype$shortid
hostnamectl set-hostname $strhostname.$domain --static
instanceID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 create-tags --region $region --resources $instanceID --tags Key=Name,Value=$strhostname

# Build and install the EFS RPM
git clone https://github.com/aws/efs-utils
cd ~/efs-utils
make rpm
dnf -y install ~/efs-utils/build/amazon-efs-utils*rpm

# Create data mount directory and mount efs share to it
mkdir -p /data
mount -t efs -o tls fs-0e1e94d5d105e5f6d:/ efs

# Run dnf updates
dnf update -y
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql13-server
/usr/pgsql-13/bin/postgresql-13-setup initdb
systemctl enable postgresql-13
systemctl start postgresql-13

# Join system to the domain
objSTSToken=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/rt-ec2-tableau`
export AWS_ACCESS_KEY_ID=$objSTSToken | jq -r .AccessKeyId
export AWS_SECRET_ACCESS_KEY=$objSTSToken | jq -r .SecretAccessKey
export AWS_DEFAULT_REGION=$region
export AWS_SESSION_TOKEN=$objSTSToken | jq -r .Token
objDomainInfo=aws secretsmanager get-secret-value --secret-id "domainjoin"
user=`echo $objDomainInfo | jq -r .SecretString | jq -r .username`
pass=`echo $objDomainInfo | jq -r .SecretString | jq -r .password`
domain=`echo $objDomainInfo | jq -r .SecretString | jq -r .domain`
realm discover --server-software=active-directory
username=`echo $user | cut -d '@' -f1`
domain_upper=`echo $user | cut -d '@' -f2 | tr '[:lower:]' '[:upper:]'`
kuser=`echo $username@$domain_upper`
echo $pass | kinit $kuser
echo $pass | realm join $domain_upper -U $kuser --client-software=sssd
systemctl enable sssd

# Download and install tableau
mkdir ~/downloads
wget https://downloads.tableau.com/esdalt/2022.1.4/tableau-server-2022-1-4.x86_64.rpm -P ~/downloads/
dnf -y install ~/downloads/tableau-server-2022-1-4.x86_64.rpm
mkdir -p /app/tableau_server
rpm -i --prefix /app/tableau_server ~/downloads/tableau-server-2022-1-4.x86_64.rpm

# Set ready tag on instance and then reboot
aws ec2 create-tags --region $region --resources $instanceID --tags Key=ReadyForUse,Value=True
reboot