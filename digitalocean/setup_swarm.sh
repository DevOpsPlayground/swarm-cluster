#!/usr/bin/env bash

# Run the settings for DigitalOcean
[ -f ~/bin/settings_do.sh ] && source ~/bin/settings_do.sh
swarm_nodes="swarm-node-1 swarm-node-2"

echo "Creating the master"
docker-machine create \
  -d digitalocean \
  --digitalocean-access-token=$DO_ACCESS_TOKEN \
  --digitalocean-size 1gb \
  --digitalocean-ssh-key-fingerprint=$DO_KEY \
  swarm-master
master_ip=$(docker-machine ip swarm-master)

echo "Initializing the swarm mode"
docker-machine ssh swarm-master docker swarm init --advertise-addr $master_ip

echo "Setting up Portainer for visualization"
docker-machine ssh swarm-master \
  docker run --name=portainer -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer

join_token=$(docker-machine ssh swarm-master docker swarm join-token -q worker)
echo "Join token is ${join_token}"

# Create and join the workers
for worker in $swarm_nodes; do
  echo "Creating worker ${worker}"
  docker-machine create \
    -d digitalocean \
    --digitalocean-access-token=$DO_ACCESS_TOKEN \
    --digitalocean-size 1gb \
    --digitalocean-ssh-key-fingerprint=$DO_KEY \
    ${worker}
  docker-machine ssh $worker docker swarm join --token $join_token $master_ip:2377
done

