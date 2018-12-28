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

echo "###4.安装k8s"
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

echo "###5.准备k8s.grc.io镜像"
docker pull $1:5000/kube-proxy:v1.12.2
docker tag $1:5000/kube-proxy:v1.12.2 k8s.gcr.io/kube-proxy:v1.12.2
docker rmi $1:5000/kube-proxy:v1.12.2
docker pull $1:5000/flannel:v0.10.0-amd64 
docker tag $1:5000/flannel:v0.10.0-amd64 quay.io/coreos/flannel:v0.10.0-amd64
docker rmi $1:5000/flannel:v0.10.0-amd64


echo "###6.添加node节点"
cat /root/kube-init.txt|grep "kubeadm join"|bash


