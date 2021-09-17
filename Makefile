export VAGRANT_CWD=${PWD}/provisioning
CSTAT := $(docker ps | grep loadbalancer | awk '{print $NF}')

default: start

install: 
	@ansible-playbook provisioning/ansible/main.yaml
	@docker build -t loadbalancer -f provisioning/docker/Dockerfile provisioning/docker/

start: vagrant docker

docker:
    ifeq ($(CSTAT), loadbalancer)
	docker stop loadbalancer && docker run -itd --rm --name loadbalancer loadbalancer:latest
    endif
	
vagrant:
	@vagrant up
	@echo "Open the load balancer using http://$$(docker container inspect loadbalancer -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"

stop:
	@vagrant halt
	@docker stop loadbalancer


#docker run -it -v ${PWD}:/e2e -w /e2e cypress/included:3.2.0