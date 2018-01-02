. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

POM="/tmp/pom.xml"

function setArtifactProperty(){

        artifactname="$1"
	prop="$2"

	value="$(getPropertyValue ${artifactname}.${prop} ${PROPERTIES_FILE})"

	[[ ! -z "${value}" ]] && eval ${prop}="${value}"	
} 

function printTabs(){

	let numberoftabs="$1"
	let tabcount=0

	if [[ -z "${numberoftabs}" || -z $(echo ${numberoftabs} | sed -n s/"^\([0-9]*\)$"/"\1"/p) ]]
	then
		error "Invalid number of tabs ${numberoftabs}"
		return 1
	fi

	while [[ "${tabcount}" < "${numberoftabs}" ]]
	do
		printf "\t" ; let tabcount="${tabcount}+1"
	done	
}

function outputEndRootToFinalTag(){

	roottotag="$1"
	
	let tabcount="$2"

	if [[  -z "${roottotag}" ]]
	then
		error "Root to final tag not given!"
		return 1
	fi

	unset IFS

	unset roottotagrev

	# Create a reverse list ...
	for tag in $(echo $roottotag | sed s/"\."/" "/g)
	do
		if [[ -z "${roottotagrev}" ]]
		then
			roottotagrev=$tag
		else
			roottotagrev="$tag.$roottotagrev"
		fi
	done

	for tag in $(echo $roottotagrev | sed s/"\."/" "/g)
	do
		printTabs ${tabcount} >> ${POM}

		printf "%s\n" "</$tag>" >> ${POM}

		let tabcount="${tabcount}-1"
	done
}

function outputRootToFinalTag(){
	
	roottotag="$1"
	
	let tabcount="$2"

	if [[  -z "${roottotag}" ]]
	then
		error "Root to final tag not given!"
		return 1
	fi

	unset IFS

	let elementcount=0

	for tag in $(echo $roottotag | sed s/"\."/" "/g)
	do
		printTabs ${tabcount} >> ${POM}

		printf "%s\n" "<$tag>" >> ${POM}

		let tabcount="${tabcount}+1"

		let elementcount="${elementcount}+1"
	done

	printf "%d" "${elementcount}"
}

function writeAsXml(){

	beforexml="$1"

	value="$2"

	let starttab="$3"

	printTabs "${starttab}" >> ${POM}
	
	printf  "<${beforexml}>${value}</${beforexml}>\n" >> ${POM}
}

function doPomStart(){

cat << EOF > ${POM}
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/${modelversion}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/${modelversion} http://maven.apache.org/xsd/maven-${modelversion}.xsd">
	<modelVersion>${modelversion}</modelVersion>
	<groupId>${groupId}</groupId>
	<artifactId>${artifactId}</artifactId>
	<version>${version}</version>
EOF

}

function doPomStop(){

cat << EOF >> ${POM}
</project>
EOF
}

function startBuildPlugins(){

cat << EOF >> ${POM}

	<build>
		<plugins>
EOF

}

function startPlugin(){

cat << EOF >> ${POM}
			<plugin>
EOF

}

function stopPlugin(){

cat << EOF >> ${POM}
			</plugin>
EOF

}

function stopBuildPlugins(){

cat << EOF >> ${POM}
		</plugins>
	</build>
EOF

}

function startPomDependencies(){

cat << EOF >> ${POM}
	<dependencies>
EOF

}

function stopPomDependencies(){

cat << EOF >> ${POM}
	</dependencies>
EOF

}

function addPomDependency(){

grp="$1"
art="$2"
ver="$3"
scope="$4"

cat << EOF >> ${POM}
		<dependency>
			<groupId>${grp}</groupId>
			<artifactId>${art}</artifactId>
			<version>${ver}</version>
EOF

if [[ ! -z "${scope}" ]]
then

cat << EOF >> ${POM}
			<scope>${scope}</scope>
EOF

fi


cat << EOF >> ${POM}
		</dependency>
EOF

}

