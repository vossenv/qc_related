#!/bin/bash

printColor(){
    case $2 in
        "black") col=0;;
          "red") col=1;;
        "green") col=2;;
       "yellow") col=3;;
         "blue") col=4;;
      "magenta") col=5;;
         "cyan") col=6;;
        "white") col=7;;
              *) col=7;;
    esac
    printf "$(tput setaf $col)$1$(tput sgr 0)\n"
}

printBanner() {
	sep="------------------------------------------------------------------"	
	printColor "$1\n$sep" green	
}

cleanup() {
	if [[ ! $? = 0 ]]; then
		printColor "Critical error! Unmounting $dev and exiting... \n\n" red
   	losetup -d $dev &> /dev/null
	fi
  echo "Unmounting $part1... "
  umount $part1
  echo "Unmounting $part2... "
  umount $part2
}

#### Script begins here
fdisk -l

dev1=/dev/sdd1
dev2=/dev/sdd2
part1=/mnt/a
part2=/mnt/b
port=3600

trap "cleanup" EXIT
printBanner "\nBegin!"
echo ""

[ ! -d "$part1" ] && mkdir $part1
[ ! -d "$part2" ] && mkdir $part2

echo "Mounting $part1... "
mount $dev1 $part1
echo "Mounting $part2... "
mount $dev2 $part2

echo "Modify sshd_config using port: ${port}"
sshd_file="${part1}/etc/ssh/sshd_config"
echo $sshd_file
sed -i -E "s/(#|^)PermitRootLogin .*/PermitRootLogin yes/g" $sshd_file
sed -i -E "s/(#|^)PubkeyAuthentication .*/PubkeyAuthentication yes/g" $sshd_file
sed -i -E "s/^Port .*/Port ${port}/g" $sshd_file

echo "Copy ssh key"
ssh_dir="${part1}/root/.ssh"
[ ! -d "$ssh_dir" ] && mkdir $ssh_dir
cp ./authorized_keys $ssh_dir

echo "Copy to second partition"
cp $sshd_file "${part2}/etc/ssh/sshd_config"
cp -r $ssh_dir "${part2}/root/"

printBanner "\nProcess complete! Login with ssh root@[host] -p 3600"


