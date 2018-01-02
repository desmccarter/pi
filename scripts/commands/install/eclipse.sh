. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

eclipsedownloadurl="http://download.eclipse.org/eclipse/downloads"

function runPostInstall(){

        artifactname="$1"

        sourceurl="`getArtifactGetPropertyValue ${artifactname} url`"

        targetdir="`getArtifactGetPropertyValue ${artifactname} dir`"

        artifact="`getFilenameFromUrl ${sourceurl}`"

        unzipdir=`getPropertyValue "${artifactname}.unzip.dir"`

	operatingsystem=$(getPropertyValue "${artifactname}.operatingsystem")
	processortype=$(getPropertyValue "${artifactname}.processortype")

	if [[ -z "${operatingsystem}" ]]
	then
		error "Please specify either 'linux' or 'win32' for ${artifactname}.operatingsystem"
		return 1
	fi	

	case $operatingsystem in
		"linux") o1=$operatingsystem;;
		"win32") o1=$operatingsystem;;
	esac

	if [[ -z "${processortype}" ]]
	then
		error "Please specify ${artifactname}.processortype (e.g. x86_64)"
		return 1
	fi	

	if [[ -z "${unzipdir}" ]]
	then
		error "${artifactname}.unzip.dir property not set. Please set this property to the output of install"
		return 1
	fi

	mirror=$(getPropertyValue "${artifactname}.mirror")

	if [[ -z "${mirror}" ]]
	then
		error "${artifactname}.mirror not set in ${PROPERTIES_FILE}"
		return 1
	fi

	release=$(curl -a ${eclipsedownloadurl}/ 2>/dev/null | sed -n s/"^.*a[ ]*href=\"\([^\"]*\)\".*title=\"Latest Release.*$"/"\1"/p)

	artifact=$(curl -a ${eclipsedownloadurl}/${release} 2>/dev/null | grep eclipse-platform | sed s/"^.*>\([^<]*\)<\/a.*$"/"\1"/g | grep $o1 | grep "${processortype}")

	if [[ ! -f /tmp/${artifact} ]]
	then
		info "Downloading $artifact for ${artifactname} install ..."

		executecurl ${mirror}/${release}/${artifact} /tmp 

		if [[ "$?" == "0" ]]
		then
			info "Successfully downloaded ${artifact}"
		else
			error "Failed to download artifact ${artifact}"
			return 1
		fi
	fi

	if [[ ! -d ${unzipdir} ]]
	then
		mkdir -p $unzipdir
	fi

	extension=$(echo ${artifact} | sed s/"^.*\.\([a-z|A-Z]*\)$"/"\1"/g)

	info "Extracting ${extension} ${artifact} to ${unzipdir} ..."

	if [[ "${extension}" == "gz" ]]
	then
		prevdir="`pwd`"

		cd "${unzipdir}"

		tar -zxvf /tmp/${artifact} >/dev/null 2>&1

		if [[ "$?" != "0" ]]
		then
			error "Failed to extract (tar) ${artifact} to ${unzipdir}"

			cd "${prevdir}"
		
			return 1
		else
			info "Extracted (tar) ${artifact} to ${unzipdir}"

			cd "${prevdir}"
		fi


	elif [[ "${extension}" == "zip" ]]
	then
		unzip -d "${unzipdir}" -o /tmp/${artifact} >/dev/null

		if [[ "$?" != "0" ]]
		then
			error "Failed to extract (zip) ${artifact} to ${unzipdir}"

			cd "${prevdir}"
		
			return 1
		else
			info "Extracted (zip) ${artifact} to ${unzipdir}"

			cd "${prevdir}"
		fi
	else
		error "Unknown archive type ${extension}"
		return 1
	fi
}
