from bs4 import BeautifulSoup
import re

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# 尋找所有 包含 "% " 與佔比的小區段
# 往往都是特定的 div, 包含名稱與百分比
all_divs = soup.find_all("div")
count = 0

print("--- 搜尋包含大比重數據的 div 列表 ---")
for d in all_divs:
    text = d.get_text(separator=' | ').strip()
    if '51.27%' in text and len(text) < 100:
        count += 1
        print(f"[{count}] {repr(text)}")
        # 尋找 href
        links = d.find_all("a", href=True)
        for l in links:
             print(f"    Link: {l['href']}")
