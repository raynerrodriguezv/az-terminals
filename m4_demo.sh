
#attach the new disk
az vm disk attach \
    --resource-group "psdemo-rg" \
    --vm-name "psdemo-linux-1c"
    --disk "psdemo-lunux-1c-st0" \
    --new \
    --size-gb 25 \
    --sku "premium_LRS" #other options are standardSSD_LRS and standard_LRS


az vm list-ip-addresses \
    --name "psdemo-linux-1c" \
    --output table

ssh -l user IP


lsblk



#we can also use dmesg, like docs.microsft.com says...
dmesg | grep SCSI

# particion the disk with fdisk and use the following commands to name  a new primary particion 

sudo fdisk /dev/sdc
m
n
p
1
w

#format the new partition with ext4
sudo mkfs -t ext4 /dev/sdc1

#6 make a directory to mount the new disk under
sudo mkdir /data1

# add the follow line to /etc/fstab. first find the  uuid for te device
sudo -i blkid | grep sdc1


uuid = ?        /data1 ext4 defaults        0 0
sudo vi /etc/fstab

# mount the volume and verify the file system is mounted

sudo mount -a
df -h


#from VM
exit




# para cambiarle el size a los disk es necesario deallocate

#resising a disk
az vm deallocate \
    --resource-group "psdemo-rg"
    --name "psdemo-linux-1c"

az disk list \
    --output table



#3 update the disk's size to the desired size
az disk update \
    --resource-group  "psdemo-rg" \
    --name "psdemo-linux-1c-st0" \
    --size-gb 100


# start up the vm again 
az vm start \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1c"


az vm list-ip-addresses \
    --name "psdemo-linux-1c" \
    --output table

ssh

#6 unmount filesystem and expand the partition
sudo vi /etc/fstab #comment out our mount  uuid line
sudo umount /data1
sudo parted /dev/sdc

#use print to find the size of the new disk, partition 1 , resize, set  the size to 107
#upgrade version
#console
print
resizepart
1
107GB
quit


sudo e2fsck -f /dev/sdc1
sudo resize2fs /dev/sdc1
sudo mount /dev/sdc1 /data1
#add line uuid
sudo vi /etc/fstab
sudo mount -a

# verify the added space is available
df -h | grep data1








#removing a disk
#1 umoubnnt the disk in the OS, remove the disk we added above from fstab
ssh -l user IP
# del line uuid
sudo vi /etc/fstab
sudo umount /data1
#view, not see 
df -h | grep /data1
exit

#2 detaching the disk from the vm. this can be done onnline too!
az vm disk detach \
    --resource-group "psdemo-rg" \
    --vm-name "psdemo-linux-1c" \
    --name "psdemo-linux-1c-st0"

#3 delete the disk
az disk delete \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1c-st0"





#snapshotting the os disk
#find the disk we want to spanshot
az disk list --output table | grep psdemo-linux-1c

#take the name of disk and copy
#update the --source parameter with the disk from the last command

az snapshot create \
    --resource-group "psdemo-rg" \
    --source "nombre_of_disk" \
    --name "psdemo-linux-1c-OSDisk-1-snap-1"

az snapshot list \
    --output table


#3 create a new disk from the snapshot we ust created.
#if this was a data disk, we could just attach and mount this disk to a vm
az disk create \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1f-OSDisk-1" \
    --source "psdemo-linux-1c-OSDisk-1-snap-1" \
    --size-gb "40"


#create a vm from the disk we just created
az vm create \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1f" \
    --atatch-os-disk "psdemo-linux-1f-OSDisk-1" \
    --os-type "Linux"


#5 if we want we can delete a snapshot when we're finished
az snapshot delete \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1c-OSDisk-1-snap-1"