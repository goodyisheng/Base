from selenium.webdriver import Chrome, ChromeOptions
import zipfile
import string
 
 
def create_proxyauth_extension(proxy_host, proxy_port,
                               proxy_username, proxy_password,
                               scheme='http', plugin_path=None):
 
    # 该配置不用改，可以直接用
    if plugin_path is None:
        plugin_path = 'chrome_proxyauth_plugin.zip'
 
    manifest_json = """
    {
        "version": "1.0.0",
        "manifest_version": 2,
        "name": "Chrome Proxy",
        "permissions": [
            "proxy",
            "tabs",
            "unlimitedStorage",
            "storage",
            "<all_urls>",
            "webRequest",
            "webRequestBlocking"
        ],
        "background": {
            "scripts": ["background.js"]
        },
        "minimum_chrome_version":"22.0.0"
    }
    """
 
    background_js = string.Template(
        """
        var config = {
                mode: "fixed_servers",
                rules: {
                  singleProxy: {
                    scheme: "${scheme}",
                    host: "${host}",
                    port: parseInt(${port})
                  },
                  bypassList: ["foobar.com"]
                }
              };
        chrome.proxy.settings.set({value: config, scope: "regular"}, function() {});
        function callbackFn(details) {
            return {
                authCredentials: {
                    username: "${username}",
                    password: "${password}"
                }
            };
        }
        chrome.webRequest.onAuthRequired.addListener(
                    callbackFn,
                    {urls: ["<all_urls>"]},
                    ['blocking']
        );
        """
    ).substitute(
        host=proxy_host,
        port=proxy_port,
        username=proxy_username,
        password=proxy_password,
        scheme=scheme,
    )
    with zipfile.ZipFile(plugin_path, 'w') as zp:
        zp.writestr("manifest.json", manifest_json)
        zp.writestr("background.js", background_js)
 
    return plugin_path
 
 
if __name__ == '__main__':
    url = "https://www.baidu.com"
 
    proxyauth_plugin_path = create_proxyauth_extension(
        proxy_host="xxx.xxx.com",  # 隧道hsot
        proxy_port="",   # 隧道端口
        proxy_username="",  # 输入隧道账号
        proxy_password=""  # 输入密码
    )
    print(proxyauth_plugin_path)
 
    cOption = ChromeOptions()
    # cOption.add_argument('--disable-gpu')
    # cOption.add_argument('--no-sandbox')
    # cOption.add_argument('--headless')
    cOption.add_extension(proxyauth_plugin_path)
 
    browser = Chrome(options=cOption)
    browser.get(url)
    print(browser.page_source)
 
