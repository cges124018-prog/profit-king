from bs4 import BeautifulSoup
import re

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# 基於我們測試出的 Class 節點
items = soup.find_all("div", class_=lambda x: x and "C($c-link-text)" in x and "Ai(c)" in x)

print(f"找到 {len(items)} 個細部 row。")
count = 0
for item in items:
    text = item.get_text(separator=' | ').strip()
    # 打印前 10 筆比重資料
    if '%' in text and len(text) < 100:
        count += 1
        print(f"[{count}] {repr(text)}")
        links = item.find_all("a", href=True)
        for l in links:
            print(f"    Link: {l['href']}")
        if count >= 15:
            break
