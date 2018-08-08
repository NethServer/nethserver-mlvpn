=================
nethserver-mlvpn
=================

MLVPN (https://github.com/zehome/MLVPN) inside NethServer.

Supported usage scenarios
=========================

Connect with a tunnel two different networks where NethServer is the gateway of both networks.
The tunnel will aggregate the bandwidth of multiple red interfaces, also handling failover scenarios.

Features:

- bandwidth aggregation of multiple internet connections
- automatic failover, without changing IP addresses or interrupting TCP connections in case of a failure
- optional tunnel encryption

Prerequisites
-------------

Firewall A:

- at least 2 red network interfaces


Firewall B:

- only 1 red interface


Limits
======

If the red network interface is configured with DHCP, the tunnel must be manually restarted if the IP address changes.

Example
=======


Client: ::

  db mlvpn set c1 client status enabled Password pippo Timeout 30 Encryption enabled ReorderBuffer 64 LossTolerence 100 Connections enp0s8:167.99.248.247:5080 RemoteNetworks 192.168.0.0/24,192.168.1.0/24 LocalPeer 10.42.43.2 RemotePeer 10.42.43.1 Nat enabled
  signal-event mlvpn modify c1


Server: ::

  db mlvpn set s1 server status enabled Password pippo Timeout 30 Encryption enabled ReorderBuffer 64 LossTolerence 100 Connections fibra:0.0.0.0:5080,adsl:0.0.0.0:5081 RemoteNetworks 192.168.5.0/24 LocalPeer 10.42.43.1 RemotePeer 10.42.43.2 Nat enabled
  signal-event mlvpn-modify s1