function runPostInstall(){

        artifactname="$1"

	generatePOM "${artifactname}"

	projectdir=$(getPropertyValue "selenium-template.rootdir" ${PROPERTIES_FILE})

	projectdir=$(eval echo ${projectdir})

	if [[ -d "${projectdir}" ]]
	then
		rm -rf "${projectdir}"
	
		if [[ "$?" != 0 ]]
		then
			error "Failed to clean ${projectdir}"
			return 1
		fi
	fi

	mkdir -p "${projectdir}"

	if [[ "$?" != 0 ]]
	then
		error "Failed to create folder ${projectdir}"
		return 1
	fi

	mv "${POM}" "${projectdir}"

	if [[ "$?" != 0 ]]
	then
		error "Failed to move POM to ${projectdir}"
		return 1
	fi

	mkdir -p "${projectdir}/src/test/java"

	if [[ "$?" != 0 ]]
	then
		error "Failed to create src/test/java folder"
		return 1
	fi

	mkdir -p "${projectdir}/src/main/java"

	if [[ "$?" != 0 ]]
	then
		error "Failed to create src/main/java folder"
		return 1
	fi

	mkdir -p "${projectdir}/src/test/resources"

	if [[ "$?" != 0 ]]
	then
		error "Failed to create src/test/resources folder"
		return 1
	fi

	# Get the browser type ...

	browsertype=$(getPropertyValue "${artifactname}.browsertype" ${PROPERTIES_FILE})

	if [[ -z "${browsertype}" ]]
	then
		error "${artifactname}.browsertype not set"
		return 1
	fi

	case "${browsertype}" in
		"chrome")
			driverloc=$(getPropertyValue "selenium-chromedriver.unzipdir" ${PROPERTIES_FILE})
			driverloc=$(eval echo ${driverloc})
		;;
		*)
			error "Browser type ${browsertype} not catered for in this script"
			return 1
		;;
	esac

	if [[ ! -d "${driverloc}" ]]
	then
		error "Could not find Chromedriver"
		return 1
	fi

	mkdir -p "${projectdir}/src/test/resources/webdriver/chromedriver"

	cp "${driverloc}/chromedriver.exe" "${projectdir}/src/test/resources/webdriver/chromedriver"

	if [[ "${?}" != "0" ]]
	then
		error "Chrome driver does not exist in ${driverloc}"
		return 1
	fi

	artifactid=$(getPropertyValue "${artifactname}.artifactId" ${PROPERTIES_FILE})
	groupid=$(getPropertyValue "${artifactname}.groupId" ${PROPERTIES_FILE})

	javacodefolder="${projectdir}/src/test/java/$(echo ${groupid} | sed s/'\.'/'\/'/g)/$(echo ${artifactid} | sed s/'\.'/'\/'/g)"

	mkdir -p "${javacodefolder}"

	if [[ "$?" != 0 ]]
	then
		error "Failed to create ${javacodefolder} folder"
		return 1
	fi

	seleniumjava="${javacodefolder}/selenium/Selenium.java"

	mkdir -p $(dirname "${seleniumjava}")

	if [[ "$?" != 0 ]]
	then
		error "Failed to create `dirname ${seleniumjava}` folder"
		return 1
	fi

	package="${groupid}.${artifactid}"

	. "${PROVISION_SCRIPTS_FOLDER}/commands/install/selenium-template-Seleniumjava.sh"

	if [[ "$?" != 0 ]]
	then
		error "Failed to load ${PROVISION_SCRIPTS_FOLDER}/commands/install/selenium-template-Seleniumjava.sh"
		return 1
	fi

	run "${seleniumjava}" "${package}.selenium"

	# PageFactory class creation ...

	unset javapageproperties

	getProperties "pagefactory" "^pagefactory\.\(.*\)$" "${PROPERTIES_FILE}"
	getProperties "pagenames" "^pagefactory\.\([^\.]*\)$" "${PROPERTIES_FILE}"

	let proppos=0

	prop=${pagenamesname[$proppos]}

	. "${PROVISION_SCRIPTS_FOLDER}/commands/install/selenium-template-Seleniumpage.sh"

	while [[ ! -z "${prop}" ]]
	do
		classname=$(getPropertyValue "${prop}" ${PROPERTIES_FILE})
		url=$(getPropertyValue "${prop}.url" ${PROPERTIES_FILE})

		pageid=$(echo ${prop} | sed s/"^[^\.]*\.\(.*\)$"/"\1"/g)

		unset classproperties
		unset classpropertiesvalues

		let classpropertiesindex=0

		let j=0

		while [[ ! -z "${pagefactoryname[${j}]}" ]]
		do
			propertyname=$( echo ${pagefactoryname[${j}]} | sed -n s/"^pagefactory\.$pageid\.\(.*\)$"/"\1"/p)

			if [[ ! -z ${propertyname} ]]
			then
				if [[ ${propertyname} != "url" ]]
				then
					classproperties[${classpropertiesindex}]=${propertyname}
					classpropertiesvalues[${classpropertiesindex}]=${pagefactoryvalue[${j}]}

					let classpropertiesindex="${classpropertiesindex}+1"
				fi
			fi
	
			let j="${j}+1"
		done

		pageclass="${javacodefolder}/pages/${classname}.java"

		mkdir -p $(dirname "${pageclass}")

		if [[ "$?" != 0 ]]
		then
			error "Failed to create `dirname ${pageclass}` folder"
			return 1
		fi

		run "${pageclass}" "${groupid}.${artifactid}.pages" "${classname}" "${classproperties}" "${classpropertiesvalues}" "${url}"

		let proppos="${proppos}+1"
	
		prop=${pagenamesname[$proppos]}
	done

	# Create SeleniumFixture abstract class ...
	. "${PROVISION_SCRIPTS_FOLDER}/commands/install/selenium-template-Seleniumfixture.sh"

	pageclass="${javacodefolder}/junittests/selenium/baseclass/SeleniumFixture.java"

	mkdir -p $(dirname "${pageclass}")

	if [[ "$?" != 0 ]]
	then
		error "Failed to create `dirname ${pageclass}` folder"
		return 1
	fi

	run "${pageclass}" "${groupid}.${artifactid}.junittests.selenium.baseclass"

	# Create SeleniumPage base class ...
	. "${PROVISION_SCRIPTS_FOLDER}/commands/install/selenium-template-Seleniumpagebase.sh"

	pageclass="${javacodefolder}/pages/basepage/SeleniumPage.java"

	mkdir -p $(dirname "${pageclass}")

	if [[ "$?" != 0 ]]
	then
		error "Failed to create `dirname ${pageclass}` folder"
		return 1
	fi

	run "${pageclass}" "${groupid}.${artifactid}.pages.basepage"
}

