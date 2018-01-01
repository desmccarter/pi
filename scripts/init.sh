#!/bin/bash

# AUTHOR 	: Des McCarter @ BJSS
# DATE		: 12/09/2017
# DESCRIPTION	: This script needs to be executed (only once) 
#		  once you have cloned the Royal Mail Test Project

BASHRC="~/.bashrc"

function VerifyLocation(){

	CURRENT_FOLDER="`pwd`"

	THIS_SCRIPT="`basename ${1}`"	

	if [[ ! -f ${THIS_SCRIPT} ]]
	then
		echo "[ERR] Please re-run ${THIS_SCRIPT} from the scripts folder"
		exit 1
	fi
}

# Set the scripts folder in 
# PATH in bashrc ...

function GetProvisionScriptsFolderExport(){
	cat ~/.bashrc | grep "^export[ ]*PROVISION_SCRIPTS_FOLDER" | grep "${PROVISION_SCRIPTS_FOLDER}"
}

PROVISION_SCRIPTS_FOLDER_EXPORT="`GetProvisionScriptsFolderExport`"

# START HERE ...

VerifyLocation "${0}"

# import utils ...

. ./utils.sh

# Add export of PROVISION_SCRIPTS_FOLDER
# to ~/.bashrc ...

if [ "a${PROVISION_SCRIPTS_FOLDER_EXPORT}" = "a" ]
then
	info "Updating ~/bashrc with PROVISION_SCRIPTS_FOLDER variable ..."

	echo "export PROVISION_SCRIPTS_FOLDER=\"`pwd`\"" >> ~/.bashrc

	echo >> ~/.bashrc
	echo "alias provision=\"\${PROVISION_SCRIPTS_FOLDER}/provision.sh -setupfile \${PROVISION_SCRIPTS_FOLDER}/setup/provision.setup -propertiesfile \${PROVISION_SCRIPTS_FOLDER}/setup/provision.properties\"" >> ~/.bashrc

cat << EOF >> ~/.bashrc

function prov(){
	. "\${PROVISION_SCRIPTS_FOLDER}"/utils.sh

	if [[ "\$?" != "0" ]]
	then
		echo "[ERR] Failed to import utils"
		usage
	fi

	setup="\$1"

	if [[ -z "\${setup}" ]]
	then
		error "Set-up not given"

		if [[ -d \${PROVISION_SCRIPTS_FOLDER}/setup ]]
		then		
			usagemsg "Possible set-up arguments:"

			for s in \$(find \${PROVISION_SCRIPTS_FOLDER}/setup -name "*.setup" | sed -n s/"^.*\/\([^\/]*\)\.setup\$"/"\1"/p)
			do
				usagemsg "        \${s}"	
			done
		else
			error "Set-up folder does not exist \${PROVISION_SCRIPTS_FOLDER}/setup"
		fi

		return 1	
	fi

	if [[ ! -f "\${PROVISION_SCRIPTS_FOLDER}/setup/\${setup}.setup" ]]
	then
		error "Unknown set-up \${setup}"
		usage
		return 1
	fi
	
	\${PROVISION_SCRIPTS_FOLDER}/provision.sh -setupfile "\${PROVISION_SCRIPTS_FOLDER}/setup/\${setup}.setup" -propertiesfile "\${PROVISION_SCRIPTS_FOLDER}/setup/provision.properties"	
}

EOF
	completed "Updated ~/bashrc with PROVISION_SCRIPTS_FOLDER variable."
else
	info "~/.bash already contains PROVISION_SCRIPTS_FOLDER"
fi
