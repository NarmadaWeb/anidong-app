import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

req = urllib.request.Request(
    'https://v1.samehadaku.how/',
    headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }
)
try:
    response = urllib.request.urlopen(req, context=ctx)
    print("Success:", response.status)
    print(response.read().decode('utf-8')[:500])
except Exception as e:
    print("Error:", e)
