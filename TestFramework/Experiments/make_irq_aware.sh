echo "Enabling HarvestContainers IRQ awareness"
IRQ_LIST=$(cat /mnt/extra/config/irq_nums | tr '\n' ',' | sed 's/,$//')
echo ${IRQ_LIST} | sudo tee /proc/idlecpu/irqlist
echo "18,20" | sudo tee /proc/idlecpu/irqaffinity
echo 1 | sudo tee /proc/idlecpu/irqcontrol
