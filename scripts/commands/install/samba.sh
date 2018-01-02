#!/bin/bash

. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

function runPostInstall(){


	artifactname="$1"

	sambaconf=/etc/samba/smb.conf

	if [[ ! -f "${sambaconf}" ]]
	then
		error "ERROR ${sambaconf} does not exist. Terminating samba install"
		return 1
	fi

	propertynames="`getPropertyNames -all \"${PROPERTIES_FILE}\"`"

	unset restartsamba

	unset IFS

	for propname in $propertynames
	do
		sambadef=`echo $propname | sed -n s/"^$artifactname\.\([^\.]*\)\.exposefolder$"/"\1"/p`

		if [[ ! -z $sambadef ]]
		then
			sambadefexists=`sed -n s/"^\([ |	]*\[[ |	]*$sambadef[ |	]*\][ |	]*\)$"/"\1"/p ${sambaconf}`

			exposedfolderpath="`getPropertyValue ${propname}`"

			if [[ -z "${sambadefexists}" ]]
			then
				tempfile="/tmp/sambatext.txt" 

				> ${tempfile}

				if [[ "$?" != 0 ]]
				then
					error "Failed to create SAMBA temp file ${tempfile}"
					return 1
				fi
	
				echo "[$sambadef]" >> ${tempfile}
				echo "   comment = $sambadef - Publically exposed foler" >> ${tempfile}
				echo "   path = $exposedfolderpath" >> ${tempfile}
				echo "   browseable = yes" >> ${tempfile}
				echo "   read only = no" >> ${tempfile}
				echo "   guest ok = yes" >> ${tempfile}
	
				>/tmp/docat.sh && echo "cat ${tempfile} >> ${sambaconf}" >> /tmp/docat.sh && chmod 755 /tmp/docat.sh
	
				sudo /tmp/docat.sh

				info "Updated ${sambaconf} as ${sambadef} based on .exposefolder for artifact ${artifact}"

				restartsamba=true
			else
				info "WARNING - Samba entry exists for ${sambadef}. Ignoring .exposefolder for artifact ${artifact}"

				for field in "comment" "path" "browseable" "read only" "guest ok"
				do
					case $field in
						"comment") newval="${sambadef} - publically exposed folder";;
						"path") newval="${exposedfolderpath}";;
						"browseable") newval="yes";;
						"read only") newval="no";;
						"guest ok") newval="yes";;
					esac

					alterSambaConfField "$sambadef" "$field" "${newval}"
				done

				restartsamba=true
			fi

			break;
		fi
	done

	if [[ ! -z "${restartsamba}" ]]
	then
		sudo service smbd restart >/dev/null 2>&1

		if [[ "$?" == "0" ]]
		then
			info "Samba restartd."
		else
			error "Failed to restart samba"
		fi
	fi
}

function alterSambaConfField(){

	sambadef="$1"
	fieldname="$2"
	fieldvalue="$3"

	sedtemplate="${PROVISION_SCRIPTS_FOLDER}/commands/install/samba.sed.template"

	if [[ ! -f "${sedtemplate}" ]]
	then
		error "ERROR SED template ${sedtemplate} does not exist. Terminating samba install"
		return 1
	fi

	sedscript="/tmp/samba.sed" ; > ${sedscript}

	fieldvalue="`echo ${fieldvalue} | sed s/'\/'/'<<d>>'/g`"

	cat "${sedtemplate}" | \
		sed s/"<<definition>>"/"$sambadef"/g | \
		sed s/"<<variablename>>"/"$fieldname"/g | \
		sed s/"<<newvariablevalue>>"/"$fieldvalue"/g > ${sedscript}

	sudo sed -i -f ${sedscript} /etc/samba/smb.conf 
	sudo sed -i s/"<<d>>"/"\/"/g /etc/samba/smb.conf 
}
