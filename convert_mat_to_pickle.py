import numpy as np
import scipy.io
import h5py


data_all = scipy.io.loadmat("data_all.mat")

trials = data_all.get('data').shape[1]
timesteps = 100
dims = 5
control_dims = 2

y_data = np.zeros((trials,timesteps,dims))
u_data = np.zeros((trials,timesteps-1,control_dims))
latent_data = np.zeros((trials,timesteps,dims))

for i in range(trials):
    y_data[i]      = data_all.get('data')[0, i][0]
    u_data[i]      = data_all.get('data')[0, i][1]
    latent_data[i] = data_all.get('data')[0, i][2]

with h5py.File('data_all.h5', 'w') as hf:
    hf.create_dataset("y_data",  data=y_data)
    hf.create_dataset("u_data", data=u_data)
    hf.create_dataset("latent_data", data=latent_data)