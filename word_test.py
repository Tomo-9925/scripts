#!/usr/bin/env python
'''
# このスクリプトについて
実行方法: `python [このファイル]`
CSVファイルをもとに単語テストを行います．
CSVファイルは`問題, 回答(, 別解)*`のように記入してください．
また，読み込むCSVファイルは事前にcsv_path変数に記入してください．
'''

import csv
import random

csv_path = '1.csv'

data = []
file = open(csv_path)
for row in csv.reader(file):
    data.append(row)

correct = [False] * len(data)
while False in correct:
    num = random.randrange(len(data))
    while correct[num] == True:
        num = random.randrange(len(data))
    print(data[num][0])
    ans = input("解答: ").rstrip()
    if ans != data[num][0] and ans in data[num]:
        correct[num] = True
    else:
        print("答え: " + "，".join(data[num][1:]))
