#!/usr/bin/env bash
set -e

# This script starts N nodes (TODO N instead of 5) and waits for ctrl-c to shutdown the process group of AvalancheGo processes
# Uses data directory to store all AvalancheGo data neatly in one location with minimal config overhead
if ! [[ "$0" =~ scripts/run.sh ]]; then
  echo "must be run from repository root, but got $0"
  exit 255
fi

# Load the versions
SUBNET_EVM_PATH=$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  cd .. && pwd
)
source "$SUBNET_EVM_PATH"/scripts/versions.sh

# Load the constants
source "$SUBNET_EVM_PATH"/scripts/constants.sh

# Set up avalanche binary path and assume build directory is set
AVALANCHEGO_BUILD_PATH=${AVALANCHEGO_BUILD_PATH:-"$GOPATH/src/github.com/ava-labs/avalanchego/build"}
AVALANCHEGO_PATH=${AVALANCHEGO_PATH:-"$AVALANCHEGO_BUILD_PATH/avalanchego"}
AVALANCHEGO_PLUGIN_DIR=${AVALANCHEGO_PLUGIN_DIR:-"$AVALANCHEGO_BUILD_PATH/plugins"}
DATA_DIR=${DATA_DIR:-/tmp/subnet-evm-start-node/$(date "+%Y-%m-%d%:%H:%M:%S")}

