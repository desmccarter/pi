function run(){

javacode="$1"
package="$2"

cat << EOF > ${javacode}
package ${package};

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.How;
import org.openqa.selenium.support.PageFactory;

public abstract class SeleniumPage
{
	protected WebDriver webdriver;

	protected String url;

	public SeleniumPage(WebDriver webdriver, String url){
		this.webdriver = webdriver;
		this.url = url;
	}

	public void openPage(){
		webdriver.get(url);
		PageFactory.initElements(webdriver, this.getClass());
	}
	
	public void setText(WebElement element, String text)
	{
		element.sendKeys(text);
	}
	
	public void click(WebElement element)
	{
		element.click();
	}
}
EOF
}
