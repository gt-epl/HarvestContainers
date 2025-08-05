# %%
import matplotlib.pyplot as plt
import matplotlib.pylab as pylab
import pandas as pd
import numpy as np
import re

Harvest_Color='#4cadab'
Harvest_Marker='v'
Baseline_Color='#0d68a8'
Baseline_Marker='s'

baseline_x264_progress = 363 # frames
baseline_dedup_progress = 1.08 # GB

# low, mid, high attributes
colors = ['#9370db', '#faa460', '#cd5c5c']

#TODO: CHANGE THIS TO THE PATH OF THE DATA
# root_path = '/mnt/extra/'
root_path = './final_runs'

dsz=18
params = {'legend.fontsize': dsz,
          'figure.figsize': (15, 5),
         'axes.labelsize': dsz,
         'axes.titlesize':dsz,
         'xtick.labelsize':dsz,
         'ytick.labelsize':dsz}
pylab.rcParams.update(params)

# %%
def combine_df(root_path):
    logs_path = f'{root_path}/logs/multi-primary/summary'
    xapian_results_path = f'{root_path}/results/multi-primary/xapian.summary'
    mysql_results_path = f'{root_path}/results/multi-primary/mysql.summary'
    config_path = f'{root_path}/config/multi-primary_config.out'


    df1 = pd.read_csv(config_path, sep=' ')
    df2 = pd.read_csv(logs_path, sep=' ')

    if len(df1) != len(df2):
        raise ValueError('config and progress UUIDs dont match')

    merged = df1.merge(df2, on='uuid', how='outer', suffixes=('_log', '_res'))

    xapian_df = pd.read_csv(xapian_results_path, sep=' ')
    mysql_df = pd.read_csv(mysql_results_path, sep=' ')

    if len(merged) != len(xapian_df):
        raise ValueError('config and xapian UUIDs dont match')
    if len(merged) != len(mysql_df):
        raise ValueError('config and mysql UUIDs dont match')

    merged = merged.merge(mysql_df, on='uuid', how='outer', suffixes=('', '_mysql'))
    merged = merged.merge(xapian_df, on='uuid', how='outer', suffixes=('', '_xapian'))

    return merged

def extract_x264_progress(progress_str):
    return float(progress_str)/baseline_x264_progress - 1


def extract_dedup_progress(progress_str):
    val = 0
    if progress_str.endswith('M'):
        val = float(progress_str.replace('M',''))/1000
    else:
        val = float(progress_str.replace('G',''))
    
    return max(0, val/baseline_dedup_progress - 1)

# %%

df = combine_df(root_path)
baseline_df = df[df['type'] == 'baseline']
harvest_df = df[df['type'] == 'harvest']



mysql_norm_p99 = harvest_df.groupby('qps')['p99'].mean() / baseline_df.groupby('qps')['p99'].mean()
mysql_norm_p99 = mysql_norm_p99.to_frame()

xapian_norm_p99 = harvest_df.groupby('qps')['p99_xapian'].mean() / baseline_df.groupby('qps')['p99'].mean()
xapian_norm_p99 = xapian_norm_p99.to_frame()

merged_norm_p99 = mysql_norm_p99.merge(xapian_norm_p99, on='qps', how='outer', suffixes=('_mysql', '_xapian'))


harvest_df = harvest_df.copy()
harvest_df['x264_relative_progress'] = harvest_df['x264_progress'].apply(extract_x264_progress)
harvest_df['dedup_relative_progress'] = harvest_df['dedup_progress'].apply(extract_dedup_progress)

x264_progress = harvest_df.groupby('qps')['x264_relative_progress'].mean().to_frame()
dedup_progress = harvest_df.groupby('qps')['dedup_relative_progress'].mean().to_frame()
merged_progress = x264_progress.merge(dedup_progress, on='qps', how='outer', suffixes=('_x264', '_dedup'))

fig, axs = plt.subplots(1,2,figsize=(15, 5))
width = 0.2
xticks = {qps: np.arange(2)+i*width for i,qps in enumerate(['LOW', 'MEDIUM', 'HIGH'])}

for i,qps in enumerate(['LOW', 'MEDIUM', 'HIGH']):
    axs[0].bar(xticks[qps], merged_norm_p99.loc[qps].values, color=colors[i], width=width)
    axs[1].bar(xticks[qps], merged_progress.loc[qps].values, color=colors[i], width=width)

    for j in range(2):
        axs[0].annotate(f'{merged_norm_p99.loc[qps].values[j]:.1f}%', (xticks[qps][j], merged_norm_p99.loc[qps].values[j]+width/4), fontsize=dsz, ha='center', va='bottom', rotation=90)

for ax in axs.flat:
    ax.set_xticks(xticks['MEDIUM'])

axs[0].set_ylabel('Normalized P99 Latency')
axs[0].set_xticklabels(['MySQL', 'Xapian'])
axs[0].set_ylim(0, 4)

axs[1].set_ylabel('Cores Harvested')
axs[1].set_xticklabels(['X264', 'Dedup'])
axs[1].set_ylim(0, 8)

# %%
fig.savefig('figs/fig9.pdf', bbox_inches='tight')
