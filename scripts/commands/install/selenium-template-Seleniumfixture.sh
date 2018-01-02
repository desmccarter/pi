function run(){

javacode="$1"
package="$2"
driverlocation="$3"

cat << EOF > ${javacode}
package ${package};

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.How;

import org.openqa.selenium.chrome.ChromeDriver;

import java.util.concurrent.TimeUnit;

public class SeleniumFixture 
{
	protected static WebDriver webdriver=null;
	
	protected static void initWebDriver(){
		System.setProperty("webdriver.chrome.driver","src/test/resources/webdriver/chromedriver/chromedriver.exe");
		
		webdriver = new ChromeDriver();
		webdriver.manage().timeouts().implicitlyWait(10, TimeUnit.SECONDS);		
	}
	
	public SeleniumFixture(){
		if(webdriver==null)
		{
			initWebDriver();
		}
	}
}
EOF
}
