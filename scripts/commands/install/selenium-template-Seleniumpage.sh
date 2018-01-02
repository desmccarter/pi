function run(){

javacode="$1"
package="$2"
classname="$3"
classproperties="$4"
classpropertiesvalues="$5"
url="$6"

cat << EOF > ${javacode}
package ${package};

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.How;

import ${package}.basepage.SeleniumPage;

public class ${classname} extends SeleniumPage
{
	public ${classname}(WebDriver webdriver){
		super(webdriver, "${url}");
	}

EOF

let i=0

while [[ ! -z ${classproperties[${i}]} ]]
do
	classprop=${classproperties[${i}]}
	classpropval=${classpropertiesvalues[${i}]}

	printf "\t@FindBy(how = How.ID, using = \"%s\")\n" "${classpropval}" >> ${javacode}
	printf "\tpublic WebElement %s;\n\n" "${classprop}" >> ${javacode}

	printf "\tpublic void %sSetText(String text){\n\t\t%s.sendKeys(text);\n\t}\n\n" "${classprop}" "${classprop}" >> ${javacode}

	let i="${i}+1"

done
	printf "}" >> ${javacode}
}
