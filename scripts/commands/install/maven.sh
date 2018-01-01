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

	# Find out if JAVA_HOME already exists in ~/.bashrc. If so then replace it with new JAVA_HOME.
	# If JAVA_HOME does not exist, then simply append the export to ~/.bashrc ...

        rootfolder="`getRootFolderFromTarArchive ${targetdir}/${artifact}`"

	filetoedit="~/.bashrc"

	# Create/update MAVEN_HOME variable in ~/.bashrc ...
	updateEnvironmentVariable "MAVEN_HOME" "${unzipdir}/${rootfolder}" "${filetoedit}"

	# Extend PATH for MAVEN_HOME/bin ...
        created="$?"

        info "Created/updated MAVEN_HOME in ${filetoedit}"

        # if MAVEN_HOME did not already exist in this file,
        # then append then ammend PATH ...

        if [[ "$created" == "10" ]]
        then
                appendEnvironmentVariable "PATH" "\"\${MAVEN_HOME}/bin:\${PATH}\"" "${filetoedit}"

                info "Updated PATH to include MAVEN_HOME/bin (${unzipdir}/${rootfolder}) in ${filetoedit}"
        elif [[ "$created" == "-10" ]]
        then
                info "PATH variable NOT updated, since JAVA_HOME already existed"
        fi
}
