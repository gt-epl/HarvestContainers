# Commonly, for c6420 machines, disk space can be mounted on /dev/sda4. 
lsblk -a

# format drive
sudo mkfs -t ext4 /dev/sda4

# create drive. Please stick to same name for drive
sudo mkdir /mnt/extra

# mount drive. This will be valid till next boot
sudo mount /dev/sda4 /mnt/extra

# change permissions if necessary
sudo chmod -R 775 /mnt/extra
my_group=$(groups | awk '{ print $1}') # gets the cloudlab group
sudo chgrp -R $my_group /mnt/extra