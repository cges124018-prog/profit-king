import urllib.request
import re

url = "https://tw.stock.yahoo.com/quote/0050.TW/holding"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
}

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as r:
        html = r.read().decode('utf-8')
        # Find if shares or weights tables exist
        with open("yahoo_0050_holding.html", "w", encoding="utf-8") as f:
            f.write(html)
        print("Written html to yahoo_0050_holding.html")
except Exception as e:
    print(f"Error: {e}")
