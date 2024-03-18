#

## Set up JupyterLab

```
ssh -L localhost:3135:localhost:3135 bheberlein@townsend-submit.chtc.wisc.edu
```

```
conda activate esker
```

```
dask-chtc jupyter run lab --port 4000
```



## Set up `dask-chtc` on CHTC

Create a conda environment with 

```
numpy
jupyterlab
dask
dask-jobqueue
dask-labextension
python-graphviz
```


```
conda clean --all
```

then install `dask-chtc`

```
pip install --upgrade git+https://github.com/CHTC/dask-chtc.git
```

try

```
dask-chtc --version
```

I encountered an incompatibility between `dask` & an old version of `dark_jobqueue` that was attempting to import the no-longer existing `dask.utilss.ignoring`. I had to do

`pip install dask-jobqueue --upgrade`


```
"C:\Program Files\PuTTY\putty.exe" -ssh 
```


### Launch dask lab

```
dask-chtc jupyter run lab --port 8888
```


### Connect from user machine

```
ssh -L localhost:3000:localhost:8888 bheberlein@townsend-submit.chtc.wisc.edu
```
