# %%
import matplotlib.pyplot as plt
import matplotlib.pylab as pylab
import pandas as pd
import numpy as np


dsz=18
params = {'legend.fontsize': dsz,
          'figure.figsize': (15, 5),
         'axes.labelsize': dsz,
         'axes.titlesize':dsz,
         'xtick.labelsize':dsz,
         'ytick.labelsize':dsz}
pylab.rcParams.update(params)

# low, mid, high attributes
colors = ['#9370db', '#faa460', '#cd5c5c']
# %%
root_path = './final_runs'

def combine_df(app_name, root_path):
    logs_path = f'{root_path}/logs/{app_name}/{app_name}-irq.summary'
    results_path = f'{root_path}/results/{app_name}/{app_name}-irq.summary'
    config_path = f'{root_path}/config/{app_name}-irq_config.out'

    df1 = pd.read_csv(logs_path, sep=' ')
    df2 = pd.read_csv(results_path, sep=' ')
    df3 = pd.read_csv(config_path, sep=' ')

    merged = df1.merge(df2, on='uuid', how='outer', suffixes=('_log', '_res'))
    merged = merged.merge(df3, on='uuid', how='outer', suffixes=('', '_cfg'))

    return merged

def plot_irq(name, root_path, ax1, ax2):
    df = combine_df(name, root_path)

    baseline_df = df[df['type'] == 'baseline-irq']
    harvest_df = df[df['type'] == 'harvest-irq']
    irq_df = harvest_df[harvest_df['metadata'] == 'aware']
    noirq_df = harvest_df[harvest_df['metadata'] != 'aware']

    irq_norm_p99 = 100*(irq_df.groupby('qps')['p99'].mean() - baseline_df.groupby('qps')['p99'].mean()) / baseline_df.groupby('qps')['p99'].mean()
    noirq_norm_p99 = 100*(noirq_df.groupby('qps')['p99'].mean() - baseline_df.groupby('qps')['p99'].mean()) / baseline_df.groupby('qps')['p99'].mean()

    irq_norm_p99 = irq_norm_p99.clip(lower=0)


    irq_core_util = irq_df.groupby('qps')['time-weighted'].mean() - baseline_df.groupby('qps')['time-weighted'].mean()
    noirq_core_util = noirq_df.groupby('qps')['time-weighted'].mean() - baseline_df.groupby('qps')['time-weighted'].mean()



    xticks = np.arange(3)
    width = 0.2

    ax1.bar(xticks, noirq_norm_p99.values, width, color=colors, edgecolor='black')
    ax1.bar(xticks+width, irq_norm_p99.values, width, color=colors, edgecolor='black', hatch='*')

    for i in range(3):
        ax1.annotate(f'{int(noirq_norm_p99.values[i])}%', (xticks[i], noirq_norm_p99.values[i]+2), ha='center', va='bottom', rotation=90, fontsize=16)
        ax1.annotate(f'{int(irq_norm_p99.values[i])}%', (xticks[i]+width, irq_norm_p99.values[i]+2), ha='center', va='bottom', rotation=90, fontsize=16)

    ax1.set_xticks(xticks+width/2)
    ax1.set_xticklabels([])
    ax1.set_ylim(0,100)

    ax2.bar(xticks, noirq_core_util.values, width, color=colors, edgecolor='black')
    ax2.bar(xticks+width, irq_core_util.values, width, color=colors, edgecolor='black', hatch='*')
    for i in range(3):
        ax2.annotate(f'{noirq_core_util.values[i]:.2f}%', (xticks[i], noirq_core_util.values[i]+2*width), ha='center', va='bottom', rotation=90, fontsize=16)
        ax2.annotate(f'{irq_core_util.values[i]:.2f}%', (xticks[i]+width, irq_core_util.values[i]+2*width), ha='center', va='bottom', rotation=90, fontsize=16)

    ax2.set_ylim(0,8)
    ax2.set_xticklabels([])


    for x in xticks[:-1]:
        ax1.axvline(x=x+3*width, color='black', linestyle=':')
        ax2.axvline(x=x+3*width, color='black', linestyle=':')

    return baseline_df, harvest_df, irq_df, noirq_df, irq_norm_p99, noirq_norm_p99, irq_core_util, noirq_core_util


# %%

fig, axs = plt.subplots(2,3,figsize=(10, 5))

plot_irq('memcached', root_path, axs[0,0], axs[1,0])
axs[0,0].set_title('Memcached')
baseline_df, harvest_df, irq_df, noirq_df, irq_norm_p99, noirq_norm_p99, irq_core_util, noirq_core_util = plot_irq('mysql', root_path, axs[0,1], axs[1,1])
axs[0,1].set_title('MySQL')
plot_irq('xapian', root_path, axs[0,2], axs[1,2])
axs[0,2].set_title('Xapian')

axs[0,0].set_ylabel('P99 Latency \nIncrease %')
axs[1,0].set_ylabel('Cores \nHarvested')
fig.tight_layout()

# Add two legends at the top of the plot: one for "No IRQ" and one for "IRQ shielding"
import matplotlib.patches as mpatches

# Create legend handles for bar types
noirq_patch = mpatches.Patch(facecolor='white', edgecolor='black', label='OFF')
irq_patch = mpatches.Patch(facecolor='white', edgecolor='black', hatch='*', label='ON')

# Create legend handles for QPS levels (colors)
low_patch = mpatches.Patch(facecolor=colors[0], edgecolor='black', label='Low')
mid_patch = mpatches.Patch(facecolor=colors[1], edgecolor='black', label='Mid')
high_patch = mpatches.Patch(facecolor=colors[2], edgecolor='black', label='High')

# Add legends to the figure (top center)
legend1 = fig.legend(handles=[low_patch, mid_patch, high_patch], title='Primary Workload QPS', loc='upper center', ncol=3, bbox_to_anchor=(0.3, 1.22), fontsize=dsz, title_fontsize=dsz)
legend2 = fig.legend(handles=[noirq_patch, irq_patch], title='IRQ shielding', loc='upper center', ncol=2, bbox_to_anchor=(0.8, 1.22), fontsize=dsz, title_fontsize=dsz)
fig.add_artist(legend1)
fig.add_artist(legend2)

plt.savefig('figs/fig8.pdf', bbox_inches='tight')



# %%
