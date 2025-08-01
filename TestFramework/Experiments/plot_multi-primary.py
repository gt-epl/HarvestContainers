# %%
import matplotlib.pyplot as plt
import matplotlib.pylab as pylab
import pandas as pd
import re

Harvest_Color='#4cadab'
Harvest_Marker='v'
Baseline_Color='#0d68a8'
Baseline_Marker='s'

# low, mid, high attributes
colors = ['#9370db', '#faa460', '#cd5c5c']

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

    merged = df1.merge(df2, on='uuid', how='outer', suffixes=('_log', '_res'))

    xapian_df = pd.read_csv(xapian_results_path, sep=' ')
    mysql_df = pd.read_csv(mysql_results_path, sep=' ')

    merged['xapian_p99'] = merged['uuid'].map(xapian_df.set_index('uuid')['p99'])
    merged['mysql_p99'] = merged['uuid'].map(mysql_df.set_index('uuid')['p99'])

    return merged

def extract_x264_progress(progress_str):
    """
    Extracts the integer value after 'Combined Progress:' in the given string.
    Returns None if not found or not an float.
    """
    if not isinstance(progress_str, str):
        return None
    match = re.search(r'Combined Progress:\s*(\d+)', progress_str)
    if match:
        return float(match.group(1)) / secondary_baseline_progress
    return None


def extract_dedup_progress(progress_str):
    """
    Extracts the integer value after 'Combined Progress:' in the given string.
    Returns None if not found or not an float.
    """
    if not isinstance(progress_str, str):
        return None
# %%


df = combine_df(root_path)
baseline_df = df[df['type'] == 'baseline']
harvest_df = df[df['type'] == 'harvest']


xapian_norm_p99 = baseline_df['xapian_p99'].groupby('qps').mean() / harvest_df['xapian_p99'].groupby('qps').mean()
mysql_norm_p99 = baseline_df['mysql_p99'].groupby('qps').mean() / harvest_df['mysql_p99'].groupby('qps').mean()

low_norm_p99 = xapian_norm_p99.loc['LOW'], mysql_norm_p99.loc['LOW']
mid_norm_p99 = xapian_norm_p99.loc['MEDIUM'], mysql_norm_p99.loc['MEDIUM']
high_norm_p99 = xapian_norm_p99.loc['HIGH'], mysql_norm_p99.loc['HIGH']

baseline_x264_progress = 363 # frames
baseline_dedup_progress = 1

harvest_x264_progress = extract_x264_progress(harvest_df['x264_progress'].values)
harvest_dedup_progress = extract_dedup_progress(harvest_df['dedup_progress'].values)

norm_x264_progress = harvest_x264_progress / baseline_x264_progress - 1
norm_dedup_progress = harvest_dedup_progress / baseline_dedup_progress - 1

low_norm_progress = norm_x264_progress.loc['LOW'], norm_dedup_progress.loc['LOW']
mid_norm_progress = norm_x264_progress.loc['MEDIUM'], norm_dedup_progress.loc['MEDIUM']
high_norm_progress = norm_x264_progress.loc['HIGH'], norm_dedup_progress.loc['HIGH']

fig, axs = plt.subplots(1,2,figsize=(15, 5))
ax = axs[0]
ax.bar(low_norm_p99, color=colors[0])
ax.bar(mid_norm_p99, color=colors[1])
ax.bar(high_norm_p99, color=colors[2])
ax.set_ylabel('Normalized P99 Latency')

ax = axs[1]
ax.bar(low_norm_progress, color=colors[0])
ax.bar(mid_norm_progress, color=colors[1])
ax.bar(high_norm_progress, color=colors[2])
ax.set_ylabel('Cores Harvested')

