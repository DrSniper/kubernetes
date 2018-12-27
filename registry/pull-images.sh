#! /bin/bash
images=(kube-apiserver:v1.12.1 kube-controller-manager:v1.12.1 kube-scheduler:v1.12.1 kube-proxy:v1.12.1 pause:3.1 etcd:3.2.24 coredns:1.2.2 kubernetes-dashboard-amd64:v1.10.0)
for imageName in ${images[@]} ; do
  docker pull fingerliu/$imageName
  docker tag fingerliu/$imageName k8s.gcr.io/$imageName
  docker rmi fingerliu/$imageName
done
