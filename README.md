# ansible-runner
Ansible, terraform, SSH runner for pipline tasks

## How to use

For running as dev environment:
```
docker pull ghcr.io/syntax3rror404/ansible-runner:master
```

For running in github actions:

```
jobs:
  deploy-nginx-config:
    runs-on: self-hosted
    container: 
      image: ghcr.io/syntax3rror404/ansible-runner
```

## Example update docker-compose nginx config

```
on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
  
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
        run: ssh -i ~/.ssh/id_rsa user@dockersrv1.labza "sudo sh -c 'cd /root/dockersrv01/volumes/nginx/nginx_conf && git pull origin master && exit'"

      - name: Redeploy nginx to apply config
        run: ssh -i ~/.ssh/id_rsa user@dockersrv1.labza "sudo sh -c 'cd /root/dockersrv01 && docker-compose -f ./compose/NGINX_PROXY/docker-compose.yml down && docker-compose -f ./compose/NGINX_PROXY/docker-compose.yml up -d && exit'"
```
