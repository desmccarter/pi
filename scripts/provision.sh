#!/bin/bash

ARGS="${*}"

# Make sure scripts folder var is defined ...

if [[ -z "${PROVISION_SCRIPTS_FOLDER}" ]]
then
	echo "[ERR] PROVISION_SCRIPTS_FOLDER has not been defined. Please run init.sh and run THIS script again"
	exit 1
fi

# Make sure scripts folder exists ...

if [[ ! -f "${PROVISION_SCRIPTS_FOLDER}/utils.sh" ]]
then
	echo "[ERR] Cannot find utils.sh. Please make sure the PROVISION_SCRIPTS_FOLDER variable is set correctly (run/re-run init.sh if needbe)"
	exit 1
fi

# Import utils ...

. ${PROVISION_SCRIPTS_FOLDER}/utils.sh
. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

# Set to default properties file ...
export PROPERTIES_FILE="${PROVISION_SCRIPTS_FOLDER}/provision.properties"

function importProperties(){

	for propname in `getPropertyNames "-all" "${PROPERTIES_FILE}"`
	do
		varname="`echo ${propname} | sed s/'[\.|\-]*'/''/g`"

		export $varname="`getPropertyValue ${propname} ${PROPERTIES_FILE}`"

		export ${varname}="`eval echo ${!varname}`"

		debug "${varname} = ${!varname}"
	done
}

function processArgs(){

	while [[ ! -z "$1" ]]
	do
		if [[ "${1}" == "-propertiesfile" ]]
		then
			shift

			if [[ -z "${1}" ]]
			then
				error "-propertiesfile requires an argument"
				usage
				exit 1
			fi

			export PROPERTIES_FILE="${1}"
		elif [[ "${1}" == "-setupfile" ]]
		then
			shift

			if [[ -z "${1}" ]]
			then
				error "-setupfile requires an argument"
				usage
				exit 1
			fi

			export SETUP_FILE="${1}"
		fi

		shift
	done
}

function usage(){

	usagemsg "`basename ${0}` -setupfile <the setup file> -propertiesfile <the properties file>"

	unset IFS

	for s in $(ls ${PROVISION_SCRIPTS_FOLDER})
	do
		echo $s
	done
}

function verifyArgs(){

	if [[ -z "${SETUP_FILE}" ]]
	then
		error "Setup file not given"
		usage
		exit 1
	fi
}

function verifyFileExists(){

	file="$1"
	filedescription="$2"

	# Check filename given ...

	if [[ -z "${file}" ]]
	then
		error "File not supplied."

		usage

		exit 1

	fi

	# Make sure file exists ...

	if [[ ! -f "${file}" ]]
	then
		echo "[ERR] ${filedescription} ${file} does not exist!"

		usage

		exit 1
	fi
}

function getCommand(){

	line="$1"

	echo "${line}" | sed s/"^\([^ |	]*\).*$"/"\1"/g
}

function getArgument(){

	line="$1"

	echo "${line}" | sed s/"^[^ |	]*\(.*\)$"/"\1"/g
}

function validateExpression(){

	command="$1"

	if [[ -z ${command} ]]
	then
		error "COMMAND not given"
		exit 1
	fi

	line="$2"

	if [[ -z ${line} ]]
	then
		error "'LINE' not given"
		exit 1
	fi

	setupfile="$3"

	if [[ ! -f ${setupfile} ]]
	then
		error "Setup file '${setupfile}' does not exist"
		exit 1
	fi

	commanddir="${PROVISION_SCRIPTS_FOLDER}/commands/${command}"

	if [[ ! -d "${commanddir}" ]]
	then
		error "Unknown command[1] '${command}' found in setup script ${setupfile}"
		exit 1
	fi
	
	if [[ ! -f "${commanddir}/${command}.sed" ]]
	then
		error "Unknown command[2] '${command}' found in setup script ${setupfile}"
		exit 1
	fi

	sedresult=`echo ${line} | sed -n -f "${PROVISION_SCRIPTS_FOLDER}/commands/${command}/${command}.sed"`

	echo ${sedresult}
}


function processValidatedExpression(){

command="${1}"
file="${2}"

shift
shift

validatedExpresssionResult="${*}"

	executionscript="${PROVISION_SCRIPTS_FOLDER}/commands/${command}/${command}.sh"

	if [[ ! -f "${executionscript}" ]]
	then	
		error "Cannot find execution command for ${command}"

		return 1
	else
		. "${executionscript}"

		run ${validatedExpresssionResult}

		if [[ "$?" != "0" ]]
		then
			return 1
		else
			return 0
		fi
	fi
}

function processSetupFile(){

	# Import all properties ...

	importProperties

	# Validate expressions and execute them ...

	SETUP_FILE="$1"

	IFS=$'\n'

	for line in `cat ${SETUP_FILE}`
	do
		command=`getCommand ${line}`

		if [[ -z "${command}" ]]
		then
			error "No command found in file ${SETUP_FILE}"
			exit 1
		fi

		hash=`echo $command | sed s/'^[ |	]*\(.\).*'/'\1'/g`

		if [ ! -z "${hash}" -a "${hash}" != "#" ]
		then
			info "**********************************> '${line}' ..."

			validatedExpression="`validateExpression "${command}" "${line}" ${SETUP_FILE}`"
	
			if [[ -z "${validatedExpression}" ]]
			then
				error "-----> Unknown command '${command}' expressed in set-up file ${SETUP_FILE}"
				exit 1
			fi
	
			processValidatedExpression "${command}" "${SETUP_FILE}" ${validatedExpression}
	
			if [[ "$?" != "0" ]]
			then
				error "-----> Execution of '${line}' failed. Stopping setup."
				exit 1
			fi
		fi
	done
}

processArgs ${ARGS}

verifyArgs
echo 1

verifyFileExists "${SETUP_FILE}" "Set-up file"
verifyFileExists "${PROPERTIES_FILE}" "Properties file"

processSetupFile "${SETUP_FILE}"

