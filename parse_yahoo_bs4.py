from bs4 import BeautifulSoup
import re

# 讀取剛才儲存的 Yahoo HTML 備份檔
try:
    with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
        html = f.read()
        
    soup = BeautifulSoup(html, "html.parser")
    
    # 在 Yahoo 股市中，持股比例表格通常包在特定的 ListItem 或者是 Row 裡面
    # 觀察 context, 會有很多包含「台積電」、「鴻海」的區塊
    
    # 搜尋含有 "台積電" 並且可能是表格行的 div
    rows = soup.find_all("div", class_=lambda x: x and ("table-row" in x or "list-item" in x))
    if not rows:
         # 嘗試直接搜尋 <li> 或 <div> 包含文字的
         rows = soup.find_all("li", class_=lambda x: x and "ListItem" in x)
         
    print(f"找到 {len(rows)} 行數據區塊。")
    for r in rows[:10]:
         text = r.get_text()
         if "台積電" in text or "鴻海" in text:
              print(f"Row Text: {text}")
              
except Exception as e:
    print(f"Error: {e}")