# Base64 encoded Staking TLS Cert and Key File Contents for AvalancheGo local staking node 1 (published key content used for testing)
STAKING_TLS_KEY_FILE_CONTENT="LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlKS0FJQkFBS0NBZ0VBeW1Fa2NQMXRHS1dCL3pFMElZaGEwZEp2UFplc2s3c3k2UTdZN25hLytVWjRTRDc3CmFwTzJDQnB2NXZaZHZjY0VlQ2VhKzBtUnJQdTlNZ1hyWkcwdm9lejhDZHE1bGc4RzYzY2lTcjFRWWFuL0pFcC8KbFZOaTNqMGlIQ1k5ZmR5dzhsb1ZkUitKYWpaRkpIQUVlK2hZZmFvekx3TnFkTHlldXZuZ3kxNWFZZjBXR3FVTQpmUjREby85QVpnQ2pLMkFzcU9RWVVZb2Zqcm9JUEdpdUJ2VDBFeUFPUnRzRTFsdGtKQjhUUDBLYVJZMlhmMThFCkhpZGgrcm0xakJYT1g3YlgrZ002U2J4U0F3YnZ5UXdpbG9ncnVadkxlQmkvTU5qcXlNZkNiTmZaUmVHR0JObnEKSXdxM3FvRDR1dUV0NkhLc0NyQTZNa2s4T3YrWWlrT1FWR01GRjE5OCt4RnpxZy9FakIzbjFDbm5NNCtGcndHbQpTODBkdTZsNXVlUklFV0VBQ0YrSDRabU96WDBxS2Qxb2RCS090dmlSNkRQOVlQbElEbDVXNTFxV1BlVElIZS8zCjhBMGxpN3VDTVJOUDdxdkZibnlHM3d1TXEyUEtwVTFYd0gzeU5aWFVYYnlZenlRVDRrTkFqYXpwZXRDMWFiYVoKQm5QYklSKzhHZG16OUd4SjJDazRDd0h6c3cvRkxlOVR0Z0RpR3ZOQU5SalJaZUdKWHZ6RWpTVG5FRGtxWUxWbgpVUk15RktIcHdJMzdzek9Ebms2K0hFWU9QbFdFd0tQU2h5cTRqZFE3bnNEY3huZkZveWdGUjVuQ0RJNmlFaTA1CmN6SVhiSFp2anBuME9qcjhsKzc5Qmt6Z1c0VDlQVFJuTU1PUU5JQXMxemRmQlV1YU1aOFh1amh2UTlNQ0F3RUEKQVFLQ0FnRUF1VU00TXQ4cjhiWUJUUFZqL1padlhVakFZS2ZxYWNxaWprcnpOMGtwOEM0Y2lqWnR2V0MrOEtnUwo3R0YzNnZTM0dLOVk1dFN3TUtTNnk0SXp2RmxmazJINFQ2VVU0MU9hU0E5bEt2b25EV0NybWpOQW5CZ2JsOHBxCjRVMzRXTEdnb2hycExiRFRBSkh4dGF0OXoxZ2hPZGlHeG5EZ0VVRmlKVlA5L3UyKzI1anRsVEttUGhzdHhnRXkKbUszWXNTcDNkNXhtenE0Y3VYRi9mSjF2UWhzWEhETHFIdDc4aktaWkErQVdwSUI1N1ZYeTY3eTFiazByR25USwp4eFJuT2FPT0R1YkpneHFNRVExV2tMczFKb3c5U3NwZDl2RGdoUHp0NFNOTXpvckI4WURFU01pYjE3eEY2aVhxCmpGajZ4NkhCOEg3bXA0WDNSeU1ZSnVvMnc2bHB6QnNFbmNVWXBLaHFNYWJGMEkvZ2lJNVZkcFNEdmtDQ09GZW4KbldaTFY5QWkveDd0VHEvMEYrY1ZNNjlNZ2ZlOGlZeW1xbGZkNldSWklUS2ZWaU5IQUxsRy9QcTl5SEpzejdOZwpTOEJLT0R0L3NqNFEweEx0RkRUL0RtcFA1MGlxN1NpUzE0b2JjS2NRcjhGQWpNL3NPWS9VbGc0TThNQTdFdWdTCnBESndMbDZYRG9JTU1DTndaMUhHc0RzdHpteDVNZjUwYlM0dGJLNGlaemNwUFg1UkJUbFZkbzlNVFNnbkZpenAKSWkxTmpITHVWVkNTTGIxT2pvVGd1MGNRRmlXRUJDa0MxWHVvUjhSQ1k2aVdWclVINEdlem5pN2NrdDJtSmFOQQpwZDYvODdkRktFM2poNVQ2alplSk1KZzVza1RaSFNvekpEdWFqOXBNSy9KT05TRDA2c0VDZ2dFQkFQcTJsRW1kCmcxaHBNSXFhN2V5MXVvTGQxekZGemxXcnhUSkxsdTM4TjY5bVlET0hyVi96cVJHT3BaQisxbkg3dFFKSVQvTDEKeExOMzNtRlZxQ3JOOHlVbVoraVVXaW9hSTVKWjFqekNnZW1WR2VCZ29kd1A5TU9aZnh4ckRwMTdvVGRhYmFFcQo3WmFCWW5ZOHhLLzRiQ3h1L0I0bUZpRjNaYThaVGQvKzJ5ZXY3Sk0rRTNNb3JXYzdyckttMUFwZmxmeHl0ZGhPCkpMQmlxT2Nxb2JJM2RnSHl6ZXNWYjhjVDRYQ3BvUmhkckZ3b3J0MEpJN3J5ZmRkZDQ5dk1KM0VsUmJuTi9oNEYKZjI0Y1dZL3NRUHEvbmZEbWVjMjhaN25WemExRDRyc3pOeWxZRHZ6ZGpGMFExbUw1ZEZWbnRXYlpBMUNOdXJWdwpuVGZ3dXlROFJGOVluWU1DZ2dFQkFNNmxwTmVxYWlHOWl4S1NyNjVwWU9LdEJ5VUkzL2VUVDR2Qm5yRHRZRis4Cm9oaUtnSXltRy92SnNTZHJ5bktmd0pPYkV5MmRCWWhDR0YzaDl6Mm5jOUtKUUQvc3U3d3hDc2RtQnM3WW9EaU0KdXpOUGxSQW1JMFFBRklMUENrNDh6L2xVUWszci9NenUwWXpSdjdmSTRXU3BJR0FlZlZQRHF5MXVYc0FURG9ESgphcmNFa05ENUxpYjg5THg3cjAyRWV2SkpUZGhUSk04bUJkUmw2d3BOVjN4QmR3aXM2N3VTeXVuRlpZcFNpTXc3CldXaklSaHpoTEl2cGdENzhVdk52dUppMFVHVkVqVHFueHZ1VzNZNnNMZklrODBLU1IyNFVTaW5UMjd0Ly94N3oKeXpOa283NWF2RjJobTFmOFkvRXBjSEhBYXg4TkFRRjV1dVY5eEJOdnYzRUNnZ0VBZFMvc1JqQ0syVU5wdmcvRwowRkx0V0FncmNzdUhNNEl6alZ2SnMzbWw2YVYzcC81dUtxQncwVlVVekdLTkNBQTRUbFhRa09jUnh6VnJTNkhICkZpTG4yT0NIeHkyNHExOUdhenowcDdmZkUzaHUvUE1PRlJlY04rVkNoZDBBbXRuVHRGVGZVMnNHWE1nalp0TG0KdUwzc2lpUmlVaEZKWE9FN05Vb2xuV0s1dTJZK3RXQlpwUVZKY0N4MGJ1c054NytBRXR6blpMQzU4M3hhS0p0RApzMUs3SlJRQjdqVTU1eHJDMEc5cGJrTXlzbTBOdHlGemd3bWZpcEJIVmxDcHl2ZzZEQ3hkOEZodmhOOVplYTFiCmZoa2MwU0pab3JIQzVoa3FweWRKRG1sVkNrMHZ6RUFlUU00Qzk0WlVPeXRibmpRbm1YcDE0Q05BU1lxTFh0ZVEKdWVSbzB3S0NBUUFHMEYxMEl4Rm0xV290alpxdlpKZ21RVkJYLzBmclVQY3hnNHZwQjVyQzdXUm03TUk2WVF2UgpMS0JqeldFYWtIdjRJZ2ZxM0IrZms1WmNHaVJkNnhTZG41cjN3S1djR2YzaC8xSkFKZEo2cXVGTld0VnVkK04zCnpZemZsMVllcUZDdlJ3RDhzc2hlTlkzQlYvVTdhU3ROZDJveTRTNSt3WmYyWW9wTFNSV1VWNC9tUXdkSGJNQUIKMXh0Mno1bEROQmdkdng4TEFBclpyY1pKYjZibGF4RjBibkF2WUF4UjNoQkV6eFovRGlPbW9GcGRZeVUwdEpRVQpkUG1lbWhGZUo1UHRyUnh0aW1vaHdnQ0VzVC9UQVlodVVKdVkyVnZ6bkVXcHhXdWNiaWNLYlQySkQwdDY3bUVCCnNWOSs4anFWYkNsaUJ0ZEJhZHRib2hqd2trb1IzZ0J4QW9JQkFHM2NadU5rSVdwRUxFYmVJQ0tvdVNPS04wNnIKRnMvVVhVOHJvTlRoUFI3dlB0amVEMU5ETW1VSEpyMUZHNFNKclNpZ2REOHFOQmc4dy9HM25JMEl3N2VGc2trNQo4bU5tMjFDcER6T04zNlpPN0lETWo1dXlCbGoydCtJeGwvdUpZaFlTcHVOWHlVVE1tK3JrRkowdmRTVjRmakxkCkoybTMwanVZbk1pQkJKZjdkejVNOTUrVDB4aWNHV3lWMjR6VllZQmJTbzBOSEVHeHFlUmhpa05xWk5Qa29kNmYKa2ZPSlpHYWxoMkthSzVSTXBacEZGaFova1c5eFJXTkpaeUNXZ2tJb1lrZGlsTXVJU0J1M2xDcms4cmRNcEFMMAp3SEVjcTh4d2NnWUNTMnFrOEh3anRtVmQzZ3BCMXk5VXNoTXIzcW51SDF3TXBVNUMrbk0yb3kzdlNrbz0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0K"
STAKING_TLS_CRT_FILE_CONTENT="LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZOekNDQXg4Q0NRQzY4N1hGeHREUlNqQU5CZ2txaGtpRzl3MEJBUXNGQURCL01Rc3dDUVlEVlFRR0V3SlYKVXpFTE1Ba0dBMVVFQ0F3Q1Rsa3hEekFOQmdOVkJBY01Ca2wwYUdGallURVFNQTRHQTFVRUNnd0hRWFpoYkdGaQpjekVPTUF3R0ExVUVDd3dGUjJWamEyOHhEREFLQmdOVkJBTU1BMkYyWVRFaU1DQUdDU3FHU0liM0RRRUpBUllUCmMzUmxjR2hsYmtCaGRtRnNZV0p6TG05eVp6QWdGdzB4T1RBM01ESXhOakV5TVRWYUdBOHpNREU1TURjeE1ERTIKTVRJeE5Wb3dPakVMTUFrR0ExVUVCaE1DVlZNeEN6QUpCZ05WQkFnTUFrNVpNUkF3RGdZRFZRUUtEQWRCZG1GcwpZV0p6TVF3d0NnWURWUVFEREFOaGRtRXdnZ0lpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElDRHdBd2dnSUtBb0lDCkFRREtZU1J3L1cwWXBZSC9NVFFoaUZyUjBtODlsNnlUdXpMcER0anVkci81Um5oSVB2dHFrN1lJR20vbTlsMjkKeHdSNEo1cjdTWkdzKzcweUJldGtiUytoN1B3SjJybVdEd2JyZHlKS3ZWQmhxZjhrU24rVlUyTGVQU0ljSmoxOQozTER5V2hWMUg0bHFOa1VrY0FSNzZGaDlxak12QTJwMHZKNjYrZURMWGxwaC9SWWFwUXg5SGdPai8wQm1BS01yCllDeW81QmhSaWgrT3VnZzhhSzRHOVBRVElBNUcyd1RXVzJRa0h4TS9RcHBGalpkL1h3UWVKMkg2dWJXTUZjNWYKdHRmNkF6cEp2RklEQnUvSkRDS1dpQ3U1bTh0NEdMOHcyT3JJeDhKczE5bEY0WVlFMmVvakNyZXFnUGk2NFMzbwpjcXdLc0RveVNUdzYvNWlLUTVCVVl3VVhYM3o3RVhPcUQ4U01IZWZVS2Vjemo0V3ZBYVpMelIyN3FYbTU1RWdSCllRQUlYNGZobVk3TmZTb3AzV2gwRW82MitKSG9NLzFnK1VnT1hsYm5XcFk5NU1nZDcvZndEU1dMdTRJeEUwL3UKcThWdWZJYmZDNHlyWThxbFRWZkFmZkkxbGRSZHZKalBKQlBpUTBDTnJPbDYwTFZwdHBrR2M5c2hIN3daMmJQMApiRW5ZS1RnTEFmT3pEOFV0NzFPMkFPSWE4MEExR05GbDRZbGUvTVNOSk9jUU9TcGd0V2RSRXpJVW9lbkFqZnV6Ck00T2VUcjRjUmc0K1ZZVEFvOUtIS3JpTjFEdWV3TnpHZDhXaktBVkhtY0lNanFJU0xUbHpNaGRzZG0rT21mUTYKT3Z5WDd2MEdUT0JiaFAwOU5HY3d3NUEwZ0N6WE4xOEZTNW94bnhlNk9HOUQwd0lEQVFBQk1BMEdDU3FHU0liMwpEUUVCQ3dVQUE0SUNBUUFxTDFUV0kxUFRNbTNKYVhraGRUQmU4dHNrNytGc0hBRnpUY0JWQnNCOGRrSk5HaHhiCmRsdTdYSW0rQXlHVW4wajhzaXo4cW9qS2JPK3JFUFYvSW1USDVXN1EzNnJYU2Rndk5VV3BLcktJQzVTOFBVRjUKVDRwSCtscFlJbFFIblRhS011cUgzbk8zSTQwSWhFaFBhYTJ3QXd5MmtEbHo0NmZKY3I2YU16ajZaZzQzSjVVSwpaaWQrQlFzaVdBVWF1NVY3Q3BDN0dNQ3g0WWRPWldXc1QzZEFzdWc5aHZ3VGU4MWtLMUpvVEgwanV3UFRCSDB0CnhVZ1VWSVd5dXdlTTFVd1lGM244SG13cTZCNDZZbXVqaE1ES1QrM2xncVp0N2VaMVh2aWVMZEJSbFZRV3pPYS8KNlFZVGtycXdQWmlvS0lTdHJ4VkdZams0MHFFQ05vZENTQ0l3UkRnYm5RdWJSV3Jkc2x4aUl5YzVibEpOdU9WKwpqZ3Y1ZDJFZVVwd1VqdnBadUVWN0ZxUEtHUmdpRzBqZmw2UHNtczlnWVVYZCt5M3l0RzlIZW9ETm1MVFNUQkU0Cm5DUVhYOTM1UDIveE91b2s2Q3BpR3BQODlEWDd0OHlpd2s4TEZOblkzcnZ2NTBuVnk4a2VyVmRuZkhUbW9NWjkKL0lCZ29qU0lLb3Y0bG1QS2RnekZmaW16aGJzc1ZDYTRETy9MSWhURjdiUWJIMXV0L09xN25wZE9wTWpMWUlCRQo5bGFndlJWVFZGd1QvdXdyQ2NYSENiMjFiL3B1d1Y5NFNOWFZ3dDdCaGVGVEZCZHR4SnJSNGpqcjJUNW9kTGtYCjZuUWNZOFYyT1Q3S094bjBLVmM2cGwzc2FKVExtTCtILzNDdEFhbzlOdG11VURhcEtJTlJTVk55dmc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="

