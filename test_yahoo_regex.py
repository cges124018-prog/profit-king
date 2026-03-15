from bs4 import BeautifulSoup
import re

with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# 尋找前十大持股的 wrapper div
# 先抓取包含 "前十大持股" 文字的節點
title_tag = soup.find(string="前十大持股")

if title_tag:
    parent = title_tag.parent
    for i in range(5): # 往上退 5 層，試圖抓取包裹整個列表的大 div
         if parent: parent = parent.parent
         
    if parent:
         text = parent.get_text(separator=' | ').strip()
         print(f"Wrapper Text Length: {len(text)}")
         print(f"Snippet: {repr(text[100:600])}") # 打印片段
         
         # 使用 Regex 匹配 "名稱 | %"
         # 例如: "台積電 | 51.27%" 或 "富邦金 | 4.5%"
         # 由於有 | 分隔，我們匹配  名稱 | 數據%
         # Regex:  ([\u4e00-\u9fa5A-Za-z0-9]+)\s*\|\s*(\d+\.\d+)%
         matches = re.finditer(r'([\u4e00-\u9fa5]+)\s*\|\s*(\d+\.\d+)%', text)
         
         print("\n--- Regex 匹配結果 ---")
         for m in matches:
              print(f"名稱: {m.group(1)}, 比重: {m.group(2)}%")
    else:
         print("No parent found.")
else:
    print("No title tag found.")
