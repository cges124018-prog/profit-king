import urllib.request, rre = None

url = "https://histock.tw/etf/0050"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...'
}

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as r:
        html = r.read().decode('utf-8')
        print(f"HTML Length: {len(html)}")
        if "台積電" in html:
            print("Found 台積電 inside HTML!")
        else:
            print("Not found 台積電 inside.")
except Exception as e:
    print(f"Error: {e}")