function generatePOM(){

        artifactname="$1"

	setArtifactProperty "${artifactname}" "modelversion"
	setArtifactProperty "${artifactname}" "groupId"
	setArtifactProperty "${artifactname}" "artifactId"
	setArtifactProperty "${artifactname}" "version"

	info "(Maven) model.version:	${modelversion}"
	info "(Maven) group.id     :	${groupId}"
	info "(Maven) artifact.id  :	${artifactId}"
	info "(Maven) version      :	${version}"

	allproperties=$(getPropertyNames "-all" ${PROPERTIES_FILE})

	doPomStart

	# Write dependencies ...
	dependencies="$(getPropertyValue ${artifactname}.dependson)"

	if [[ ! -z "${dependencies}" ]]
	then
		startPomDependencies

		while [[ ! -z "${dependencies}" ]]
		do
			dependency=$(echo $dependencies | sed -n s/"^\([^ ]*\).*"/"\1"/p)

			depgroup="$(getPropertyValue ${dependency}.groupId)"
			departifact="$(getPropertyValue ${dependency}.artifactId)"
			depversion="$(getPropertyValue ${dependency}.version)"
			depscope="$(getPropertyValue ${dependency}.scope)"

			if [[ ! -z "${depgroup}" && ! -z "${departifact}" ]]
			then
				addPomDependency "${depgroup}" "${departifact}" "${depversion}" "${depscope}"
			else
				error "No definition found for dependency ${dependency}"
				return 1
			fi

			dependencies=$(echo $dependencies | sed -n s/"^[^ ]* *\(.*\)$"/"\1"/p)
		done

		stopPomDependencies
	fi

	# Start build plugins ...
	buildplugins="$(getPropertyValue ${artifactname}.build.plugin ${PROPERTIES_FILE})"

	if [[ ! -z "${buildplugins}" ]]
	then
		startBuildPlugins

		while [[ ! -z "${buildplugins}" ]]
		do
			plugin=$(echo $buildplugins | sed -n s/"^\([^ ]*\).*"/"\1"/p)

			startPlugin

			unset prevroottofinaltag

			let tabbing=4

			for propname in $allproperties
			do
				if [[ ! -z $(echo $propname | sed -n s/"^build\.plugin\.$plugin\.\(.*\)$"/"\1"/p) ]]
				then
					propnamesuffix=$(echo $propname | sed -n s/"^build\.plugin\.$plugin\.\(.*\)$"/"\1"/p) 
					
					finaltag=$(echo ${propnamesuffix} | sed s/"^.*\.\([^\.]*\)$"/"\1"/g)

					roottofinaltag=$(echo ${propnamesuffix} | sed s/"^\(.*\)\.[^\.]*$"/"\1"/g)

					# Below useful for debugging ...
					#echo propnamesuffix=$propnamesuffix finaltag=$finaltag roottofinaltag=$roottofinaltag

					if [[ "${finaltag}" != "${roottofinaltag}" ]]
					then
						unset output

						if [[ -z "${prevroottofinaltag}" ]] 
						then
							output=true
						elif [[ "${prevroottofinaltag}" != "${roottofinaltag}" ]]
						then
							echo not equal: prev=$prevroottofinaltag curr=$roottofinaltag

							subtags=$(echo $roottofinaltag | sed -n s/"^$prevroottofinaltag\.\(.*\)$"/"\1"/p)

							#if the new root is a child of the previous root ...
							if [[ ! -z ${subtags} ]]
							then
								let rootelementcount="$(outputRootToFinalTag ${subtags} ${tabbing})+${rootelementcount}"
							
								prevroottofinaltag=$roottofinaltag
							else
								output=true
							fi
						fi

						if [[ ! -z "${output}" ]]
						then
							rootelementcount=$(outputRootToFinalTag ${roottofinaltag} "${tabbing}")

							prevroottofinaltag=$roottofinaltag

							let tabbing="${tabbing}+${rootelementcount}"
						fi
					fi	
					
					writeAsXml $finaltag $(getPropertyValue "${propname}" "${PROPERTIES_FILE}") "${tabbing}"
				fi
			done

			if [[ ! -z "${prevroottofinaltag}" ]]
			then
				if [[ ! -z "${rootelementcount}" ]]
				then
					let tabbing="${tabbing}-${rootelementcount}+1"

					unset rootelementcount
				fi

				outputEndRootToFinalTag ${prevroottofinaltag} "${tabbing}"
			fi

			stopPlugin

			buildplugins=$(echo $buildplugins | sed -n s/"^[^ ]* *\(.*\)$"/"\1"/p)
		done


		stopBuildPlugins
	fi

	doPomStop
}
