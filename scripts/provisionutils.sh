# Extracts the source URL

. ${PROVISION_SCRIPTS_FOLDER}/utils.sh

export GET_TYPES="wget curl"

function getArtifactGetPropertyValue(){

	artifactname="${1}"
	propsuffix="${2}"

	unset IFS
	unset prop

	for gettype in ${GET_TYPES}
	do	
		prop="`getPropertyValue ${artifactnamel}.${gettype}.${propsuffix}`"

		if [ ! -z "${prop}" ]
		then
			break
		fi
	done

	echo "${prop}"
}

function getGetType(){

	artifactname="${1}"
	propsuffix="${2}"

	unset IFS
	unset prop

	unset gt

	for gettype in ${GET_TYPES}
	do	
		prop="`getPropertyValue ${artifactnamel}.${gettype}.url`"

		if [ ! -z "${prop}" ]
		then
			gt=$gettype
			break
		fi
	done

	echo "${gt}"
}

