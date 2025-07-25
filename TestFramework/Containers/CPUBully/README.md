# CPUBully Container

This directory holds files for creating a CPUBully container and pod.

The *launcher.py* file is used to start CPUBully with a given configuration after its pod/container have been deployed.

To start CPUBully inside a pod:

1. Deploy the pod: `kubectl create -f c1.yaml`
2. Expose the pod's port 20000 as a service
3. `curl --data "{\"duration\":\"1\",\"workers\":\"5\"}" --header "Content-Type: application/json" http://<IP-of-CPUBully-Service>:20000`
