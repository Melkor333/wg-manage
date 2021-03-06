#!/usr/bin/env bash
set -euo pipefail
set +x
VERSION=0.1


# see: https://www.codebyamir.com/blog/parse-command-line-arguments-using-getopt
usage() {
  echo ""
  echo "Usage: $0 "
  echo "[-a --address <string>] Server Wireguard IP in this format: 10.0.0.1/24"
  echo "[-e --endpoint <string>] Server endpoint IP or dns and : port. Format: 77.22.33.44 or 1.1.1.1:123 to use a custom port"
  echo ""
  echo "Optional:"
  echo "[-r --root <string>] The root directory (default: /etc/wireguard)"
  echo "[-d --dns <string>] the default DNS configuration. E.g. '10.0.0.1, example.com'"
  echo "[-n --name <string>] The name of this tunnel (default: wggt). necessary if multiple Tunnels exist on one server"
  echo "[-s --subnets <string>] AllowedIPs Directive to route vpn clients + shared vpn services => \"10.190.248.0/30, 10.190.4.0/23\""
  echo "[-h / --help]"
  echo "example:"
  echo "# run script	      wg subnet & server IP	public IP of server    the network available    the name of this config      dns settings over the vpn"
  echo "./create-server.sh -a 10.0.0.1/24            -e 185.182.26.29:51820 -s 172.16.1.0/24         -n dmz                       -d \"10.0.0.10, mybusiness.local\""
  echo 1>&2;
  exit 1;
}

# Default variables
NAME=wggt
BASE=/etc/wireguard/
NETWORK=''
SUBNETS=
ENDPOINT=
DNS=

## Parse Parameters
# ______________________________________________________________________________
SHORT=e:d:s:a:i:r:n:h
LONG=endpoint:,dns:,subnets:,address:,interface:,name:,root:,help
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; usage; exit 1 ; fi
eval set -- "$OPTS"
while true ; do
  case "$1" in
    -h | --help )
      usage
      shift
      ;;
    -a | --address )
      NETWORK="$2"
      shift 2
      ;;
    -r | --root )
      # we create a new folder in this root folder, therefore this is called "base"
      BASE="$2"
      shift 2
      ;;
    -n | --name )
      NAME="$2"
      shift 2
      ;;
    -e | --endpoint )
      ENDPOINT="$2"
      shift 2
      ;;
    -d | --dns )
      DNS="$2"
      shift 2
      ;;
    -s | --subnets )
      SUBNETS="$2"
      shift 2
      ;;
    -- )
      shift
      break
      ;;
    *)
      echo "Internal error (geopt)!"
      usage;
      exit 1
      ;;
  esac
done

# Validate
# ______________________________________________________________________________

if [ -z "${NETWORK}" ]; then
  echo "ERROR: -a / --address is missing"
  echo ""
  usage
fi

if [ -z "${ENDPOINT}" ]; then
  echo "ERROR: -e / --endpoint is missing"
  echo ""
  usage
fi

ROOT="${BASE}/${NAME}"
# TODO: This could also be given as a parameter
SERVER="$HOSTNAME"
# Use default port if no Port is given
LISTENPORT="${ENDPOINT##*:}"
if [ -z "$LISTENPORT" ]; then
    LISTENPORT=51820
    ENDPOINT="${ENDPOINT}:$LISTENPORT}"
fi

if [[ -f "${BASE}/$NAME.conf" ]]; then
  echo "Error: The File: ${BASE}/$NAME.conf already exist! Does this tunnel already exist?"
  exit 1
fi

if [[ -d "${ROOT}" ]]; then
  echo "Error: The directory: ${ROOT} already exist! Does this tunnel already exist?"
  exit 1
fi

# Generate Keys
# ______________________________________________________________________________
mkdir -p "$ROOT"

pushd "$ROOT" || exit 1
wg genkey > "$SERVER.key"
chmod 0600 "$SERVER.key"
wg pubkey > "$SERVER.pub" < "$SERVER.key"
chmod 0644 "$SERVER.pub"

# Create wg-manage config files
# ______________________________________________________________________________

if [[ -n "$ENDPOINT" ]]; then
  echo "$ENDPOINT" > "$ROOT/endpoint"
fi
if [[ -n "$SUBNETS" ]]; then
  echo "$SUBNETS" > "$ROOT/subnets"
fi
if [[ -n "$DNS" ]]; then
  echo "$DNS" > "$ROOT/dns"
fi

echo "$NETWORK" > "$ROOT/last_address"

# Create actual server config
# ______________________________________________________________________________
{
    echo "##########"
    echo "# $SERVER "
    echo "##########"
    echo "# Generated by wg-manage. Version: $VERSION #"
    echo ""
    echo "[Interface]"
    echo "Address = $NETWORK"
    echo -n "PrivateKey = "
    cat "$SERVER.key"
    # TODO: Be able to change the listenport
    echo "ListenPort = $LISTENPORT"
    echo ""
} > "${BASE}/${NAME}.conf"

popd

# Inform user
# ______________________________________________________________________________
echo -e "\033[0;32mUse the following command to start the newly created VPN server:\033[0m"
echo "systemctl start wg-quick@${NAME}.service"
echo ""
echo -e "\033[0;32mUse the following command to enable the newly created VPN server:\033[0m"
echo "systemctl enable wg-quick@${NAME}.service"
