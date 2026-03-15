from bs4 import BeautifulSoup

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")
tag = soup.find(string="台積電")

if tag:
    # 這是包含 台積電 名字的那一列
    # 逐步往上看，直到整列的 row
    row = tag.parent
    for _ in range(3): # 可能是 2-3 層
         if row: row = row.parent
         
    if row:
         print(f"Row HTML class: {row.get('class')}")
         print(f"Row Full Text: {row.get_text(separator=' | ')}")
else:
    print("Not found.")
