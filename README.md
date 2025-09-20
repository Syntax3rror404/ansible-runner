# ansible-runner
Ansible, terraform, packer, SSH runner for pipline tasks like tekton or just simple sh scripts

## How to use

For running as dev environment:
```
docker pull ghcr.io/syntax3rror404/ansible-runner@sha256:f778b582aebcab9b0bb5cca349b825c8498d75b68d9d93e547976a4737b78bb0
```

For running in github actions:

```
jobs:
  deploy-nginx-config:
    runs-on: self-hosted
    container: 
      image: ghcr.io/syntax3rror404/ansible-runner@sha256:f778b582aebcab9b0bb5cca349b825c8498d75b68d9d93e547976a4737b78bb0
```

For running in tekton:

```
---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: build-packer-vmtemplate
  namespace: tekton-build
spec:
  params:
  - name: PACKER_TEMPLATE_NAME
  - name: PACKER_PATH
  - name: git-subdirectory
    type: string
    default: ""
    description: The subdirectory to list
  workspaces:
  - name: source
    description: A workspace holding packer template files
  steps:
  - name: show-packer-version
    securityContext:
      runAsNonRoot: true
      runAsUser: 65532
    image: ghcr.io/syntax3rror404/ansible-runner@sha256:f778b582aebcab9b0bb5cca349b825c8498d75b68d9d93e547976a4737b78bb0
    script: |
      packer --version
  - name: show-ansible-version
    securityContext:
      runAsNonRoot: true
      runAsUser: 65532
    image: ghcr.io/syntax3rror404/ansible-runner@sha256:f778b582aebcab9b0bb5cca349b825c8498d75b68d9d93e547976a4737b78bb0
    script: |
      ansible --version
```

## Example update docker-compose nginx config

```
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  
jobs:
  deploy-nginx-config:
    runs-on: self-hosted
    container: 
      image: ghcr.io/syntax3rror404/ansible-runner

    steps:
      - uses: actions/checkout@v1

      - name: Create SSH key
        run: |
          mkdir -p ~/.ssh/
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
          chmod 644 ~/.ssh/known_hosts
          ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no user@dockersrv1.labza
        env:
          SSH_PRIVATE_KEY: ${{secrets.SSH_PRIVATE_KEY}}
          SSH_KNOWN_HOSTS: ${{secrets.SSH_KNOWN_HOSTS}}

      - name: Update nginx config
        run: ssh -i ~/.ssh/id_rsa user@dockersrv1.labza "sudo sh -c 'cd /root/dockersrv01/volumes/nginx/nginx_conf && git pull origin main && exit'"

      - name: Redeploy nginx to apply config
        run: ssh -i ~/.ssh/id_rsa user@dockersrv1.labza "sudo sh -c 'cd /root/dockersrv01 && docker-compose -f ./compose/NGINX_PROXY/docker-compose.yml down && docker-compose -f ./compose/NGINX_PROXY/docker-compose.yml up -d && exit'"
```
