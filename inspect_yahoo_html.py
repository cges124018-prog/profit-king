with open("yahoo_0050_holding.html", "r", encoding="utf-8") as f:
    text = f.read()
    idx = text.find("台積電")
    if idx != -1:
        print(f"Index: {idx}")
        print(f"Context: {repr(text[max(0, idx-500):idx+500])}")
    else:
        print("Not found containing 台積電")
