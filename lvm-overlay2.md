## 不重启显示添加磁盘
```
echo "- - -" >  /sys/class/scsi_host/host0/scan
echo "- - -" >  /sys/class/scsi_host/host1/scan
echo "- - -" >  /sys/class/scsi_host/host2/scan
```
```
for host in $(ls /sys/class/scsi_host) ; do echo "- - -" > /sys/class/scsi_host/$host/scan; done
for scsi_device in $(ls /sys/class/scsi_device/); do echo 1 > /sys/class/scsi_device/$scsi_device/device/rescan; done
lsblk

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
