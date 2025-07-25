# Container for memcached

# Build

To build a memcached container:

`docker build -t memcached-hc .`

(Note: You will need to do this on every node in the K8s cluster since we rely on the local image repo when creating pods/containers)

# Deploy

K8s deploy files in this dir:

1. `memcached_pod.yaml` creates a single memcached pod named *memcached-primar*
2. `m1.yaml` and `m2.yaml` create two separate memcached pods *memcached-one* and *memcached-two* on the same node.

Note: All these configs expect one node in the cluster to be tagged with `podtype: memcached` annotation to ensure they will only be deployed to that node. 
You can add this annotation from the K8s master node with command `kubectl label nodes k8s01-sw podtype=memcached` where `k8s01-sw` is the node where you want memcached pods to be deployed.
