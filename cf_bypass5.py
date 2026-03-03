import urllib.request
import ssl
import gzip
from io import BytesIO

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = 'https://corsproxy.io/?url=https://v1.samehadaku.how/anime-movie/'
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
}

req = urllib.request.Request(url, headers=headers)
try:
    response = urllib.request.urlopen(req, context=ctx)
    print("Success:", response.status)
    if response.info().get('Content-Encoding') == 'gzip':
        buf = BytesIO(response.read())
        f = gzip.GzipFile(fileobj=buf)
        html = f.read().decode('utf-8')
    else:
        html = response.read().decode('utf-8')
    with open('samehadaku_movie.html', 'w') as f:
        f.write(html)
except Exception as e:
    print("Error:", e)
