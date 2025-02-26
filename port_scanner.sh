#!/bin/bash

# Check for arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <scan_type> <host1> [host2] ... [hostN] [start_port] [end_port]"
  echo "Scan type: tcp or udp"
  echo "Example: $0 tcp 192.168.1.1 192.168.1.2 1 1024"
  exit 1
fi

# Scan type (tcp or udp)
SCAN_TYPE=$1
shift

# Get list of hosts and port range
HOSTS=()
PORT_START=1
PORT_END=1024

# Separate arguments into hosts and ports
for arg in "$@"; do
  if [[ $arg =~ ^[0-9]+$ ]]; then
    if [ -z "$PORT_START_SET" ]; then
      PORT_START=$arg
      PORT_START_SET=1
    else
      PORT_END=$arg
    fi
  else
    HOSTS+=("$arg")
  fi
done

# Function to scan a single port
scan_port() {
  local host=$1
  local scan_type=$2
  local port=$3

  # Check port with a 0.1-second timeout
  if [ "$scan_type" == "tcp" ]; then
    timeout 0.1 bash -c "echo >/dev/$scan_type/$host/$port" 2>/dev/null
  elif [ "$scan_type" == "udp" ]; then
    timeout 0.1 bash -c "echo >/dev/$scan_type/$host/$port" 2>/dev/null
  fi

  if [ $? -eq 0 ]; then
    echo "Host: $host, Port $port is open"
  fi
}

# Function to scan ports on a single host
scan_host() {
  local host=$1
  local scan_type=$2
  local port_start=$3
  local port_end=$4
  local total_ports=$((port_end - port_start + 1))
  local current_port=0

  echo "Scanning host: $host (ports $port_start-$port_end, type: $scan_type)"

  # Scan ports in parallel
  for ((port=port_start; port<=port_end; port++)); do
    current_port=$((current_port + 1))
    # Progress bar
    echo -ne "Progress: $((current_port * 100 / total_ports))%\r"

    # Scan the port in the background
    scan_port "$host" "$scan_type" "$port" &
  done

  # Wait for all background processes to finish
  wait
  echo "Scanning host $host completed."
}

# Start scanning for each host in the background
for host in "${HOSTS[@]}"; do
  scan_host "$host" "$SCAN_TYPE" "$PORT_START" "$PORT_END" &
done

# Wait for all background processes to finish
wait
echo "All scans completed."
