# Routing between ZeroTier and VPC Networks 

This is going to be a step-by-step guide in how to route your private network to the ZeroTier service. This only requires a little bit of networking know how to accomplish. This will be a walk through from a fresh installation of Ubuntu 24 that is set up in DigitalOcean. Please note that at the time of this writing these instructions might change over time but still may be used as a guide.

## Required Information
| Info | Example | Shorthand Name Below | Notes |
| --- | --- | --- | --- |
| ZeroTier Network ID | 48d6023c46c1bfd8 | N/A |  |
| ZeroTier Interface Name |  | 

## Installation

Instructions on how to install and set up zero ZeroTier.

```bash
sudo apt update
curl -s https://install.zerotier.com | sudo bash
```
```bash
sudo zerotier-cli join 48d6023c46c1bfd8
sudo zerotier-cli listnetworks
```

Output should look like this
```bash
root@zt-server-01:~# sudo zerotier-cli join 48d6023c46c1bfd8
200 join OK
root@zt-server-01:~# sudo zerotier-cli listnetworks
200 listnetworks <nwid> <name> <mac> <status> <type> <dev> <ZT assigned ips>
200 listnetworks 48d6023c46c1bfd8  da:23:6d:02:13:c1 ACCESS_DENIED PRIVATE ztosimha46 -
```

> **YOU MUST GO TO ZEROTIER CENTRAL AND HAVE YOUR DEVICE AUTHORIZED IN ORDER TO CONTINUE**

After your device has been authorized it should look something similar to this
```bash
root@zt-server-01:~# sudo zerotier-cli listnetworks
200 listnetworks <nwid> <name> <mac> <status> <type> <dev> <ZT assigned ips>
200 listnetworks 48d6023c46c1bfd8 it490_fantasy da:23:6d:02:13:c1 OK PRIVATE ztosimha46 172.30.52.150/16
```

## Configuration
We next need to configure the routing table to allow traffic to flow between the VPC and ZeroTier network.

Use the `ip a` command to see the list of all interfaces available to us. Note the interface names as we need to set up the iptables as well.
```bash
root@zt-server-01:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether b6:ea:53:63:c6:18 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
    inet 162.243.218.171/24 brd 162.243.218.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 10.13.0.5/16 brd 10.13.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::b4ea:53ff:fe63:c618/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether f2:43:3f:96:b7:dc brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    altname ens4
    inet 10.100.0.2/20 brd 10.100.15.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::f043:3fff:fe96:b7dc/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ztosimha46: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 2800 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether da:23:6d:02:13:c1 brd ff:ff:ff:ff:ff:ff
    inet 172.30.52.150/16 brd 172.30.255.255 scope global ztosimha46
       valid_lft forever preferred_lft forever
    inet6 fe80::d823:6dff:fe02:13c1/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever

```
We can see that the interface `ztosimha46` is the one that is connected to our zerotier network. We need to route connections to `eth1` which is our VPC interface.




Examples of how to use the project.

```bash
# Example usage
python main.py
```

## Contributing

Guidelines for contributing to the project.

## License

Information about the project's license.