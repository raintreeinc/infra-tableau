#!/bin/bash

# Disable selinux
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config

# Install the AWS CLI and prerequisite packages for later
dnf install -y unzip sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python-utils jq git rpm-build make wget nfs-utils
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install -i /usr/local/aws-cli -b /usr/local/bin
rm -rf ./awscliv2.zip
rm -rf ./aws

# Steup the nvme share to be usable as swap and add it to fstab
parted /dev/nvme1n1 mklabel gpt
parted -a opt /dev/nvme1n1 mkpart primary xfs 0% 100%
mkfs.xfs /dev/nvme1n1p1
optid=`blkid -s UUID -o value /dev/nvme1n1p1`
fstabinfo="UUID=$optid\t/opt\txfs\tdefaults\t0\t0"
echo -e "$fstabinfo" >> /etc/fstab
mount -a remount

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
hostnamectl set-hostname $strhostname --static
instanceID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 create-tags --region $region --resources $instanceID --tags Key=Name,Value=$strhostname

# Build and install the EFS RPM
git clone https://github.com/aws/efs-utils
cd ~/efs-utils
make rpm
dnf -y install ~/efs-utils/build/amazon-efs-utils*rpm

# Run dnf updates
dnf update -y
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql13

# Join system to the domain
objSTSToken=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/rt-ec2-tableau`
export AWS_ACCESS_KEY_ID=$objSTSToken | jq -r .AccessKeyId
export AWS_SECRET_ACCESS_KEY=$objSTSToken | jq -r .SecretAccessKey
export AWS_DEFAULT_REGION=$region
export AWS_SESSION_TOKEN=$objSTSToken | jq -r .Token
objDomainInfo=`aws secretsmanager get-secret-value --secret-id "domainjoin"`
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

# Create data mount directory and mount efs share to it
objTableauInfo=`aws secretsmanager get-secret-value --secret-id "$prefix-$environment-bi-tableau"`
efs_data=`echo $objTableauInfo | jq -r .SecretString | jq -r .efs_id`
mount_ip=`aws efs describe-mount-targets --output text --file-system-id $efs_data --query "MountTargets[0].[IpAddress]"`
mkdir -p /data
efs_fstabinfo="$mount_ip:/\t/data\tnfs4\tnfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,nofail\t0\t0"
echo -e "$efs_fstabinfo" >> /etc/fstab
mount -a remount

# Download and install tableau
mkdir ~/downloads
wget https://downloads.tableau.com/esdalt/2022.1.4/tableau-server-2022-1-4.x86_64.rpm -P ~/downloads/
dnf install -y ~/downloads/tableau-server-2022-1-4.x86_64.rpm
aws s3 cp s3://$prefix-$environment-bi-tableau/config.json /opt/tableau/config.json

# Create Tableau setup script
core_key=`echo $objTableauInfo | jq -r .SecretString | jq -r .core_key`
db_user=`echo $objTableauInfo | jq -r .SecretString | jq -r .server_admin`
db_pass=`echo $objTableauInfo | jq -r .SecretString | jq -r .server_admin_pw`
tsm_admin=`echo $objTableauInfo | jq -r .SecretString | jq -r .tsm_admin`
tsm_pass=`echo $objTableauInfo | jq -r .SecretString | jq -r .tsm_admin_password`
json_data=$(cat <<EOF
{
  "flavor": "generic",
  "masterUsername": "$db_user",
  "host": "aurora-use1-dev-bi-tableau.cluster-csp9tzipbcew.us-east-1.rds.amazonaws.com",
  "port": 5432
}
EOF
)
echo "$json_data" >> /opt/tableau/dbconfig.json
cat <<EOT >> /opt/tableau/tableau.sh
#!/bin/bash
/opt/tableau/tableau_server/packages/scripts.20221.22.0712.0324/initialize-tsm --accepteula
sleep 180
source /etc/profile.d/tableau_server.sh
tsm licenses activate -k $core_key
tsm register --file /opt/tableau/config.json
sleep 180
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.20221.22.0712.0324/config.json
echo $db_pass | tsm topology external-services repository enable -f /opt/tableau/dbconfig.json --no-ssl
tsm configuration set -k gateway.trusted -v "3.219.54.181 44.195.175.101 184.72.160.208 54.156.128.95 3.221.148.57 54.156.110.250"
tsm configuration set -k gateway.public.host -v "tableau.dev.raintreeinc.com"
tsm configuration set -k gateway.trusted_hosts -v "tableau.dev.raintreeinc.com"
tsm configuration set -k gateway.public.port -v "443"
tsm pending-changes apply
tsm initialize --start-server --request-timeout 1800
echo $tsm_pass | tabcmd initialuser --server http://localhost --username $tsm_admin
TOKEN=\`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"\`
region=\`curl -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone | rev | cut -c2- | rev\`
objSTSToken=\`curl -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/rt-ec2-tableau\`
export AWS_ACCESS_KEY_ID=\$objSTSToken | jq -r .AccessKeyId
export AWS_SECRET_ACCESS_KEY=\$objSTSToken | jq -r .SecretAccessKey
export AWS_DEFAULT_REGION=\$region
export AWS_SESSION_TOKEN=\$objSTSToken | jq -r .Token
instanceID=\`curl -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/instance-id\`
aws ec2 create-tags --region \$region --resources \$instanceID --tags Key=TableauReady,Value=True
EOT
chmod +x /opt/tableau.sh

# Set ready tag and then reboot server
aws ec2 create-tags --region $region --resources $instanceID --tags Key=ReadyForUse,Value=True
reboot