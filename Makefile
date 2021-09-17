export VAGRANT_CWD=${PWD}/provisioning

default: start

install: 
	@ansible-playbook provisioning/ansible/main.yaml
	@docker build -t loadbalancer -f provisioning/docker/Dockerfile provisioning/docker/

start:
	@vagrant up
	@docker run -itd --rm --name loadbalancer loadbalancer:latest
	@echo "Open the load balancer using http://$$(docker container inspect loadbalancer -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"

stop:
	@vagrant halt
	@docker stop loadbalancer


#docker run -it -v ${PWD}:/e2e -w /e2e cypress/included:3.2.0