path="final_runs"
mkdir -p $path/config
mkdir -p $path/logs/memcached
mkdir -p $path/results/memcached
mkdir -p $path/logs/mysql
mkdir -p $path/results/mysql
mkdir -p $path/logs/xapian
mkdir -p $path/results/xapian

rsync -avz clabcl0:/mnt/extra/config/\*_config.out $path/config/

rsync -avz clabcl0:/mnt/extra/logs/memcached/summary $path/logs/memcached/
rsync -avz clabcl0:/mnt/extra/results/memcached/summary $path/results/memcached/

rsync -avz clabcl0:/mnt/extra/logs/mysql/summary $path/logs/mysql/
rsync -avz clabcl0:/mnt/extra/results/mysql/summary $path/results/mysql/

rsync -avz clabcl0:/mnt/extra/logs/xapian/summary $path/logs/xapian/
rsync -avz clabcl0:/mnt/extra/results/xapian/summary $path/results/xapian/