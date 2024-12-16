import numpy as np
import pandas as pd
import matplotlib.pylab as plt

import seaborn as sns
import math
import os
import glob

import pyhgf
from pyhgf.model import Network, HGF
from pyhgf.typing import AdjacencyLists


# load PPID file
id = pd.read_csv(r"data\metac_ppids_exploration_task_v3_1.txt")
ppid = "TNU_METAC_" + str(id['PPID'][0]) # get first PPID

# path root
b_basedir = r"R:\METAC\behavior\raw" #bluebay
t_fname = "behavior\\task\\*.csv"

t_fullpath = os.path.join(b_basedir, ppid, t_fname)

# load task data (experiment)
for t_file in glob.glob(t_fullpath):
    if t_file.find("experiment") != -1:

        # task settings
        specifications = pd.read_csv(t_file, nrows=1)

        # repeat rows
        n_trials = specifications.values[0,0] # get nTrials
        t_specs80 = pd.DataFrame(np.repeat(specifications.values, n_trials, axis=0)) # repeat rows nTrial-times
        t_specs80.columns = specifications.columns # assign column names

        # responses
        t_dat = pd.read_csv(t_file, skiprows=[0,1,83,84]) # skip task specs and single aversiveness rating (if there)


# concatenate arrays (t_reponses + t_specifications + quest)
df = pd.concat([t_dat, t_specs80], axis=1)


# # plot responses
# sns.relplot(data=df, x="trial#", y=" jSuccess", hue=' wind')
# sns.relplot(data=df, x="trial#", y=" prediction", hue=' wind')
# sns.relplot(data=df, x="trial#", y=" control", hue=' wind')

# # replace -1 placeholder values
# df = df.replace(to_replace={' handling': [-1],
#                             ' tolerance': [-1],
#                             ' aversiveness': [-1]}, value=np.nan)
# sns.relplot(data=df, x='trial#', y=' handling', hue=' wind')
# sns.relplot(data=df, x='trial#', y=' tolerance', hue=' wind')
# sns.relplot(data=df, x='trial#', y=' aversiveness', hue=' wind')

# plt.show()


# creating probabilistic nodes
parameters = {"mean": 0.0, "precision": 1.0}

attributes = (parameters, parameters, parameters)

# AdjacencyLists(node_type, val_parents, volat_parents, val_children, volat_ch, coupling_fn)
# first entry: node type (0=cont input, 1=binary input node, 2=cont state node)
edges = (
    AdjacencyLists(0, (1,), None, None, None, (None,)),
    AdjacencyLists(2, None, (2,), (0,), None, (None,)),
    AdjacencyLists(2, None, None, None, (1,), (None,)),
)

# create a three-level HGF using default parameters
hgf_bin = HGF(n_levels=3, model_type="binary")
#hgf_bin.plot_network()

dat_bin = np.array(df[" jSuccess"])

hgf_bin.input_data(input_data=dat_bin.astype('float32'))

axs_bin = hgf_bin.plot_nodes([2, 1, 0], figsize=(12, 8))
sns.despine()
plt.show()


## modyfing the ATTRIBUTES
hgf_bin.attributes[2]["precision"] = 5.0

# method 1
new_input_precision_1 = Network().add_nodes(
    precision=10.0
)

# method 2
new_input_precision_2 = Network().add_nodes(
    node_parameters={"precision": 10.0}
)

# both methods change the default values, but only method 2 will create a new key without error
assert (
    new_input_precision_1.attributes[0]["precision"]
    == new_input_precision_2.attributes[0]["precision"]
)


## modifying the EDGES
a_custom_hgf = (
    Network()
    .add_nodes()
    .add_nodes(value_children=0)
    .add_nodes(value_children=1, n_nodes=3)
    .add_nodes(volatility_children=[2, 3])
    .add_nodes(volatility_children=4)
    .add_nodes(volatility_children=[5, 6])
)
#a_custom_hgf.plot_network()
a_custom_hgf.edges[4]


## MULTIVARIATE COUPLING

# simulate some time series - one Gaussian noise and one noisy in wave
u_0 = np.random.normal(0, 0.5, size=1000)
u_1 = np.sin(np.arange(0, 1000) / 30) * 8 + np.random.normal(0, 0.5, size=1000)

input_data = np.array([u_0, u_1]).T

# creating a network that contains many child nodes are value coupled to one parent node
many_value_children_hgf = (
    Network()
    .add_nodes(precision=1e4, n_nodes=2)
    .add_nodes(value_children=[0, 1])
    .add_nodes(volatility_children=2, mean=4.0)
)

# plot the network
#many_value_children_hgf.plot_network()

many_value_children_hgf.input_data(input_data=input_data);

axs = many_value_children_hgf.plot_nodes([3, 2], figsize=(12, 5))
for i in range(2):
    axs[1].scatter(
        np.arange(0, 1000), 
        input_data[:, i],
        color="#4c72b0",
        alpha=0.2,
        s=5,
        edgecolors="k",
        zorder=10,
    )
sns.despine()
plt.show()


print("success")
