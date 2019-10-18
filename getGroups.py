import re
import subprocess

inp = ""

#with open("/tmp/test") as f:
#    inp = f.read()

inp =  subprocess.getoutput("ipa group-find ")
#print(inp)

regex = re.compile(r'name:\s(.*)\n\s\sDescription\:\s(.*)')

result = regex.finditer(inp)
for mo in result:
    for group in mo.groups():
        print(group)
    print("OFF")
