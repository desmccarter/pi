function run(){

javacode="$1"
package="$2"

cat << EOF > ${javacode}
package ${package};

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;

public abstract class Selenium
{
	protected String url;

	protected WebDriver driver = null;

	public String getUrl(){
		return url;
	}

	public void setUrl(String url){
		this.url = url;
	}

	public Selenium(){
		System.setProperty("webdriver.chrome.driver","recources/webdriver/chromedriver/chromedriver.exe");
		driver = new ChromeDriver();
	}
}
EOF
}
