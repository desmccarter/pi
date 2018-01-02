. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

function createStartupScript(){

portnumber="$3"

if [[ ! -z "${portnumber}" ]]
then
	portarg=" --port ${portnumber}"
fi

cat << EOF > "${1}/run.sh"

java -jar "${1}/${2}" ${portarg}

EOF

if [[ "$?" != "0" ]]
then
	error "Failed to create wiremock start-up script"
	return 1
fi

chmod 755 "${1}/run.sh"

}


function runPostInstall(){

        artifactname="$1"

        sourceurl="`getArtifactGetPropertyValue ${artifactname} url`"

        targetdir="`getArtifactGetPropertyValue ${artifactname} dir`"

        artifact="`getFilenameFromUrl ${sourceurl}`"

        unzipdir=`getPropertyValue "${artifactname}.unzip.dir"`

	if [[ -z "${unzipdir}" ]]
	then
		error "${artifactname}.unzip.dir property not set. Please set this property to the output of install"
		return 1
	fi

	if [[ ! -f /tmp/${artifact} ]]
	then
		error "Artifact ${artifact} does not exist (for install ${artifactname})"
		return 1
	fi

	if [[ ! -d ${unzipdir} ]]
	then
		mkdir -p $unzipdir
	fi

	if [[ "$?" != "0" ]]
	then
		error "Failed to create target folder ${unzipdir}"
		return 1
	fi

	if [[ ! -f "${unzipdir}/${artifact}" ]]
	then
		runFunction "cp /tmp/${artifact} ${unzipdir}" "Successfully installed ${artifact}" "Failed to install ${artifact}"
        
		wiremockport=$(getPropertyValue "${artifactname}.port")
	
		createStartupScript "${unzipdir}" "${artifact}" "${wiremockport}"

		if [[ "$?" != "0" ]]
		then
			return 1
		fi
		
	else
		info "($artifactname} - ${artifact} already exists"
	fi

	return 0
}
