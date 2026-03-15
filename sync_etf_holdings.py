import os
import urllib.request
import re
from bs4 import BeautifulSoup
# pip install supabase
from supabase import create_client, Client

# 從環境變數中取得 Supabase 連線資訊 (GitHub Secrets自動帶入)
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

# 免持股張數爬蟲，只抓取 % 權重，由 Yahoo! 股市讀取公用數據
etf_list = ['0050', '0056', '00878', '00919', '00929', '006208', '00713', '00881', '00915', '00918']

def fetch_name_to_symbol_map():
    """從 supabase.tables('companies_api') 下載全台灣所有個股的 {名字: 代號} 對照"""
    mapping = {}
    try:
        res = supabase.table("companies_api").select("name, symbol").execute()
        for item in res.data:
            # 去除可能包含的空格，例如 "台積電 " 變為 "台積電"
            mapping[item['name'].strip()] = item['symbol'].strip()
    except Exception as e:
         print(f"下載 companies_api 故障: {e}")
    return mapping

def scrape_etf_yahoo(etf_code, name_to_symbol_map):
    print(f"--- 開始抓取 {etf_code} 權重 % ---")
    url = f"https://tw.stock.yahoo.com/quote/{etf_code}.TW/holding"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
    }
    
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            html = r.read().decode('utf-8')
            
        soup = BeautifulSoup(html, "html.parser")
        title_tag = soup.find(string="前十大持股")
        if not title_tag:
             print(f"未找到 {etf_code} 前十大持股列表標題。")
             return []
             
        # 往上退 5 層，抓取包裹整個列表的大範圍 text
        parent = title_tag.parent
        for _ in range(5):
             if parent: parent = parent.parent
             
        if not parent:
             print(f"{etf_code} 無法抓取到父節點包裹區塊。")
             return []
             
        text = parent.get_text(separator=' | ').strip()
        
        # 提取資料日期 (例如: 資料時間： | 2026/02/01)
        date_match = re.search(r'資料時間：\s*\|\s*(\d{4}/\d{2}/\d{2})', text)
        data_date = date_match.group(1) if date_match else "即時"
        print(f"-> {etf_code} 資料日期為: {data_date}")
        
        matches = re.finditer(r'([\u4e00-\u9fa5A-Za-z0-9]+)\s*\|\s*(\d+\.\d+)%', text)
        
        data_rows = []
        for m in matches:
             name = m.group(1).strip()
             weight = float(m.group(2))
             symbol = name_to_symbol_map.get(name)
             if symbol:
                  data_rows.append({
                      "etf_symbol": etf_code,
                      "stock_symbol": symbol,
                      "weight": weight,
                      "data_date": data_date # 寫入日期
                  })
             else:
                  print(f"跳過 {name} (%): 比對不到公司代號。")
                  
        print(f"-> {etf_code} 成功讀取到 {len(data_rows)} 筆權重數據。")
        return data_rows
    except Exception as e:
        print(f"讀取 {etf_code} 異常: {e}")
        return []

def main():
    if not url or not key:
        print("缺少 Supabase 憑證設定")
        return

    # 先取得個股名字與代號對照表 (省去重複查詢 API 的次數)
    name_to_symbol_map = fetch_name_to_symbol_map()
    print(f"成功加載 {len(name_to_symbol_map)} 筆各股代號對照字典。")

    all_data = []
    for etf in etf_list:
        items = scrape_etf_yahoo(etf, name_to_symbol_map)
        all_data.extend(items)
            
    if all_data:
        print(f"準備寫入 {len(all_data)} 筆權重 % 到 Supabase...")
        try:
            # 使用 Upsert (如果有重複 composite key 就覆寫 weight，並保留原有 shares)
            res = supabase.table("etf_holdings").upsert(
                all_data, 
                on_conflict="etf_symbol, stock_symbol"
            ).execute()
            print("資料自動權重覆寫同步完成！")
        except Exception as e:
             print(f"覆寫 Supabase 失敗: {e}")
    else:
        print("本次未更新到任何比重。")

if __name__ == "__main__":
    main()
