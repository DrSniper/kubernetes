## 不重启显示添加磁盘
```shell
echo "- - -" >  /sys/class/scsi_host/host0/scan
echo "- - -" >  /sys/class/scsi_host/host1/scan
echo "- - -" >  /sys/class/scsi_host/host2/scan
```
```
for host in $(ls /sys/class/scsi_host) ; do echo "- - -" > /sys/class/scsi_host/$host/scan; done
for scsi_device in $(ls /sys/class/scsi_device/); do echo 1 > /sys/class/scsi_device/$scsi_device/device/rescan; done
lsblk

```
### lvm创建
```shell
# 1. 先提前准备一块待添加的磁盘，例如/dev/sdb
# 2 创建物理卷pv(physical volume) 
[root@centos ~]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@centos ~]# pvs
  PV         VG            Fmt  Attr PSize  PFree
  /dev/sda2  centos_centos lvm2 a--  19.80g    0 
  /dev/sdb                 lvm2 ---   5.00g 5.00g
# 3. 创建卷组vg(volume group)卷组名为test-vg
[root@centos ~]# vgcreate test_vg /dev/sdb
  Volume group "test_vg" successfully created
[root@centos ~]# vgs
  VG            #PV #LV #SN Attr   VSize  VFree
  centos_centos   1   2   0 wz--n- 19.80g    0 
  test_vg         1   1   0 wz--n- <5.00g 2.50g
# 4. 创建逻辑卷lv(logical volume),逻辑卷名称为test_lv
[root@centos ~]# lvcreate -n test_lv -l 95%FREE test_vg
  Logical volume "test_lv" created.
[root@centos ~]# lvs
  LV      VG            Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root00  centos_centos -wi-ao---- 15.80g                                                    
  swap    centos_centos -wi-ao----  4.00g                                                    
  test_lv test_vg       -wi-a----- <2.50g   
[root@centos ~]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   20G  0 disk 
├─sda1                     8:1    0  200M  0 part /boot
└─sda2                     8:2    0 19.8G  0 part 
  ├─centos_centos-root00 253:0    0 15.8G  0 lvm  /
  └─centos_centos-swap   253:1    0    4G  0 lvm  [SWAP]
sdb                        8:16   0    5G  0 disk 
└─test_vg-test_lv        253:2    0  2.5G  0 lvm  
sr0                       11:0    1 1024M  0 rom  
# 5. 格式化lv
[root@centos ~]# mkfs.xfs /dev/test_vg/test_lv 
meta-data=/dev/test_vg/test_lv   isize=512    agcount=4, agsize=163584 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=654336, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
# 6. 挂载lv
[root@centos ~]# mount /dev/test_vg/test_lv /mnt
[root@centos mnt]# df -hT
Filesystem                       Type      Size  Used Avail Use% Mounted on
devtmpfs                         devtmpfs  979M     0  979M   0% /dev
tmpfs                            tmpfs     991M     0  991M   0% /dev/shm
tmpfs                            tmpfs     991M  9.6M  981M   1% /run
tmpfs                            tmpfs     991M     0  991M   0% /sys/fs/cgroup
/dev/mapper/centos_centos-root00 xfs        16G  2.0G   14G  13% /
/dev/sda1                        xfs       197M  141M   57M  72% /boot
tmpfs                            tmpfs     199M     0  199M   0% /run/user/0
/dev/mapper/test_vg-test_lv      xfs       2.5G   33M  2.5G   2% /mnt
# 7. 开机挂载
# vi /etc/fstab 在最后新增
/dev/test_vg/test_lv /mnt      xfs     defaults        0 0

```
1. mkfs.xfs -n ftype=1 /dev/sdb
2. mount /dev/sdb /var/lib/docker/
3. 将挂载信息写入/etc/fstab
`/dev/sdb /var/lib/docker   xfs defaults 0 0`
4. 修改damon.json
```
{
    "insecure-registries": [
        "192.168.0.4:60080",
        "",
        ""
    ],
    "storage-driver": "overlay2"
}
```
