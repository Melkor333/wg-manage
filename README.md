# Introduction

This is a very opinionated project trying to enable an almost completely smooth transition from OpenVPN with easy-rsa to wireguard.
The usage is quite simple but has some downsides. E.g. the private key of all clients will be stored on the server [currently, this could be changed quite easily].

**It is imported that once this tool is used, every client needs to be created with this scripts, as duplicated IP usage will happen otherwise!**

# Simple setup

First we need the following information before we can define the server config:

## Prerequisites

### Name

If only one wireguard server is used, we don't need a name and default "wggt" will be used.
If multiple wireguard services should run on the same wireguard server, we need to provide a name.

the configfile will be called "/etc/wireguard/NAME.conf" and can usually be started with `systemctl start wg-quick@NAME.service`.

### Address

The address, respectively the subnet used in the communication with all clients needs to be known. It'll be Address/subnet.

### Endpoint [address]

The public address of the server to which clients will connect is also necessary. the port can also be specified, e.g. 1.1.1.1:1234.

### Subnets (Optional)

Sometimes you just want to connect to the wireguard server, but usually the vpn tunnel is used to connect to a whole network.
If that is the case, the network(s) need to be specified here.

### DNS (Optional)

If the client should use a DNS Server through the VPN, this can be specified here.

## Server Setup

Once the above information are gathered, the setup is easy:

```
./create-server.sh -n Name -e Endpoint -s Subnets -d DNS
```

### Created files

#### /etc/wireguard/name.conf

This is the server config file.

#### /etc/wireguard/name/

This Directory holds all relevant information to create new client configs. All relevant configuration options are stored into files pretty much exaclty as they were given on the commandline:

- endpoint
- last_address: Initially holds the Address given for the Server. Increments whenever a new host is added
- dns
- subnets

public / private key files will also be stored in this directory, starting with a keypair for the wireguard server

- HOSTNAME.key
- HOSTNAME.pub

## Client Setup

every client will have a unique name, which should be either the hostname of a device or a username. But it's completely up to the user
The most simple client Setup is:

```
./create-client.sh -c client
```

This will create a client configuration for the default wireguard setup (with the name `wggt`). The configuration will be printed out.

Almost all of the above prerequisites can be overridden for a single client.
