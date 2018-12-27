#! /bin/bash
USERNAME=sniperwang
LOCALIP=`hostname -i`
images=(kube-apiserver:v1.12.2 kube-controller-manager:v1.12.2 kube-scheduler:v1.12.2 kube-proxy:v1.12.2 pause:3.1 etcd:3.2.24 coredns:1.2.2 kubernetes-dashboard-amd64:v1.10.0)
for imageName in ${images[@]} ; do
  docker pull $USERNAME/$imageName
  docker tag $USERNAME/$imageName k8s.gcr.io/$imageName
  docker tag $USERNAME/$imageName $LOCALIP:5000/$imageName
  docker push $LOCALIP:5000/$imageName
  docker rmi $USERNAME/$imageName
done
