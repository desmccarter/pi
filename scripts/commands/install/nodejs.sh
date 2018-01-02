. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

function installutil(){

	command="$1"

	install="$2"

	if [[ -z $(commandexists $command) ]]
	then
		runFunction "${install}" "Successfully installed ${command}" "Failed to install ${command}"
	else
		info "${command} already installed"
	fi

}

function runPostInstall(){

        artifactname="$1"

	installutil "${artifactname}" "sudo apt install ${artifactname} npm"
}
