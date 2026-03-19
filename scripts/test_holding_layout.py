import requests

url = "https://www.moneydj.com/ETF/X/Basic/Basic0007.xdjhtm?etfid=0056.TW"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
}
# verify=False to bypass local SSL handshake glitch for testing
r = requests.get(url, headers=headers, verify=False)
with open("temp_holding.html", "w", encoding="utf-8") as f:
    f.write(r.text)
print("Done!")
