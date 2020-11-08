import sys
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv(sys.argv[1], encoding='UTF8')

fig = plt.figure()
ax = plt.gca()

if sys.argv[4] == 'log':
  ax.set_xscale('log')
  ax.set_yscale('log')

for label in [('MethodChannelMemset', 'MethodChannel'), \
  ('ffiMemsetAndConvert', 'FFI and data conversion'), ('ffiMemsetWithListView', 'FFI with ListView'), ('ffiMemset', 'FFI only')]:
  series = df[df['type'] == label[0]]
  print(series)
  data_kb = series['dataSize[KB]']
  time_us = series['time[ns]'] / 1000
  ax.plot(data_kb, time_us, label=label[1], marker='o')

ax.set_title('Time of memset ' + sys.argv[3])
ax.set_xlabel('dataSize[KB]')
ax.set_ylabel('time[us]')
plt.legend()
plt.grid(which='both')
fig.savefig(sys.argv[2])