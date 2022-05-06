#!/bin/bash

readonly script_name=$(basename "${0}")

usage() {
	cat <<EOF
Usage: ${script_name} [OPTIONS]
    -u Device UUID
    -a Balena API endpoint
    -r Balena registry endpoint
    -t Balena API token
    -h Display usage
EOF
}

main() {
	while getopts "hu:t:r:a:" c; do
		case "${c}" in
			u) UUID="${OPTARG:-}";;
			a) API_ENDPOINT=${OPTARG:-};;
			r) REGISTRY_ENDPOINT=${OPTARG:-};;
			t) API_KEY=${OPTARG:-};;
			h) usage;exit 1;;
			*) usage;exit 1;;
		esac
	done

	if [ -z "${UUID}" ]; then
		echo "Missing device UUID"
	elif [ -z "${REGISTRY_ENDPOINT}" ]; then
		echo "Missing registry endpoint"
	elif [ -z "${API_ENDPOINT}" ]; then
		echo "Missing API endpoint"
	elif [ -z "${API_KEY}" ]; then
		echo "Missing API token"
	fi
	if [ -z "${UUID}" ] ||
		[ -z "${REGISTRY_ENDPOINT}" ] ||
		[ -z "${API_ENDPOINT}" ]||
		[ -z "${API_KEY}" ]; then
			usage
			exit 1
	fi

	if [ ! -d "/out" ]; then
		echo "Please bind mount an output directory into /out"
		exit 1
	fi

	DIAGNOSTICS_URL="https://raw.githubusercontent.com/balena-io-modules/device-diagnostics/master/scripts/"
	DIAGNOSTICS_SCRIPTS=("diagnose.sh" "checks.sh")
	NOW=$(date +"%Y-%m-%d-%H-%M")
	echo "[INFO] Logging into ${API_ENDPOINT/https:\/\/api./}"
	export BALENARC_BALENA_URL=${API_ENDPOINT/https:\/\/api./}

	balena login --token "${API_KEY}" > /dev/null 2>&1
	balena support enable --device "${UUID}" --duration 1h > /dev/null 2>&1

	DEVICE_IP=$(node mdns-resolve "${UUID:0:7}.local")
	if [ -z "${DEVICE_IP}" ]; then
		# Maybe it had connected to the cloud
		DEVICE_IP=$(balena device "${UUID}" | grep "IP ADDRESS" | cut -f2 -d":" | sed 's/^ *//' | sed 's/ *$//' | cut -f1 -d" ")
	fi
	if [ -z "${DEVICE_IP}" ]; then
		echo "[${script_name} Unable to resolve ${UUID:0:7}.local]"
		exit 1
	fi

	for script in "${DIAGNOSTICS_SCRIPTS[@]}"; do
		curr_script=$(echo "${script}" | cut -f1 -d'.')
		DIAGNOSTICS_LOG="device_${curr_script}_${UUID}_${NOW}.log"
		echo && echo "[${script_name}] Will run ${curr_script} on local device ${UUID} - ${DEVICE_IP}. This may take a few minutes."
		echo "wget --quiet ${DIAGNOSTICS_URL}${script} -O /tmp/${script} && bash /tmp/${script} 2>/dev/null | tee /tmp/${DIAGNOSTICS_LOG} > /dev/null" | balena ssh "${DEVICE_IP}"
		echo "cat /tmp/${DIAGNOSTICS_LOG}" | balena ssh "${DEVICE_IP}" > "/out/${DIAGNOSTICS_LOG}"
		echo "[${script_name}] Finished running ${curr_script} on device ${UUID}."
		echo "rm /tmp/${DIAGNOSTICS_LOG}" | balena ssh "${DEVICE_IP}"
		echo "Log file saved as ${DIAGNOSTICS_LOG}"
		chmod 777 "/out/${DIAGNOSTICS_LOG}"
	done
}

main "${@}"
