from bs4 import BeautifulSoup
import re

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")
items = soup.find_all("div", class_=lambda x: x and "table-row" in x)
if not items:
    items = soup.find_all("div", class_=lambda x: x and "C($c-link-text)" in x) # 包含文字連結的
    
count = 0
for item in items:
    text = item.get_text(separator=' | ').strip()
    if '%' in text and len(text) < 500:
        count += 1
        print(f"[{count}] {repr(text)}")
        if count >= 8:
            break
