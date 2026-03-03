import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = 'https://v1.samehadaku.how/anime-terbaru/'
headers = {
    'User-Agent': 'PostmanRuntime/7.43.0',
    'Accept': '*/*',
}
req = urllib.request.Request(url, headers=headers)
try:
    response = urllib.request.urlopen(req, context=ctx)
    print("Success:", response.status)
    html = response.read().decode('utf-8')
    print(html[:500])
except Exception as e:
    print("Error:", e)
    if hasattr(e, 'read'):
        print(e.read().decode('utf-8')[:500])
