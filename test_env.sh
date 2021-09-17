#!/usr/bin/bash
export VAGRANT_CWD=${PWD}/provisioning
vagrant_vms=$(vagrant status | grep running | awk '{print $1}' )
num=$(echo $(c() { echo $#; }; c $vagrant_vms))
docker_msg="Docker container is not started. Run 'make start' again"

test_ports () {
    nc -zv "$1" 80 2>1
}

check_app () {
    curl "$1":80 2>1 | grep Hello
}

if_app () {
    if [[ ${rc} == 0 ]]; then
        echo "Connection to $i $1 works"
    else
        err+=1
        echo "Connection to $i is down"
    fi
}
if [ ${num} == 2 ]; then
    echo "There are ${num} vms running"
    for vm in ${vagrant_vms}; do
    ip=$(vagrant ssh ${vm} -c "ip address show eth1" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    ips+="${ip} "
    service_status=$(vagrant ssh ${vm} -c "systemctl is-active httpd" 2>/dev/null)
    echo "httpd service is running on ${vm}"
    done
else
    declare -i err=1
fi

if [ ! -z ${ips+x} ]; then
    echo "IP addresses of vagrant vms are: ${ips}."
fi

docker_stat=$(docker ps | grep loadbalancer)
if [ ! -z ${docker_stat+x} ] ; then
    container_ip=$(docker container inspect loadbalancer -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    if [ ! -z ${container_ip+x} ]; then
        echo "Docker container ip is: ${container_ip}."
    else
        echo $docker_msg 
        err+=1
    fi
else
    echo $docker_msg
    err+=1
fi

for i in ${ips} ${container_ip} ; do
    test_ports $i 2>&1
    rc=$?
    if_app "port 80" 
    check_app $i 2>&1
    rc=$?
    if_app "Hello app"
done

if [ ! -z ${err+x} ]; then
    echo "There are $err errors. Environment is not working as expected."
else
    echo "There are no errors."
fi