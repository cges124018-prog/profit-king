from bs4 import BeautifulSoup
import re

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

items = soup.find_all("div", class_=lambda x: x and "C($c-link-text)" in x and "Ai(c)" in x)

for idx, item in enumerate(items):
    text = item.get_text(separator=' | ').strip()
    print(f"[{idx}] {repr(text)}")
    links = item.find_all("a", href=True)
    for l in links:
         print(f"    Link: {l['href']}")
