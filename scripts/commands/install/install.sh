. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

function run(){

artifactname="$1"

sourceurl="`getArtifactGetPropertyValue ${artifactnamel} url`"

targetdir="`getArtifactGetPropertyValue ${artifactnamel} dir`"

artifact="`getFilenameFromUrl ${sourceurl}`"

artifactextension="`echo ${artifact} | sed s/'^.*\.\([^\.]*\)$'/'\1'/g`"

# check if there was an artitact downloaded.
if [[ -z "${artifact}" ]]
then
	if [[ ! -z `getPropertyValue "${artifactname}.install.type"` ]]
	then
		runPostPostInstall "${artifactname}"

		if [[ "$?" != 0 ]]
		then
			error "ERROR executing installing ${artifactname} usingi (${artifactname}.install.type)"

			return 1
		fi
	else
		error "No artifact downloaded for install nor install type given"

		return 1
	fi
else
	unzipdir=`getPropertyValue "${artifactname}.unzip.dir"`

	artifactcompressed=$(artifactIsCompressed ${artifact})

	if [[ ! -z "${artifactcompressed}" ]]
	then
		if [[ ! -z "${unzipdir}" ]]
		then
			unzipmsg "Extracting ${artifact} to ${unzipdir} ..."
		
			if [[ "${artifactextension}" == "gz" ]]
			then
				artifact_real_extension="`echo ${artifact} | sed s/'^.*\.\([^\.]*\)\.[^\.]*$'/'\1'/g`"
		
				if [[ ! -z ${artifact_real_extension} ]]
				then 
					if [[ ${artifact_real_extension} == "tar" ]]
					then
		
						if [[ ! -d "${unzipdir}" ]]
						then
							mkdir -p "${unzipdir}"
						
							if [[ "$?" != "0" ]]
							then
								error "Failed to create output directory ${unzipdir}"
								return 1
							fi
						fi
		
						prevdir="`pwd`"
		
						cd ${unzipdir}
		
						if [[ "$?" != "0" ]]
						then
							error "Failed to change directory to ${unzipdir}"
							return 1
						fi
		
						tar -xvzf ${targetdir}/${artifact} > /dev/null 2>&1
		
						if [[ "$?" != "0" ]]
						then
							error "Extraction of ${artifact} to ${unzipdir} failed."
							return 1
						fi
		
						cd ${prevdir}
					fi
				fi
		
			elif [[ "${artifactextension}" == "zip" ]]
			then
				if [[ ! -z "${unzipdir}" ]]
				then
					mkdir -p "${unzipdir}"

					unzip -o ${targetdir}/${artifact} -d "${unzipdir}" >/tmp/${artifact}_unzip.txt 2>/tmp/${artifact}_unzip_error.txt
				else
					unzip -o ${targetdir}/${artifact} >/tmp/${artifact}_unzip.txt 2>/tmp/${artifact}_unzip_error.txt
				fi
			fi
		
			if [[ "$?" == "0" ]]
			then
				unzipmsg "Extraction of ${artifact} complete."
			else
				error "Extraction of ${artifact} FAILED."
			
				return 1
			fi
		else
			error "${artifactname}.unzip.dir property not set. Please set this property to the output of install"
			return 1
		fi
	fi
	
	runPostPostInstall "${artifactname}"

	return 0
fi
}

function runPostPostInstall(){

	artifactname="${1}"

	postinstallscript=`getPropertyValue "${artifactname}.install.type"`

	ptype=$postinstallscript

	if [[ ! -z "${postinstallscript}" ]]
	then
		postinstallscript="${PROVISION_SCRIPTS_FOLDER}/commands/install/${postinstallscript}.sh"
	
		if [[ -f "${postinstallscript}" ]]
		then
			. ${postinstallscript}

			info "Running install type ${ptype} ..." 
	
			runPostInstall "${artifactname}"

			if [[ "$?" != "0" ]]
			then
				error "Install type ${ptype} failed."
				return 1
			fi	

			info "Successfully executed install type ${ptype}"
		else
			error "Install script '${postinstallscript}' not found"
			return 1
		fi
	fi	

}
