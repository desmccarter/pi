COMPRESSION_TYPES="gz zip"

function artifactIsCompressed(){

	fullpathtoartifact="$1"

	if [[ -z ${fullpathtoartifact} ]]
	then
		return 1
	fi

	ext=$(echo ${fullpathtoartifact} | sed -n s/"^.*\.\([^\.]*\)$"/"\1"/p)

	if [[ -z ${ext} ]]
	then
		return 2
	fi

	ret="3"

	if [[ "zip" == ${ext} ]]
	then
		echo ${ext}
		ret="0"
	fi

	if [[ "gz" == ${ext} ]]
	then
		echo ${ext}
		ret="0"
	fi

	return $ret
}


function extractArtifact(){

        artifactname="$1"

	artifact="$2"

	targetfolder="$3"

	if [[ -z "${artifactname}" ]]
	then
		error "${artifactname} not given. Please set this argument"
		return 1
	fi

	if [[ -z "${artifact}" ]]
	then
		error "${artifact} not given. Please set this argument"
		return 1
	fi

	if [[ -z "${targetfolder}" ]]
	then
		error "${targetfolder} not given. Please set this argument"
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

	extension=$(echo ${artifact} | sed s/"^.*\.\([a-z|A-Z]*\)$"/"\1"/g)

	info "Extracting ${extension} ${artifact} to ${targetfolder} ..."

	if [[ "${extension}" == "gz" ]]
	then
		prevdir="`pwd`"

		cd "${targetfolder}"

		tar -zxvf /tmp/${artifact} >/dev/null 2>&1

		if [[ "$?" != "0" ]]
		then
			error "Failed to extract (tar) ${artifact} to ${targetfolder}"

			cd "${prevdir}"
		
			return 1
		else
			info "Extracted (tar) ${artifact} to ${targetfolder}"

			cd "${prevdir}"
		fi


	elif [[ "${extension}" == "zip" ]]
	then
		unzip -d "${targetfolder}" -o /tmp/${artifact} >/dev/null

		if [[ "$?" != "0" ]]
		then
			error "Failed to extract (zip) ${artifact} to ${targetfolder}"

			cd "${prevdir}"
		
			return 1
		else
			info "Extracted (zip) ${artifact} to ${targetfolder}"

			cd "${prevdir}"
		fi
	else
		error "Unknown archive type ${extension}"
		return 1
	fi
}

function commandexists(){
	command="$1"

	exists=$(type ${command} 2>/dev/null| sed -n s/^"$command[ |	]*is[ |	]*\(.*$command\)$"/"\1"/p)

	if [[ ! -z "${exists}" ]]
	then
		echo "${exists}"
	fi
}

function runFunction(){

        thefunction="${1}"
        succmsg="${2}"
        failmsg="${3}"

        if [[ -z "${thefunction}" ]]
        then
                error "No function given!"
                exit 1
        fi

        eval ${thefunction}

        exitresult="$?"

        if [[ "$exitresult" != "0" ]]
        then
                if [[ ! -z "${failmsg}" ]]
                then
                        error "${failmsg} (${thefunction})"
                else
                        error "Failed to execute (${thefunction})"
                fi

                usage

                exit ${exitresult}
        else
                if [[ ! -z "${succmsg}" ]]
                then
                        info "${succmsg} (${thefunction})"
                else
                        info "Executed successfully (${thefunction})"
                fi
        fi
}

##
# @info     returns the current os enum [WINDOWS/MAC/LINUX]
# @param    na
# @return   os enum [WINDOWS , MAC , LINUX]
##

function getOs()
{
    local _ossig=`uname -s 2> /dev/null | tr "[:upper:]" "[:lower:]" 2> /dev/null`
    local _os_base="UNKNOWN"

    case "$_ossig" in
        *windowsnt*)_os_base="WINDOWS";;
        *darwin*)   _os_base="MAC";;
        *linux*)    
                    if [ -f /etc/redhat-release ] ; then
                        _os_base="LINUX-REDHAT"
                    elif [ -f /etc/SuSE-release ] ; then
                        _os_base="LINUX-SUSE"
                    elif [ -f /etc/mandrake-release ] ; then
                        _os_base="LINUX-MANDRAKE"
                    elif [ -f /etc/debian_version ] ; then
                        _os_base="LINUX-DEBIAN"             
                    else
                        _os_base="LINUX"            
                    fi
            ;;
        *)          _os_base="UNKNOWN";;
    esac

    echo $_os_base
}


function getRootFolderFromTarArchive(){

	if [[ -z "${1}" ]]
	then
		error "You need to specify the artifact location"
		return 1
	fi

	artifactlocation="$1"

        tar -tzf ${artifactlocation} | sed -n s/'^\([^\/]*\)\/README.*$'/'\1'/p 2>/dev/null
}

function appendEnvironmentVariable(){

	variablename="$1"

	variablevalue="$2"

	filetoedit="$3"

	if [[ -f "`eval echo $filetoedit`" ]]
	then
		echo "export $variablename=$variablevalue" >> ~/.bashrc
			
		info "Created $variablename=$variablevalue"
	else
		echo "export $variablename=$variablevalue" >> ~/.bashrc
			
		info "set $variablename=$variablevalue"
	fi
}

