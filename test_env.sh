#!/usr/bin/bash
export VAGRANT_CWD=${PWD}/provisioning
vagrant_vms=$(vagrant status | grep running | awk '{print $1}' )
num=$(echo $(c() { echo $#; }; c $vagrant_vms))
docker_msg="Docker container is not started. Run 'make start' again"
file=outfile.txt

test_ports () {
    nc -zv "$1" 80 2>/dev/null
}

check_app () {
    curl "$1":80 2>/dev/null | grep Hello
}

if_app () {
    if [[ ${rc} == 0 ]]; then
        echo "Connection to $i $1 works" >> ${file}
    else
        echo "Connection to $i $1 is down" >> ${file}
    fi
}

if [ -f ${file} ]; then
    echo > ${file}
else
    touch ${file}
fi

if [ ${num} == 2 ]; then
    echo "There are ${num} vms running" >> ${file}
    for vm in ${vagrant_vms}; do
    ip=$(vagrant ssh ${vm} -c "ip address show eth1" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    ips+="${ip} "
    service_status=$(vagrant ssh ${vm} -c "systemctl is-active httpd" 2>/dev/null)
    echo "httpd service is running on ${vm}" >> ${file}
    done
fi

if [[ ! -z ${ips} ]]; then
    echo "IP addresses of vagrant vms are: ${ips}." >> ${file}
fi

docker_stat=$(docker ps | grep loadbalancer)
if [[ ! -z ${docker_stat} ]] ; then
    container_ip=$(docker container inspect loadbalancer -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    if [[ ! -z ${container_ip} ]]; then
        echo "Docker container ip is: ${container_ip}." >> ${file}
    else
        echo $docker_msg  >> ${file}
    fi
else
    echo $docker_msg >> ${file}
fi

for i in ${ips} ${container_ip} ; do
    test_ports $i 2>&1
    rc=$?
    if_app "port 80"  >> ${file}
    check_app $i 2>&1
    rc=$?
    if_app "Hello app" >> ${file}
done

