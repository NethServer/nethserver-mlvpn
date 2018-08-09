=================
nethserver-mlvpn
=================

Implement a simple SD-WAN for NethServer using MLVPN (Multi-link VPN).

Features:

- bandwidth aggregation of multiple internet connections
- automatic failover, without changing IP addresses or interrupting TCP connections in case of a failure
- optional tunnel encryption

Official site: https://github.com/zehome/MLVPN

Supported usage scenarios
=========================

Current implementation covers two different usage scenarios:

- fault tolerant tunnels between private networks
- high-speed Internet access using a proxy firewall

Fault tolerant tunnels
----------------------

Connect with a tunnel two different networks where NethServer is the gateway of both networks.
The tunnel will aggregate the bandwidth of multiple red interfaces, also handling failover scenarios.

For instance, an office with 2 ADSL connections should always able to access a remote Nextcloud instance with
the maximum available speed.

Requirements:

- a Nextcloud installed on a NethServer hosted on a high-bandwidth VPS: 1 green network interface 
- one NethServer installation configured with 2 WAN connections: 1 (or more) green network interface, 2 red network interfaces

High-speed proxy firewall
-------------------------

Use a remote high-bandwidth VPS as gateway for all Internet traffic.

For instance, an office has two slow Internet connections and wants to maximize
the available bandwidth also exposing services like a local mail server.

Requirements:

- one NethServer installation hosted on a high-bandwidth VPS: 1 green network interface
- one NethServer installation configured with 2 WAN connections: 1 (or more) green network interface, 2 red network interfaces

All connections to the outside world will use the public IP of the VPS.

Configuration
=============

Tunnel are records inside the ``mlvpn`` esmith database. Each machine can handle multiple tunnels.

Supported record type:

* ``server``: configure a MLVPN server on a VPS or another remote machine with 1 at least one green interface
* ``client``: configure a MLVPN client on firewall with at least 2 WAN connections to be bonded together

Options:

* ``status``: can be ``enabled`` or ``disabled``, if ``disabled`` the MLVPN instance will not be 

* ``Connections``: a comma-separated list of strings in the format ``identifier:address:port``. 
  The meaning is different when used on a client or server record.

  * server: ``identifier`` is a unique name of the connection, like "fiber1"; ``address`` is the bind IP, it should always be ``0.0.0.0``; ``port`` is the unique binding port
  * client: ``identifier`` is the name of an existing red interface, like ``eth2``; ``address`` is the remote server public IP or hostname; ``port`` is the server remote port

* ``ControlPort``: HTTP port to use for retrieving tunnel statics. The port is bind only on 127.0.0.1. Use progressive ports starting from ``50001``

* ``Encryption``: if ``enabled`` all traffic will be encrypted, if ``disabled`` session data (auth)
  will still be encrypted, but all data packets will not

* ``LocalPeer``: a local virtual IP for the tunnel, used for firewall rules

* ``LossTolerence``: the maximum loss ratio accepted before the link affected is being considered too lossy and removed from aggregation.
  This value is expressed in percent. A value of ``100`` disables the loss tolerance system

* ``Nat``: set it to ``enabled`` if the tunnel should be used for internet access. Inside the the client use the tunnel as default gateway; inside the server, it enabled the masquerading.
  Set to ``disabled`` if the tunnel should be used to access services running on the server (or on a network attached to it)

* ``Password``: random password used for encryption

* ``RemoteNetworks``: comma-separated list of network CIDR which should be reachable behind the tunnel. All routes are created on tunnel startup

* ``RemotePeer``: the IP of the remote tunnel endpoint, used for firewall rules

* ``ReorderBuffer``: number of packets inside the buffer for reordering algorithm. Experiment to know what value is best for you. Good starting point can be as small as ``64`` packets
  If set to ``0``, it disables the link aggregation

* ``Timeout``: triggered when the other side does not responds to keepalive packets. Keepalive are send every timeout/2 seconds. Good starting point can be ``30`` seconds


When configuring a client and a server, the following options should be the same on both ends: ``Encryption``, ``LossTolerance``, ``Nat``, ``Password``, ``ReorderBuffer``, ``Timeout``.
Swap ``LocalPeer`` and ``RemotePeer`` IPs  between server and client configuration.