function updateEnvironmentVariable(){

	variablename="$1"

	variablevalue="$2"

	filetoedit="$3"

	created="-10"

	if [[ -f "`eval echo $filetoedit`" ]]
	then
		jhome=`cat ~/.bashrc | grep "^[ |	]*export[ |	]*$variablename="`

		if [[ ! -z "${jhome}" ]]
		then
			info "Environment variable ${variablename} has already been set in ${filetoedit}"

			exportdiresc="`echo ${variablevalue} | sed s/'\/'/'<delimiter>'/g`"

			sedtext="s/\(^[ |	]*export[ |	]*$variablename=\).*$/\1$exportdiresc/g"

			sed "$sedtext" ~/.bashrc | sed s/"<delimiter>"/"\/"/g > /tmp/bashrcnew

			mv /tmp/bashrcnew ~/.bashrc

			info "set $variablename=$variablevalue"
		else
			created="10"

			echo "export $variablename=$variablevalue" >> ~/.bashrc
			
			info "set $variablename=$variablevalue"
		fi
	else
		created="10"

		echo "export $variablename=$variablevalue" >> ~/.bashrc
			
		info "set $variablename=$variablevalue"
	fi

	return $created
}

function writeToStdout(){

	prefix="${1}"

	text="${2}"

	snapshotdate="`date +\"%d-%m-%Y %H:%M:%S\"`"

	printf "[%-20s %-18s] %-40s\n" "${prefix}" "${snapshotdate}" "${text}"
}

function info(){
	writeToStdout "INFO" "$1"
}

function debug(){
		
	loglevel=$(getPropertyValue output.log.level)

	if [[ ! -z "${loglevel}" ]]
	then
		if [[ "${loglevel}" == "debug" ]]
		then
			writeToStdout "DEBUG" "$1"
		fi
	fi
}

function error(){
	writeToStdout "ERR" "$1"
}

function completed(){
	writeToStdout "DONE" "$1"
}

function usagemsg(){
	writeToStdout "USAGE" "$1"
}

function downloadmsg(){
	writeToStdout "DOWNLOAD" "$1"
}

function unzipmsg(){
	writeToStdout "UNZIP" "$1"
}

function getPropertyValue(){

	name="$1"
	file="$2"

	if [[ -z ${name} ]]
	then
		return
	fi

	if [[ ! -z "${file}" ]]
	then
		if [[ ! -f ${file} ]]
		then
			return
		fi

		sed -n s/"^[ |	]*$name=\(.*\)$"/"\1"/p ${file}
	else
		getPropertyValueFromBashVariable "${name}"
	fi
}

function getProperties(){

propvarprefix="$1"
regex="$2"
propfile="$3"

	let index=0

        for prop in $(getPropertyNames "-all" ${PROPERTIES_FILE})
        do
                regexmatchexpr="eval echo $prop | sed -n s/\"$regex\"/\"\1\"/p"
                regexmatch="`${regexmatchexpr}`"

                if [[ ! -z ${regexmatch} ]]
                then
                        propval=$(getPropertyValue ${prop} ${PROPERTIES})

			var1="${propvarprefix}name[${index}]=\"${prop}\""
			var2="${propvarprefix}value[${index}]=\"${propval}\""

			eval $var1
			eval $var2

			let index="${index}+1"
		fi
	done
}


function getPropertyNamesUsingRegex(){

	regex="$1"

	unset propn

	for p in $(getPropertyNames "-all" "${PROPERTIES_FILE}")
	do
		echo $p
	done
}

function getPropertyNames(){

        name="$1"
        file="$2"

	if [[ -z ${name} ]]
	then
		return
	fi
	
	if [[ ! -f ${file} ]]
	then
		return
	fi

	if [[ "${name}" == "-all" ]]
	then
		sed -n s/"^[ |	]*\([^\=]*\)\=.*$"/"\1"/p "${file}"
	else
	        sed -n s/"^[ |  ]*$name\.\([^=]*\).*$"/"\1"/p ${file}
	fi
}

function propertyToLinux(){

	echo "${1}" | sed s/'[\.|-]'/''/g
}

function getFilenameFromUrl(){
	echo "${*}" | sed s/"^.*\/\([^\/]*\)$"/"\1"/g
}

function getPropertyValueFromBashVariable(){
	if [ ! -z ${1} ]
	then
		propertyname="${1}"
		propertynamebash=`propertyToLinux ${propertyname}`
		echo ${!propertynamebash}
	fi
}

function executewget(){

	if [[ -z ${1} ]]
	then
		error "URL not given for WGET"
		exit 1
	fi

	url="${1}"

	targetdir="${2}"

	shift;shift

	args=${*}

	if [[ ! -z "${targetdir}" ]]
	then
		eval wget ${args} "${url}" -P "${targetdir}"
	else
		wget ${args} "${url}" -P ~
	fi
}

function executecurl(){

	if [[ -z ${1} ]]
	then
		error "URL not given for WGET"
		exit 1
	fi

	url="${1}"

	targetdir="${2}"

	shift;shift

	args=${*}

	outputfile="`echo $url | sed s/'^.*\/\([^\/]*\)$'/'\1'/g`"

	eval curl ${args} -o "${targetdir}/${outputfile}" "${url}" 
}
