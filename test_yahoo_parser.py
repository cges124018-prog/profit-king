from bs4 import BeautifulSoup
import re

# 讀取備份的 Yahoo HTML
with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# 尋找含有佔比 % 的區塊
results = []
items = soup.find_all("div", class_=lambda x: x and ("D(f) Ai(c)" in x or "grid-item" in x))

for item in items:
    text = item.get_text(separator=' | ')
    # 正規表達式尋找: "股名" + "% 比重"
    # 例如包含 "台積電" 跟 "51.27%"
    if '%' in text and len(text) < 100: # 過濾超長的雜訊列
        print(f"Candidate Text: {repr(text)}")
        links = item.find_all("a", href=True)
        symbol = ""
        for l in links:
            href = l['href']
            # 找網址包含 quote/2330.TW 的代號
            match = re.search(r'/quote/(\d{4})\.TW', href)
            if match:
                symbol = match.group(1)
                break
                
        # 尋找%數字
        weight_match = re.search(r'(\d+\.\d+)%', text)
        if symbol and weight_match:
             weight = float(weight_match.group(1))
             name_guess = text.split('|')[0].strip() # 抓取第一個欄位當作股名
             results.append({"symbol": symbol, "weight": weight, "name": name_guess})

print("\n--- 解析成果 ---")
for r in results[:5]:
    print(r)
