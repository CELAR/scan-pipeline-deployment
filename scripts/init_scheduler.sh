#!/bin/bash -x

# Install NFS server
apt-get clean
apt-get update
apt-get -y install nfs-kernel-server portmap
#
# update system
#
apt-get -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -y upgrade
mkdir /mnt/nfs
chown nobody:nogroup /mnt/nfs


#
# enable NFS mount
#
for (( i=1; i <= `ss-get worker:multiplicity`; i++ )); do
  worker_ip=`ss-get --timeout 480 worker.$i:hostname`
  echo "/mnt/nfs     $worker_ip(rw,sync,no_subtree_check)" >> /etc/exports
done

exportfs -ra
service portmap restart
service nfs-kernel-server restart
ss-set scheduler.1:nfs_ready 1

apt-get -y install python python-pip python-dev git
pip install cql cherrypy

# Get the scheduler code etc:
cd ~
git clone https://github.com/smowton/scan.git

# Note the DB's master node address:
#ss-get cassandra-address > ~/scan/cassandra_address

# Create SSH keys and publish the public key for workers to use:
mkdir -p ~/.ssh
ssh-keygen -N "" -f ~/.ssh/id_rsa
ss-set authorized_keys `cat ~/.ssh/id_rsa.pub | base64 --wrap 0`

# Start the scheduler
~/scan/tinysched.py &
~/scan/await_server.py

# Note that we're ready
ss-set sched_address `ss-get hostname`

#
# Download files
#
#cd /mnt/nfs
#wget --output-document=Homo_sapiens.GRCh37.56.dna.chromosomes_and_MT.fa  https://pithos.okeanos.grnet.gr/public/AcXLjT5QacgAV0YaddjmN3 >/dev/null 2>&1
#wget --output-document=Homo_sapiens.GRCh37.56.dna.chromosomes_and_MT.fa.fai  https://pithos.okeanos.grnet.gr/public/Osk1Z7G2fKmF8rUNylLgD6 >/dev/null 2>&1
#wget --output-document=Homo_sapiens.GRCh37.56.dna.chromosomes_and_MT.dict  https://pithos.okeanos.grnet.gr/public/hUY61eW0zR4n61MP0h96q7 >/dev/null 2>&1
#wget --output-document=1kg.pilot_release.merged.indels.sites.hg19.human_g1k_v37.vcf  https://pithos.okeanos.grnet.gr/public/UKLZ9oHMljuaMFef3kkiv5 >/dev/null 2>&1
#wget --output-document=1kg.pilot_release.merged.indels.sites.hg19.human_g1k_v37.vcf.idx https://pithos.okeanos.grnet.gr/public/obxgOLCpLnCwwxpsdKtp26 >/dev/null 2>&1
#wget --output-document=dbsnp_138.hg19_with_b37_names.vcf https://pithos.okeanos.grnet.gr/public/xALZVZySqFSPlQteX0D757 >/dev/null 2>&1
#wget --output-document=dbsnp_138.hg19_with_b37_names.vcf.idx https://pithos.okeanos.grnet.gr/public/4CvOKo3SXiTtJ1emYMKrh6 >/dev/null 2>&1

ss-set sched_ready 1