Please use a short names for server and client, do not pick a name longer 5 characters.

Events
------

There are 2 events defined:

- ``mlvpn-modify``: takes the record key (server/client name) as argument, it must be fired when creating or editing a tunnel
- ``mlvpn-delete``: takes the record key (server/client name) as argument, disable and delete the selected tunnel

Firewall
========

Tunnels are confined inside a ``mlvnpn`` Shorewall zones which can be considered as a trusted network:
by default, all traffic is permitted to and from the mlvpn zone.
As an exception, when a server is acting as a gateway, the mlvpn interface is marked as green interface allowing the 
creation of firewall rules directly from the web interface.
Each tunnel creates a TUN device named ``mlvpn<name``. For instance if the client is named ``c1``, the interfaces will be named ``mlvpnc1``.

It's possible to create port forwarding rules inside the server for services running on the client or on a host behind the client itself.

Examples
========

Office firewall:

- red interfaces: eth1 (adsl1), eth2 (adsl2)
- local network: 192.168.0.0/24
- virtual tunnel IP: 10.42.43.2

VPS:

- green interface: eth0
- local network: 192.168.100.0/24
- public IP: 1.2.3.4
- virtual tunnel IP: 10.42.43.1

Fault tolerant tunnels
----------------------

Create a tunnel between an office firewall and a VPS to access a service running on the VPS itself (or on a network behind the VPS).

Configure a client named ``c1``: ::

  db mlvpn set c1 client status enabled Password mypassword Timeout 30 Encryption enabled ReorderBuffer 64 LossTolerence 50 Connections eth1:1.2.3.4:5080,eth2:1.2.3.4:5081 \
  RemoteNetworks 192.168.1000.0/24 LocalPeer 10.42.43.2 RemotePeer 10.42.43.1 Nat disabled ControlPort 50001
  signal-event mlvpn modify c1


Configure a server named: ``s1``::

  db mlvpn set s1 server status enabled Password mypassword Timeout 30 Encryption enabled ReorderBuffer 64 LossTolerence 50 Connections adsl1:0.0.0.0:5080,adsl2:0.0.0.0:5081 \
  RemoteNetworks 192.168.0.0/24 LocalPeer 10.42.43.1 RemotePeer 10.42.43.2 Nat disabled ControlPort 50001
  signal-event mlvpn-modify s1
    
High-speed proxy firewall

-------------------------

Access Internet using the VPS a proxy firewall.

Configure a client named ``c1``: ::

  db mlvpn set c1 client status enabled Password pippo Timeout 30 Encryption enabled ReorderBuffer 64 LossTolerence 100 Connections eth1:1.2.3.4:5080,eth2:1.2.3.4:5081 \
  RemoteNetworks 192.168.1000.0/24 LocalPeer 10.42.43.2 RemotePeer 10.42.43.1 Nat enabled ControlPort 50001
  signal-event mlvpn modify c1


Configure a server named: ``s1``::

  db mlvpn set s1 server status enabled Password pippo Timeout 30 Encryption enabled ReorderBuffer 64 LossTolerence 100 Connections adsl1:0.0.0.0:5080,adsl2:0.0.0.0:5081 \
  RemoteNetworks 192.168.0.0/24 LocalPeer 10.42.43.1 RemotePeer 10.42.43.2 Nat enabled ControlPort 50001
  signal-event mlvpn-modify s1


Check the used public IP is the one on the VPS: ::

  curl ifconfig.co

Managing tunnels
=================

Check the status: ::

  systemctl status mlvpn@<name>

Where name is tunnel name, for instance ``c1``: ``systemctl status mlvpn@c1``.

Restarting a tunnel: ::

  systemctl restart mlvpn@<name>

Logs are saved inside ``/var/log/mlvpn``.

Limitations
===========

- If the red network interface is configured with DHCP, the tunnel must be manually reconfigured if the IP address changes: ``signal-event mlvpn-modify <name>``.
- When ``Nat`` mode is enabled inside the server, the mlvpn connection will always replace the 15th Shorewall provider.
