import numpy as np
import pandas as pd
import matplotlib.pylab as plt

import pyhgf.response
import seaborn as sns
import math
import os
import glob

import pyhgf
from pyhgf.model import Network, HGF
from pyhgf.typing import AdjacencyLists

import arviz as az
import jax.numpy as jnp
import pymc as pm

from pyhgf.distribution import HGFDistribution


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

# format data
u_bin = np.array(df[" jSuccess"]).astype('float32')
y_pred = np.array(df[" prediction"])
u_pe = u_bin - y_pred
y_mc = np.array(df[" control"])


## create BINARY HGF as PyMC distribution
hgf_logp_op = HGFDistribution(
    n_levels=2,
    model_type="binary",
    input_data=u_bin[jnp.newaxis, :],
    response_function=pyhgf.response.first_level_gaussian_surprise,
    response_function_inputs=y_pred[jnp.newaxis, :]
)

with pm.Model() as beta_hgf:

    # prior over the evolution rate at the second level
    tonic_volatility_2 = pm.Normal("tonic_volatility_2", -2.0, 2.0)

    # the main HGF distribution
    pm.Potential("hgf_loglike", hgf_logp_op(tonic_volatility_2=tonic_volatility_2))

with beta_hgf:
    beta_hgf_idata = pm.sample(chains=2, cores=1)

az.plot_trace(beta_hgf_idata, var_names=["tonic_volatility_2"]);
az.summary(beta_hgf_idata, var_names=["tonic_volatility_2"])

# get samples
stacked1 = az.extract(beta_hgf_idata)
stacked1.tonic_volatility_2.values
om2 = np.mean(stacked1.tonic_volatility_2).item()

# create agent (with inferred param values)
agent1 = HGF(
    n_levels=2,
    model_type="binary",
    initial_mean={"1": .0, "2": .5},
    initial_precision={"1": .0, "2": 1e4},
    tonic_volatility={"2": om2},
).input_data(input_data=u_bin)

agent1.plot_trajectories()
plt.show()
agent1.to_pandas().head()


## create CONT HGF as PyMC distribution
hgf_logp_op2 = HGFDistribution(
    n_levels=2,
    model_type="continuous",
    input_data=u_pe[jnp.newaxis, :],
    response_function=pyhgf.response.first_level_gaussian_surprise,
    response_function_inputs=y_mc[jnp.newaxis, :]
)

with pm.Model() as mc_hgf:

    # prior over the evolution rate at the second level
    tonic_volatility_1 = pm.Normal("tonic_volatility_1", -3.0, 2.0)

    # the main HGF distribution
    pm.Potential("hgf_loglike", hgf_logp_op2(tonic_volatility_1=tonic_volatility_1))

with mc_hgf:
    mc_hgf_idata = pm.sample(chains=2, cores=1)

az.plot_trace(mc_hgf_idata, var_names=["tonic_volatility_1"]);
az.summary(mc_hgf_idata, var_names=["tonic_volatility_1"])

# get samples
stacked2 = az.extract(mc_hgf_idata)
stacked2.tonic_volatility_1.values
om1_mc = np.mean(stacked2.tonic_volatility_1).item()

# create agent (with inferred param values)
mc_agent = HGF(
    n_levels=2,
    model_type="continuous",
    initial_mean={"1": 0.0, "2": 0.0},
    initial_precision={"1": 1.0, "2": 1.0},
    tonic_volatility={"1": om1_mc, "2": -3.0}
).input_data(input_data=u_pe)

az.plot_trace(mc_hgf_idata)
mc_agent.plot_trajectories()
plt.show()

print("DONE.")
