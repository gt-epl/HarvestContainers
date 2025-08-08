# Commonly, for c6420 machines, disk space can be mounted on /dev/sda4. 
lsblk -a

# format drive
sudo mkfs -t ext4 /dev/sda4

# create drive. Please stick to same name for drive
sudo mkdir -p /mnt/extra

# mount drive. This will be valid till next boot
sudo mount /dev/sda4 /mnt/extra

# change permissions if necessary
sudo chmod -R 775 /mnt/extra
my_group=$(groups | awk '{ print $1}') # gets the cloudlab group
sudo chgrp -R $my_group /mnt/extra
sleep 5
# Disable swap
sudo sed -i '/swap/s/^/#/' /etc/fstab
sleep 2
# Add /mnt/extra to fstab
sudo sed -i "s/^UUID=.*\$/&\nUUID=$(lsblk -fno UUID /dev/sda4) \/mnt\/extra      ext4    errors=remount-ro 0       1/" /etc/fstab

# Relocate journald files to save space
sudo systemctl stop systemd-journald.service
sudo mv /var/log/journal /mnt/extra
sudo ln -s /mnt/extra/journal /var/log/journal
sudo systemctl start systemd-journald.service
