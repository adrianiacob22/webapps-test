export VAGRANT_CWD=${PWD}/provisioning

default: start
install: 
	@ansible-playbook provisioning/ansible/main.yaml
	@docker build -t loadbalancer -f provisioning/docker/Dockerfile provisioning/docker/

start: 
	@ansible-playbook -i provisioning/ansible/hosts  provisioning/ansible/main.yaml
	@docker ps | grep loadbalancer > /dev/null 2>&1 && docker stop loadbalancer || true
	@vagrant up --provision
	@docker run -itd --rm --name loadbalancer loadbalancer:latest
	@echo "---------------"
	@echo "Open the load balancer using http://$$(docker container inspect loadbalancer -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"

stop:
	@vagrant halt
	@docker stop loadbalancer

status:
	@vagrant status
	@docker ps | grep loadbalancer || echo "loadbalancer is down"
	@./test_env.sh