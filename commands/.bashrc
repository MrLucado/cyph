# Sourced by bashrc within Docker

NEWLINE=$'\n'

bindmount () {
	if [ "${CIRCLECI}" -o ! -d /cyph ] ; then
		rm -rf "${2}" 2> /dev/null
		cp -a "${1}" "${2}"
	else
		mkdir "${2}" 2> /dev/null
		sudo mount --bind "${1}" "${2}"
	fi
}

checkfail () {
	if (( $? )) ; then
		fail "${*}"
	fi
}

checkfailretry () {
	if (( $? )) ; then
		cd $(readlink -e /proc/${PPID}/cwd)
		$(ps -o args= ${$} | head -n2 | tail -n1)
		exit $?
	fi
}

download () {
	log "Downloading: ${*}"
	curl -s --compressed --retry 50 ${1} > ${2}
}

easyoptions () {
	source ~/easyoptions/easyoptions
}

fail () {
	if [ "${*}" ] ; then
		log "${*}\n\nFAIL"
	else
		log 'FAIL'
	fi
	exit 1
}

temporalCloudToken=""

ipfsAdd () {
	f="${PWD}/${1}"

	export ipfsAddOutput="$(
		curl -s https://api.pinata.cloud/pinning/pinFileToIPFS \
			-H "pinata_api_key: $(head -n1 ~/.cyph/pinata.key)" \
			-H "pinata_secret_api_key: $(tail -n1 ~/.cyph/pinata.key)" \
			-F "file=@${f}"
	)"

	hash="$(node -e 'console.log(JSON.parse(process.env.ipfsAddOutput).IpfsHash)')"

	if [ "${temporalCloudToken}" == "" ] ; then
		export temporalCloudAuth="$(
			curl -s https://api.temporal.cloud/v2/auth/login -d "{\"username\": \"$(
				head -n1 ~/.cyph/temporal.cloud.key
			)\", \"password\": \"$(
				tail -n1 ~/.cyph/temporal.cloud.key
			)\"}" 2> /dev/null
		)"

		temporalCloudToken="$(node -e "console.log(
			JSON.parse(process.env.temporalCloudAuth || '{}').token || ''
		)")"
	fi

	if [ "${hash}" ] ; then
		curl -s -X POST https://api.temporal.cloud/v2/ipfs/public/file/add \
			-H "Authorization: Bearer ${temporalCloudToken}" \
			-F 'hold_time=12' \
			-F "file=@${f}" \
		&> /dev/null

		curl -i -s -X POST https://www.eternum.io/api/pin/ \
			-H "Authorization: Bearer $(cat ~/.cyph/eternum.key)" \
			-H 'Content-Type: application/json' \
			-d "{\"hash\": \"${hash}\"}" \
		&> /dev/null

		echo "${hash}"
	else
		sleep 5
		ipfsAdd "${1}"
	fi
}

ipfsGatewaysCache=""

ipfsGateways () {
	if [ ! "${ipfsGatewaysCache}" ] ; then
		ipfsGatewaysCache="$(node -e "console.log(
			$(/cyph/commands/ipfsgateways.js).map(o => o.url).join('\\n')
		)")"
	fi

	echo -n "${ipfsGatewaysCache}"
}

ipfsWarmUp () {
	hash="${1}"
	shift

	gateway='https://gateway.ipfs.io/ipfs/:hash'
	if [ "${1}" ] ; then
		gateway="${1}"
		shift
	fi

	url="$(echo "${gateway}" | sed "s|:hash|${hash}|")"

	curl "${url}" &> /dev/null
}

ipfsWarmUpAll () {
	for gateway in $(ipfsGateways) ; do
		for f in "${@}" ; do
			ipfsWarmUp "$(cat "${f}")" "${gateway}"
		done &
	done
}

log () {
	echo -e "\n\n\n${*} ($(date))\n"
}

# Workaround for https://github.com/angular/angular-cli/issues/10529
ng () {
	node --max_old_space_size=8000 ./node_modules/@angular/cli/bin/ng "${@}"
}

notify () {
	/node_modules/.bin/notify --text "${*}" > /dev/null
	log "${*}"
}

pass () {
	if [ "${*}" ] ; then
		log "${*}\n\nPASS"
	else
		log 'PASS'
	fi
	exit 0
}

sha () {
	shasum -a 512 "${@}" | awk '{print $1}'
}

unbindmount () {
	unbindmountInternal "${1}"
	rm -rf "${1}"
}

unbindmountInternal () {
	if [ ! "${CIRCLECI}" -a -d /cyph ] ; then
		sudo umount "${1}"
	fi
}

export -f bindmount
export -f checkfail
export -f checkfailretry
export -f download
export -f easyoptions
export -f fail
export -f ipfsAdd
export -f ipfsGateways
export -f ipfsWarmUp
export -f ipfsWarmUpAll
export -f log
export -f ng
export -f notify
export -f pass
export -f sha
export -f unbindmount
export -f unbindmountInternal


export FIREBASE_CONFIG='{}'

if [ -f ~/.cyph/notify.key ] && [ -f /node_modules/.bin/notify ] ; then
	rm ~/.notifyreg 2> /dev/null
	/node_modules/.bin/notify -r "$(cat ~/.cyph/notify.key)" > /dev/null
fi


# Setup for documentation generation
if [ -d /cyph ] ; then
	cp -f /cyph/LICENSE /cyph/README.md /cyph/cyph.app/
	echo -e '\n---\n' >> /cyph/cyph.app/README.md
	cat /cyph/PATENTS >> /cyph/cyph.app/README.md
fi


# Workaround for localhost not working in CircleCI
if [ "${CIRCLECI}" ] ; then
	sed -i 's|localhost|0.0.0.0|g' /cyph/commands/serve.sh /cyph/*/protractor.conf.js
fi
