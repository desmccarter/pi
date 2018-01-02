. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

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

        javafolder="`tar -tzf ${targetdir}/${artifact} | sed -n s/'^\([^\/]*\)\/README.*$'/'\1'/p 2>/dev/null`"

	filetoedit="~/.bashrc"

	updateEnvironmentVariable "JAVA_HOME" "${unzipdir}/${javafolder}" "${filetoedit}"

	created="$?"

	info "Created/updated JRE_HOME in ${filetoedit}"

	# if JAVA_HOME did not already exist in this file,
	# then append then ammend PATH ...

	if [[ "$created" == "10" ]]
	then
		appendEnvironmentVariable "PATH" "\"\${JAVA_HOME}/bin:\${PATH}\"" "${filetoedit}"

		info "Updated PATH to include JAVA_HOME/bin (${unzipdir}/${javafolder}) in ${filetoedit}"
	elif [[ "$created" == "-10" ]]
	then	
		info "PATH variable NOT updated, since JAVA_HOME already existed"
	fi

	#  update JRE_HOME ...

	updateEnvironmentVariable "JRE_HOME" "\"\${JAVA_HOME}/jre\"" "${filetoedit}"

	info "Created/updated JRE_HOME in ${filetoedit}"

	info "update-alternatives --install ..."

	sudo update-alternatives --install "/usr/bin/java" "java" "${unzipdir}/${javafolder}/jre/bin/java" 1

	if [[ "$?" != "0" ]]
	then
		error "Failed to 'update-alternatives --install..."
		return 1
	fi

	info "update-alternatives --set ..."

	sudo update-alternatives --set "java" "${unzipdir}/${javafolder}/jre/bin/java"

	if [[ "$?" != "0" ]]
	then
		error "Failed to 'update-alternatives --set..."
		return 1
	fi

	return 1
}
