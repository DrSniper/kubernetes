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
