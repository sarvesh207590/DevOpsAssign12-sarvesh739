#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT_DIR}/terraform"

echo "Running terraform..."
terraform init
terraform apply -auto-approve

# get outputs
CONTROLLER_IP=$(terraform output -raw controller_public_ip)
MANAGER_IP=$(terraform output -raw manager_public_ip)
WORKERA_IP=$(terraform output -raw workera_public_ip)
WORKERB_IP=$(terraform output -raw workerb_public_ip)

echo "Controller: $CONTROLLER_IP"
echo "Manager: $MANAGER_IP"
echo "WorkerA: $WORKERA_IP"
echo "WorkerB: $WORKERB_IP"

# copy docker and django files to manager and workers
echo "Copying files to manager..."
scp -o StrictHostKeyChecking=no -i terraform-key.pem -r ../docker ../django_app ubuntu@${MANAGER_IP}:/home/ubuntu/
scp -o StrictHostKeyChecking=no -i terraform-key.pem -r ../docker ../django_app ubuntu@${WORKERA_IP}:/home/ubuntu/
scp -o StrictHostKeyChecking=no -i terraform-key.pem -r ../docker ../django_app ubuntu@${WORKERB_IP}:/home/ubuntu/

# run ansible playbook to install docker and init swarm + join tokens
cd ../ansible
ansible-playbook -i inventory.ini setup-swarm.yml

# build images on each node (or push to registry instead)
ssh -o StrictHostKeyChecking=no -i ../terraform/terraform-key.pem ubuntu@${MANAGER_IP} "cd ~/docker && docker build -t myorg/django_web:latest -f Dockerfile.web ../django_app"
ssh -o StrictHostKeyChecking=no -i ../terraform/terraform-key.pem ubuntu@${WORKERA_IP} "cd ~/docker && docker build -t myorg/django_web:latest -f Dockerfile.web ../django_app"
ssh -o StrictHostKeyChecking=no -i ../terraform/terraform-key.pem ubuntu@${WORKERB_IP} "cd ~/docker && docker build -t myorg/django_web:latest -f Dockerfile.web ../django_app"

# on manager deploy stack
ssh -o StrictHostKeyChecking=no -i ../terraform/terraform-key.pem ubuntu@${MANAGER_IP} "cd ~/docker && docker stack deploy -c docker-compose.yml myapp"

echo "Deployment complete. Visit: http://${MANAGER_IP}/"
