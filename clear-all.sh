#!/bin/bash

systemctl stop kubelet
systemctl stop docker 

yum remove -y kubelet kubeadm kubectl
yum remove -y docker-ce

rm -fr /root/.kube
rm -fr /var/lib/etcd
rm -fr /var/lib/kubelet
rm -fr /etc/kubernetes/

rm -fr /var/lib/docker 
rm -fr /etc/docker 

###########################################3
cat clear-all.sh 
#systemctl stop docker.service
#service docker stop
#yum remove -y docker-engine
#dpkg -r docker-engine

for i in 1 2 3
do
    kubeadm reset -f
    kubeadm reset -f
    kubeadm reset -f
    systemctl daemon-reload
    systemctl stop kubelet
    ip link set flannel.1 down
    ip link set cni0 down
    ip link delete flannel.1
    ip link delete cni0
    ip link set kube-ipvs0
    ip link delete kube-ipvs0
    ip link set dummy0 down
    ip link delete dummy0 
    ip link set tunl0 down
    ip link delete tunl0
done
systemctl stop kubelet.service
systemctl stop dirge.service
systemctl stop postfix.service
systemctl disable kubelet.service
systemctl disable dirge.service
systemctl disable postfix.service
docker rm -f $(docker ps -qa)
systemctl stop docker
df -l --output=target |grep ^/var/lib/kubelet |grep subpath | xargs -r umount
df -l --output=target |grep ^/var/lib/kubelet | xargs -r umount
rm -rf /etc/systemd/system/kubelet.service
rm -rf /usr/local/bin/kubelet
rm -rf /usr/local/bin/kubeadm
rm -rf /usr/local/bin/kubectl
rm -rf /usr/local/sbin/kubelet
rm -rf /usr/local/sbin/kubeadm
rm -rf /usr/local/sbin/kubectl
rm -rf /etc/kube*
rm -rf /var/lib/etcd
rm -rf /opt/cni/bin
rm -rf $HOME/.kube
rm -rf $HOME/.helm
rm -rf /root/.helm
rm -rf /root/.kube
rm -rf /alauda/*
rm -rf /etc/etcd
rm -rf /var/lib/etcd
rm -rf /var/log/spectre/*
rm -rf /tmp/mesos
rm -rf /tmp/hbase
rm -rf /var/log/mesos
rm -rf /var/log/mathilde/*
#rm -rf /var/run/docker
#rm -rf /etc/default/docker
rm -rf /var/log/upstart/docker*
rm -rf /var/lib/cni/*
rm -rf /etc/cni/net.d/*
rm -rf /var/lib/kubelet/*
rm -rf /run/flannel/*
rm -rf /root/.ssh1
rm -rf /var/lib/etcd

#rm -rf /etc/docker/*
#rm -rf /var/lib/docker/*
#rm -rf /var/lib/dockershim
#rm -rf /etc/init/docker.conf
#rm -rf /etc/init.d/docker
#reboot
#exit
