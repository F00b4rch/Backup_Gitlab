#!/bin/bash
#===============================================================================
#
#          FILE: gitlab_backup.sh
#
#         USAGE: ./gitlab_backup.sh
#
#   DESCRIPTION: backup gitlab config & dirs
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Corentin
#  ORGANIZATION: 
#       CREATED: 06/06/2017 10:29:58
#      REVISION:  ---
#===============================================================================


########
# VARS #
########
USER=""
DATE=`date +%d-%m-%Y`
FMTDATE=`date +%Y_%m_%d`
spPort='' # SSH PORT REMOTE
spUsr=''  # USER REMOTE
spPath='' # PATH REMOTE
spIP=''

# Preventing root running
if [[ $EUID -eq 0 ]]; then
  echo "This script must NOT be run as root" 1>&2
  exit 1
fi

cd /home/$USER/
mkdir $DATE

gitlBck() {

    # Backups are made in this path :
    # /var/opt/gitlab/backups/
    cd /home/$USER/
    sudo gitlab-rake gitlab:backup:create
    bckFile=`sudo ls /var/opt/gitlab/backups/ | grep $FMTDATE`
    sudo mv /var/opt/gitlab/backups/$bckFile /home/$USER/$DATE/    

}

gitCfgBck() {
     
    cd /home/$USER/
    sudo sh -c 'umask 0077; tar -cf $(date "+etc-gitlab-%d-%m-%Y.tar") -C / etc/gitlab'
    sudo mv /home/$USER/etc-gitlab-$DATE.tar /home/$USER/$DATE
    
    # Restoring :
    # - sudo mv /etc/gitlab /etc/gitlab.$(date +%d-%m-Y)
    # - sudo tar -xf etc-gitlab-YOUR_DATE_HERE.tar -C /
    # - sudo gitlab-ctl reconfigure

}

gitlBck
gitCfgBck

sudo chown -R $USER:$USER $DATE

# scp vers le serveur de backup
ssh -t $spUsr@$spIP -p$spPort -i "/home/$USER/.ssh/id_rsa" "sudo mkdir -p $spPath/$DATE && sudo chown -R $spUsr:$spUsr $spPath"
sudo scp -r "-P$spPort" -i /home/$USER/.ssh/id_rsa $DATE $spUsr@$spIP:$spPath

rm -rf $DATE
