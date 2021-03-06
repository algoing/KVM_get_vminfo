#!/bin/bash
rm -fr /root/vmhost.txt

#spice
function get_spiceinfo () {
ps aux | grep "qemu-kvm -name" | grep -v grep | grep " \-spice port" | awk '{ for(i=1;i<=NF;i++){if($i ~ /-name/)Name=$(i+1);else if($i == "-spice")Port=$(i+1)} print Name,$2,$3,$4,"spice:"substr(Port,1,match(Port,/,addr.*/)-1)}' | sed -r "s/(port=|tls-port=)//g" >> /root/vmhost.txt
}

#vnc
function get_vncinfo() {
ps aux | grep "qemu-kvm -name" | grep -v grep | grep " \-vnc " | awk '{ for(i=1;i<=NF;i++){if($i == "-name")Name=$(i+1);else if($i == "-vnc")Port=$(i+1)} print Name,$2,$3,$4,"vnc:"substr(Port,match(Port,/:.*/)+1)+5900}' >> /root/vmhost.txt
}

#get vhost cpu,memory
function get_vminfo() {
virsh dominfo "$1" | awk '/^CPU\(s\)/{print $2};/^Used memory/{print $3/1024/1024"G"}' | xargs
}

#get vhost block
function get_vmblk() {
virsh domblklist "$1" | awk 'NR>=3{if($2 != "-" && NF>=1) print $1":"$2}' | xargs
}

#format 
function format_line() {
get_spiceinfo
get_vncinfo
for i in `cat /root/vmhost.txt | awk '{print $1}'`;do
	vminfo="`get_vminfo ${i}`"
	blkinfo_temp="`get_vmblk ${i}`"
	blkinfo=$(echo ${blkinfo_temp} | sed -r 's/\//\\\//g')
	sed -i -r "/^${i} /s/.*/& ${vminfo} ${blkinfo}/g" /root/vmhost.txt
done
}

function format_printf() {
cat /root/vmhost.txt | awk 'BEGIN{printf "%-20s %-10s %-5s %-5s %-20s %-5s %-5s %-20s\n","VHOSTS","PID","%CPU","%MEM","PORT","Vcpus","Vmems","Vdisks";printf"%s\n","--------------------------------------------------------------------------------------------------------------------------------------"}{printf "%-20s %-10s %-5s %-5s %-20s %-5s %-5s %-20s\n",$1,$2,$3,$4,$5,$6,$7,$8}'
}

function main() {
format_line
format_printf
}
main
