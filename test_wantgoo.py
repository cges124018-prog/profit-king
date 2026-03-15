import urllib.request, json

url = "https://www.wantgoo.com/api/etf/0050/constituent"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
    'Referer': 'https://www.wantgoo.com/'
}

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as r:
        print(r.read().decode('utf-8')[:1000])
except Exception as e:
    print(f"Error: {e}")
