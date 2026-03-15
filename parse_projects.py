import codecs, re

with codecs.open('projects.txt', 'r', 'utf-16') as f:
    text = f.read()

lines = text.split('\n')
for line in lines:
    if 'yfetq' in line or 'wfvrl' in line or 'REFERENCE ID' in line:
        print(line.strip())
