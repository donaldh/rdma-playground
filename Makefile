.ONESHELL:

KERNEL ?= ~/torvalds

net:	## Configure the bridge network
	sudo ip link add br1 type bridge
	sudo ip link set br1 up

run:	## Run qemu VMs in screen
	screen -S rdma-server -dm vng --disable-microvm --name rdma-server --user root \
		-o \\-nic -o bridge,br=br0,model=virtio,mac=52:54:01:42:01:1 \
		-o \\-nic -o bridge,br=br1,model=virtio,mac=52:54:01:42:01:2 \
		--run $(KERNEL)
	screen -S rdma-client -dm vng --disable-microvm --name rdma-client --user root \
		-o \\-nic -o bridge,br=br0,model=virtio,mac=52:54:01:42:02:1 \
		-o \\-nic -o bridge,br=br1,model=virtio,mac=52:54:01:42:02:2 \
		--run $(KERNEL)

config:	## Configure networking in qemu VMs
	screen -X -S rdma-server stuff "
	ip link set dev eth0 up
	ip link set dev eth1 up
	ip address add 192.168.101.1 dev eth1
	ip route add 192.168.101/24 dev eth1
	"
	screen -X -S rdma-client stuff "
	ip link set dev eth0 up
	ip link set dev eth1 up
	ip address add 192.168.101.2 dev eth1
	ip route add 192.168.101/24 dev eth1
	"

rdma:	## Configure RDMA in qemu VMs
	screen -X -S rdma-server stuff "
	rdma link add rxe0 type rxe netdev eth1
	"
	screen -X -S rdma-client stuff "
	rdma link add rxe0 type rxe netdev eth1
	"

halt:	## Halt all VMs in screen
	-screen -X -S rdma-client stuff "^D"
	-screen -X -S rdma-server stuff "^D"


help:	## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: help
.DEFAULT_GOAL := help
