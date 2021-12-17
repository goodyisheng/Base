import os
import time
import zipfile
from selenium import webdriver
from scrapy.selector import Selector

PROXY_HOST = "http-dyn.abuyun.com" # rotating proxy or host
PROXY_PORT = 9020 # port
PROXY_USER = "" # username
PROXY_PASS = "" # password

REMOTE_SELENIUM = "111.11.111.22:4444" # 远程的docker selenium地址

manifest_json = """
{
"version":"1.0.0",
"mainifest_version":2,
"name":"Chrome Proxy",
"permissions":[
	"proxy",
	"tabs",
	"unlimitedStorage",
	"storage",
	"<all_urls>",
	"webRequest",
	"webRequestBlocking"
],
"backgroung":{
	"scripts":["background.js"]
},
"minimum_chrome_version":"22.0.0"
}
"""

background_js = """
var config = {
        mode: "fixed_servers",
        rules: {
        singleProxy: {
            scheme: "http",
            host: "%s",
            port: parseInt(%s)
        },
        bypassList: ["localhost"]
        }
    };

chrome.proxy.settings.set({value: config, scope: "regular"}, function() {});

function callbackFn(details) {
    return {
        authCredentials: {
            username: "%s",
            password: "%s"
        }
    };
}

chrome.webRequest.onAuthRequired.addListener(
            callbackFn,
            {urls: ["<all_urls>"]},
            ['blocking']
);
""" % (PROXY_HOST, PROXY_PORT, PROXY_USER, PROXY_PASS)
	
}
"""

def get_chromedriver(use_proxy=False, user_agent=None, use_docker=True):
    path = os.path.dirname(os.path.abspath(__file__))
    chrome_options = webdriver.ChromeOptions()
    if use_proxy:
        pluginfile = 'proxy_auth_plugin.zip'

        with zipfile.ZipFile(pluginfile, 'w') as zp:
            zp.writestr("manifest.json", manifest_json)
            zp.writestr("background.js", background_js)
        chrome_options.add_extension(pluginfile)
    if user_agent:
        chrome_options.add_argument('--user-agent=%s' % user_agent)
    if use_docker:
        driver = webdriver.Remote(
            command_executor="http://{}/wd/hub".format(REMOTE_SELENIUM),
            # command_executor="http://192.168.22.56:4444/wd/hub",
            options=chrome_options
        )
    else:
        driver = webdriver.Chrome(
            os.path.join(path, '/usr/local/bin/chromedriver'),
            chrome_options=chrome_options)
    return driver


def main():
    # 使用代理 使用docker
    driver = get_chromedriver(use_proxy=True, use_docker=True)
    print(driver)
    n = 0
    while True:
        # driver = get_chromedriver(use_proxy=True, use_docker=True)
        # print(driver)
        driver.get('https://www.cip.cc')
        ip_text = Selector(text=driver.page_source).xpath(
            '//pre/text()').extract_first().strip()
        print(ip_text)
        driver.close()
        time.sleep(3)
        n += 1
         if n > 10:
            break
    driver.quit()


if __name__ == '__main__':
    main()
