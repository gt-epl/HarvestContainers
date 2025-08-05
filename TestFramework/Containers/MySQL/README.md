# MySQL Pod

Deploy a MySQL pod to the K8s cluster

## Automated Creation

1. Run `./setup_mysql.sh`

## Manual Creation

For this example, we will assume the MySQL pod will be deployed to a node named `client0` and will use a ramdisk located at `/mnt/data` for its data store.

1. Label the `client0` node to instruct the K8s scheduler as to where the MySQL pod will be placed: `kubectl label client0 mysql_pod=primary`
2. Create ramdisk on the `client0` node: `sudo mkdir /mnt/data && sudo mount -t tmpfs -o size=20G tmpfs /mnt/data && sudo mkdir /mnt/data/mysql`
3. Create a PersistentVolume: `kubectl apply -f mysql-pv.yaml` (Note: You will need to edit this file if you wish to change the node name and/or mount path)
4. Create a PersistentVolumeClaim: `kubectl apply -f mysql-pvc.yaml`
5. Deploy the pod: `kubectl apply -f mysql_pod.yaml`
6. Expose the MySQL pod as a service: `kubectl expose pod mysql --type=ClusterIP --port=3306 --name=mysql --output='json' | jq '.spec.clusterIP'`
7. Using the output from Step (6), update the `db.properties` file with the service IP address
