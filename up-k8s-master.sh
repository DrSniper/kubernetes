#!/bin/bash
read -p "是否添加node节点：yes  /   no:  " CHOICE
if [ $CHOICE == 'yes' ];then
	read -p "请输入需要添加的主机ip，用' '(空格)隔开： " NODE_IP
	read -p  "请输入node节点的密码：" NODE_PASSWD
fi
echo "###1.系统准备"

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux



iptables -F
iptables -t nat -F
iptables -I FORWARD -s 0.0.0.0/0 -d 0.0.0.0/0 -j ACCEPT  

cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
vm.swappiness=0
EOF

sysctl -p /etc/sysctl.d/k8s.conf

swapoff -a 



echo "####2.安装相关软件包"
yum install -y yum-utils sshpass device-mapper-persistent-data lvm2

echo "###3.安装docker"
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum makecache fast

yum install -y --setopt=obsoletes=0 \
  docker-ce-18.06.1.ce-3.el7

systemctl start docker
systemctl enable docker

echo "###4.添加docker镜像仓库加速"

sudo mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json 
{
  "insecure-registries": ["`hostname -i`:5000"],
"registry-mirrors": ["https://ran9u71w.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "###5.安装k8s"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl-1.12.2-0 kubelet-1.12.2-0 kubeadm-1.12.2-0
systemctl enable kubelet && systemctl start kubelet

echo "###6.准备k8s.grc.io镜像"
docker run -d -p 5000:5000 --restart=always --name registry docker.io/registry
docker pull sniperwang/flannel:v0.10.0-amd64 
docker tag  sniperwang/flannel:v0.10.0-amd64 quay.io/coreos/flannel:v0.10.0-amd64
docker tag sniperwang/flannel:v0.10.0-amd64 `hostname -i`:5000/flannel:v0.10.0-amd64 
docker push `hostname -i`:5000/flannel:v0.10.0-amd64 

bash kubernetes/registry/master-pull-images.sh

docker images

cat << EOF > node-pull-images.sh
#! /bin/bash
USERNAME=`hostname -i`
images=(kube-apiserver:v1.12.2 kube-controller-manager:v1.12.2 kube-scheduler:v1.12.2 kube-proxy:v1.12.2 pause:3.1 etcd:3.2.24 coredns:1.2.2 kubernetes-dashboard-amd64:v1.10.0)
for imageName in ${images[@]} ; do
  docker pull $USERNAME/$imageName
  docker tag $USERNAME/$imageName k8s.gcr.io/$imageName
  docker rmi $USERNAME/$imageName
done
EOF

echo "###7.初始化master节点"
kubeadm init \
  --kubernetes-version=v1.12.2 \
  --pod-network-cidr=10.254.0.0/16 \
  --apiserver-advertise-address=`hostname -i` >kube-init.txt

echo "###8.使master节点 ready"
 mkdir -p $HOME/.kube
 sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 sudo chown $(id -u):$(id -g) $HOME/.kube/config
 

echo "###9.将master节点同时设置为计算节点"
kubectl taint nodes `hostname` node-role.kubernetes.io/master-

echo "###10.添加网络插件[fannel]"
kubectl apply -f  kubernetes/yaml/k8s-base-plugins/flannel.yaml
sleep 50

echo "###11.安装dashboard"
kubectl apply -f  kubernetes/yaml/k8s-base-plugins/k8s-dashboard.yaml 
sleep 10

echo "StrictHostKeyChecking no" >>/etc/ssh/ssh_config
if [ $CHOICE == 'yes' ];then
	 echo "###12.添加node节点"
	 for i in $NODE_IP
	 do
	 	sshpass -p "$NODE_PASSWD" ssh root@$i "mkdir -p /etc/docker/"
		sshpass -p "$NODE_PASSWD" scp /etc/docker/daemon.json root@$i:/etc/docker 
	 	sshpass -p "$NODE_PASSWD" scp kubernetes/up-k8s-node.sh root@$i:/root
		sshpass -p "$NODE_PASSWD" scp node-pull-images.sh root@$i:/root
	 	sshpass -p "$NODE_PASSWD" scp kube-init.txt root@$i:/root
	 	sshpass -p "$NODE_PASSWD" ssh root@$i "bash up-k8s-node.sh"
		sleep 50
	 done
fi

echo "###13.检查服务状态"
kubectl get nodes
kubectl get pods --all-namespaces

echo "###14.访问"
echo -e "请使用火狐浏览器访问dashboard界面：\n https://`hostname -i`:30001 "
SECRET=`kubectl get secret -n kube-system|grep dashboard-token|awk '{print $1}'`
TOKEN=`kubectl describe secret -n kube-system $SECRET|grep "token:"|awk '{print $2}'`
echo -e "选择token方式访问，token为：\n $TOKEN"
