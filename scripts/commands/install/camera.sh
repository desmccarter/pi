. ${PROVISION_SCRIPTS_FOLDER}/provisionutils.sh

function runPostInstall(){

        artifactname="$1"

	sudo apt-get install python3-picamera
	sudo apt-get install python-picamera-docs	
}
