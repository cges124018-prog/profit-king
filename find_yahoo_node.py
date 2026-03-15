from bs4 import BeautifulSoup

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# 尋找含有 "台積電" 的任何區段
tag = soup.find(string="台積電")
if tag:
    parent = tag.parent
    print(f"台積電 Tag: {parent}")
    # 打印上 3 層父節點的 class
    curr = parent
    for i in range(5):
         if curr:
              print(f"Parent {i}: {curr.name} - Class: {curr.get('class')}")
              curr = curr.parent
else:
    print("Not found 台積電 string.")
