from bs4 import BeautifulSoup
import re

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# 尋找含有佔比 % 的區塊
results = []
items = soup.find_all("div", class_=lambda x: x and ("D(f) Ai(c)" in x or "grid-item" in x))

print("打印前 5 個包含 % 的候選行：")
count = 0
for item in items:
    text = item.get_text(separator=' | ').strip()
    if '%' in text and len(text) < 150:
        count += 1
        print(f"[{count}] {repr(text)}")
        if count >= 10:
             break
