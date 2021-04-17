#!/bin/bash
if [ $# -ne 1 ]; then
  echo "Commands: create, connect, shell, delete"
fi

docker_sndbox_create() {
  echo "Create key..."
  yes y | ssh-keygen -t rsa -b 4096 -f docker-sandbox-key -q -N "" -C ""
  aws ec2 import-key-pair --key-name docker-sandbox-key \
    --public-key-material fileb://docker-sandbox-key.pub

  echo "Create stack..."
  aws cloudformation create-stack --stack-name docker-sandbox-stack \
    --template-body file://docker-sandbox-template.yaml \
    --parameters ParameterKey=dockerSandboxKey,ParameterValue=docker-sandbox-key  
  aws cloudformation wait stack-create-complete --stack-name docker-sandbox-stack
}

docker_sandbox_connect() {
  echo "Find host..."
  dockerSandboxPublicName=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=docker-sandbox-instance" \
    --filters "Name=instance-state-code,Values=16" \
    --query "Reservations[0].Instances[0].PublicDnsName" --output text)

  echo "Connect host..."
  export DOCKER_HOST=tcp://$dockerSandboxPublicName:10000
  until (docker version >/dev/null 2>&1); do (echo "Waiting docker..."; sleep 5); done
  docker version
}

docker_sandbox_shell() {
  echo "Open shell..."
  ssh -i docker-sandbox-key ec2-user@$dockerSandboxPublicName \
    -oStrictHostKeyChecking=accept-new
}

docker_sandbox_delete() {
  echo "Delete stack..."
  aws cloudformation delete-stack --stack-name docker-sandbox-stack
  aws cloudformation wait stack-delete-complete --stack-name docker-sandbox-stack

  echo "Delete key..."
  aws ec2 delete-key-pair --key-name docker-sandbox-key
  rm docker-sandbox-key* 2> /dev/null
}

[[ "$1" == "create" ]] && docker_sndbox_create && docker_sandbox_connect
[[ "$1" == "connect" ]] && docker_sandbox_connect
[[ "$1" == "shell" ]] && docker_sandbox_shell
[[ "$1" == "delete" ]] && docker_sandbox_delete
