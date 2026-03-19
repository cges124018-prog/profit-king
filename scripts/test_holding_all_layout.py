import requests

url = "https://www.moneydj.com/ETF/X/Basic/Basic0007B.xdjhtm?etfid=0050.TW"
headers = {'User-Agent': 'Mozilla/5.0'}

r = requests.get(url, headers=headers, verify=False)
with open("temp_holding_all.html", "w", encoding="utf-8") as f:
    f.write(r.text)
print("Done!")
