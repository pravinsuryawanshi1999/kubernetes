#!/bin/bash

# Create a Docker network
docker network create ansible-network --subnet 192.168.1.0/24

# Create the Ansible Control Node
docker run -d -it --name ansible-control --net ansible-network --hostname ansible-master ubuntu
docker exec -it ansible-control bash -c "
  apt update && apt install -y ansible openssh-client iputils-ping &&
  ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
"

# Create Worker Nodes
docker run -d -it --name ansible-worker1 --net ansible-network --ip 192.168.1.18 --hostname worker1 ubuntu
docker run -d -it --name ansible-worker2 --net ansible-network --ip 192.168.1.19 --hostname worker2 ubuntu

# Configure SSH on Worker Nodes
for worker in ansible-worker1 ansible-worker2; do
  docker exec -it $worker bash -c "
    apt update && apt install -y openssh-server &&
    service ssh start &&
    mkdir -p ~/.ssh &&
    touch ~/.ssh/authorized_keys &&
    chmod 600 ~/.ssh/authorized_keys
  "
done

# Enable Passwordless SSH Authentication
docker exec -it ansible-control bash -c "
  cat ~/.ssh/id_rsa.pub
" | tee >(docker exec -i ansible-worker1 bash -c "cat >> ~/.ssh/authorized_keys") \
     >(docker exec -i ansible-worker2 bash -c "cat >> ~/.ssh/authorized_keys")

# Setup Ansible Inventory
docker exec -it ansible-control bash -c "
  echo '[workers]' >> /etc/ansible/hosts &&
  echo 'worker1 ansible_host=192.168.1.18 ansible_user=root' >> /etc/ansible/hosts &&
  echo 'worker2 ansible_host=192.168.1.19 ansible_user=root' >> /etc/ansible/hosts
"

# Test Connectivity
docker exec -it ansible-control bash -c "ansible all -m ping"

# Install Bash inside containers & fix command history
for node in ansible-control ansible-worker1 ansible-worker2; do
  docker exec -it $node bash -c "
    apt update && apt install -y bash &&
    export HISTFILE=/root/.bash_history &&
    export HISTSIZE=1000 &&
    export HISTFILESIZE=2000
  "
done

echo "✅ Ansible Docker setup complete! You can now run Ansible commands."

