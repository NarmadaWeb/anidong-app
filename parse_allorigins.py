import json
import sys
try:
    with open('allorigins.json', 'r') as f:
        data = json.load(f)
        print(data['contents'][:1000])
except Exception as e:
    print(e)
