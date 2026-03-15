import codecs

with codecs.open('deploy_help.txt', 'r', 'utf-16') as f:
    lines = f.readlines()

for line in lines:
    print(line.strip())
