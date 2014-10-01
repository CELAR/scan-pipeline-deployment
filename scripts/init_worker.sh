#!/bin/bash -x


apt-get clean
apt-get update
apt-get -y install nfs-common portmap
#
# update system
#
apt-get -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -y upgrade
mkdir /mnt/nfs

# Wait for the scheduler to start NFS server:
RDY1=`ss-get scheduler.1:nfs_ready`
while [ $RDY1 != "1" ]; do
    echo "Waiting for the scheduler..."
    sleep 1
    RDY1=`ss-get scheduler.1:nfs_ready`
done
mount -t nfs `ss-get --timeout 480 scheduler.1:hostname`:/mnt/nfs /mnt/nfs

apt-get -y install default-jre git python

# Fetch the GATK:
mkdir ~/gatk
cd ~/gatk
wget http://cs448.user.srcf.net/GenomeAnalysisTK.jar

# Fetch the SCAN ps agent:
cd ~
git clone https://github.com/smowton/scan.git

# Fetch JCatascopia standard probes, etc.
# Not implemented yet
# Wait for the scheduler:
RDY2=`ss-get scheduler.1:sched_ready`
while [ $RDY2 != "1" ]; do
    echo "Waiting for the scheduler..."
    sleep 1
    RDY2=`ss-get scheduler.1:sched_ready`
done

# Enable passwordless SSH access (for example?)
mkdir ~/.ssh

echo `ss-get scheduler.1:authorized_keys | base64 -d` >> ~/.ssh/authorized_keys

# Machine is now ready to be a GATK worker. Register it:
SCHED_ADDRESS=`ss-get scheduler.1:sched_address`
# This might be tricky: discover my own class. The orchestrator knew this, and somehow needs to get that information through to the Slipstream phase.
WORKER_CLASS=`ss-get nodename`
ME=`ss-get hostname`
~/scan/register_worker.py $SCHED_ADDRESS $WORKER_CLASS
