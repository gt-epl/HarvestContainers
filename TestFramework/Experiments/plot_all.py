# %%
import matplotlib.pyplot as plt
import matplotlib.pylab as pylab
import pandas as pd
import re

Harvest_Color='#4cadab'
Harvest_Marker='v'
Baseline_Color='#0d68a8'
Baseline_Marker='s'

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
def combine_df(app_name, root_path):
    logs_path = f'{root_path}/logs/{app_name}/summary'
    results_path = f'{root_path}/results/{app_name}/summary'
    config_path = f'{root_path}/config/{app_name}_config.out'

    df1 = pd.read_csv(logs_path, sep=' ')
    df2 = pd.read_csv(results_path, sep=' ')
    df3 = pd.read_csv(config_path, sep=' ')

    merged = df1.merge(df2, on='uuid', how='outer', suffixes=('_log', '_res'))
    merged = merged.merge(df3, on='uuid', how='outer', suffixes=('', '_cfg'))

    return merged

def extract_combined_progress(progress_str):
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
# %%
def plot_latency_and_util(app_name, ax1, ax2):
    width = 0.4
    rotation = -30

    df = combine_df(app_name, root_path)
    baseline_df = df[df['type'] == 'baseline']
    harvest_df = df[df['type'] == 'harvest']

    # Obtain p99 in sorted qps order
    baseline_p99 = baseline_df.groupby('qps')['p99'].mean().sort_index().values
    harvest_p99 = harvest_df.groupby('qps')['p99'].mean().sort_index().values

    # df['progress'].apply(extract_combined_progress).values
    harvest_util = harvest_df.groupby('qps')['time-weighted'].mean().values
    baseline_util = baseline_df.groupby('qps')['time-weighted'].mean().values

    secondary_progress = harvest_util - baseline_util

    # latency
    ax1.plot(harvest_p99, marker=Harvest_Marker, color=Harvest_Color)
    ax1.plot(baseline_p99, marker=Baseline_Marker, color=Baseline_Color)

    qps = harvest_df['qps'].unique()
    qps.sort()

    # if a decimal is 0, then round to the nearest integer
    qps_k = [f"{int(qps[i]/1000) if qps[i] % 1000 == 0 else qps[i]/1000}k" for i in range(len(qps))]
    xticks = range(len(qps_k))
    ax1.set_xticks(xticks)
    ax1.set_xticklabels(qps_k, rotation=rotation)

    ax1.grid(color='gray', ls='--', which='major', lw=0.6)
    ax1.grid(color='gray', ls='--', which='minor', lw=0.2)


    # util
    ax2.bar(xticks, baseline_util, width, label='Primary', color=Baseline_Color, edgecolor='black', linewidth=0.5)
    ax2.bar(xticks, secondary_progress, width, label='Harvest', bottom=baseline_util, color=Harvest_Color, edgecolor='black', linewidth=0.5)
    ax2.set_ylim(0,8)
    ax2.set_xticks(xticks)
    ax2.set_xticklabels(qps_k, rotation=rotation)

    ax2.grid(color='gray', ls='--', which='major', lw=0.6)
    ax2.grid(color='gray', ls='--', which='minor', lw=0.2)

# %%
fig, axs = plt.subplots(2, 3, figsize=(15, 6))
plot_latency_and_util('memcached', axs[0, 0], axs[1, 0])
axs[0, 0].set_yticks(range(0,130,20))
axs[0, 0].set_yticklabels(range(0,130,20))
axs[0, 0].set_ylim(0, 130)
axs[0, 0].set_ylabel('Latency (ms)')
axs[0, 0].set_title('Memcached')

plot_latency_and_util('mysql', axs[0, 1], axs[1, 1])
axs[0, 1].set_yticks(range(0,900,200))
axs[0, 1].set_yticklabels(range(0,900,200))
axs[0, 1].set_ylim(0, 900)
axs[0, 1].set_title('MySQL')
axs[1, 1].set_xlabel('QPS')

plot_latency_and_util('xapian', axs[0, 2], axs[1, 2])
axs[0, 2].set_yticks(range(0,5))
axs[0, 2].set_yticklabels(range(0,4500,1000))
axs[0, 2].set_ylim(0, 4)
axs[0, 2].set_title('Xapian')

fig.savefig('figs/fig5.pdf', bbox_inches='tight')

# %%
