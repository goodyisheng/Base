#!/bin/env python3
from selenium.webdriver.chrome import options
from selenium.webdriver.remote.webdriver import WebDriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.webdriver.chrome.options import Options
ch = Options()
ch.add_argument("--headless")
browser = WebDriver(command_executor='http://192.168.3.13:4444/wd/hub',

                    desired_capabilities=DesiredCapabilities.CHROME,options=ch)
browser.get("https://www.baidu.com/")
print(browser.page_source)
browser.close()

