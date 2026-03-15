import urllib.request

url = "https://tw.stock.yahoo.com/quote/0050.TW/holding"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
}

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as r:
        html = r.read().decode('utf-8')
        print(f"Yahoo HTML Length: {len(html)}")
        if "台積電" in html:
            print("Found 台積電 inside Yahoo!")
        else:
            print("Not found.")
except Exception as e:
    print(f"Error: {e}")