mkdir -p $DATA_DIR

# Set the config file contents for the path passed in as the first argument
function _set_config(){
  cat <<EOF >$1
  {
    "network-id": "local",
    "staking-enabled": false,
    "health-check-frequency": "5s",
    "plugin-dir": "$AVALANCHEGO_PLUGIN_DIR"
  }
EOF
}

DATA_DIRS=()
CMDS=()
for (( i=0; i <5; i++ ))
do
  NODE_NAME=node$(($i+1))
  NODE_DATA_DIR="$DATA_DIR/$NODE_NAME"
  DATA_DIRS+=("$NODE_DATA_DIR")
  echo "Creating data directory: $NODE_DATA_DIR"
  mkdir -p $NODE_DATA_DIR
  NODE_CONFIG_FILE_PATH="$NODE_DATA_DIR/config.json"
  _set_config $NODE_CONFIG_FILE_PATH
  
  CMD="$AVALANCHEGO_PATH --data-dir=$NODE_DATA_DIR --config-file=$NODE_CONFIG_FILE_PATH"
  if [ $i -gt 0 ]; then
    echo "Adding CLI options for node$(($i+1))"
    CMD="$CMD --staking-port=$((9651+2*$i)) --http-port=$((9650+2*$i)) --bootstrap-ips=127.0.0.1:9651 --bootstrap-ids=NodeID-7Xhw2mDxuDS44j42TCB6U5579esbSt3Lg"
  else
    CMD="$CMD --staking-tls-key-file-content=$STAKING_TLS_KEY_FILE_CONTENT --staking-tls-cert-file-content=$STAKING_TLS_CRT_FILE_CONTENT"
  fi
  
  echo "Created command $CMD"
  CMDS+=("$CMD")
done


echo "Starting AvalancheGo network with the commands:"
echo ""
for (( i=0; i<5; i++ ))
do
  echo "CMD $i: ${CMDS[i]}"
  echo ""
done

# cleanup sends SIGINT to each tracked process
function cleanup_process_group(){
  echo "Terminating AvalancheGo network process group"
  kill 0 # This kills a process group rather than a process with the ID 0, used to kill subshell to cleanup below
}

function execute_cmd() {
  echo "Executing command: $@"
  $@
}

# TODO change from executing each CMD by index to iterate and execute each command within the subshell
# Trap SIGINT and cleanup the processes within this subshell after receiving SIGINT (ctrl-c)
(trap 'cleanup_process_group' SIGINT; execute_cmd ${CMDS[0]} & execute_cmd ${CMDS[1]} & execute_cmd ${CMDS[2]} & execute_cmd ${CMDS[3]} & execute_cmd ${CMDS[4]} & wait)
