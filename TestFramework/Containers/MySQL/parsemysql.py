import pandas as pd
import sys

df = pd.read_csv(sys.argv[1], header=None)

p50 = df[100:][2].astype('float').quantile(.99)
p90 = df[100:][2].astype('float').quantile(.99)
p95 = df[100:][2].astype('float').quantile(.99)
p99 = df[100:][2].astype('float').quantile(.99)
mean = df[100:][2].astype('float').mean()
lmin = df[100:][2].astype('float').min()
lmax = df[100:][2].astype('float').max()

print(f'{mean} {p50} {p90} {p95} {p99} {lmin} {lmax}')