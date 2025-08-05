root_path=$(git rev-parse --show-toplevel)

rsync -avPz --exclude .git --exclude .DS_Store $root_path/ clabcl1:~/HarvestContainers/
rsync -avPz --exclude .git --exclude .DS_Store $root_path/ clabsvr:~/HarvestContainers/