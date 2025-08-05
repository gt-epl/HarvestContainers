# HarvestContainers

HarvestContainers monorepo for NSDI'26 Artifact Submission.

## Getting Started Instructions

The fastest way to start evaluating HarvestContainers is to use our pre-built Cloudlab image:
 
- You will need to register for an account at [Cloudlab](https://www.cloudlab.us)
- Once you have registered, visit the profile page for our [HarvestContainers Cloudlab Profile](https://www.cloudlab.us/p/NFSlicer/c6420-10g-cluster)
- Select the `Instantiate` button
- At the `Parameterize` step, ensure `Number of client machines` is set to 1 (this will create one server machine and one client machine)
- Ensure "No Interswitch Links" is checked, and then click "Next"
- Select a project to attach this experiment to (if you do not already have a project to use, one can be created by selecting your username in the top-right corner and then "Start/Join Project")
- Select "Next" and then "Finish" to launch a new experiment

Cloudlab will provision bare metal machines and load them with a pre-built Linux image that contains most dependencies needed to run HarvestContainers.

After the machines have been brought online, SSH into each and clone this repo to your home directory.

Follow the instructions in docs 1-3 to finish configuring the system. After these steps are completed you may run `HarvestContainers/TestFramework/Experiments/sanity.sh` to sanity check your setup. This script will run some simple baseline and harvest evaluations that should return similar results if the system setup is successful.

## Detailed Instructions

For full evaluations on Cloudlab, follow our documentation in the order below:

1. [Setup Cloudlab](./Docs/01_setup_cloudlab.md)
2. [Setup Kubernetes](./Docs/02_setup_k8s.md)
3. [Setup Workloads](./Docs/03_setup_workload.md)
4. [Run Experiments](./Docs/04_setup_exp.md)
5. (Optional)[Examine Test Runners](./Docs/05_setup_runner.md)
