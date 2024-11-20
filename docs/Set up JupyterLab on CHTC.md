# Set up JupyterLab

## Assign Variables

```shell
SUBMIT=townsend-ap.chtc.wisc.edu
```

```shell
ssh -L localhost:3135:localhost:3135 bheberlein@$SUBMIT
```

```shell
conda activate esker
```

```shell
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


```shell
conda clean --all
```

then install `dask-chtc`

```shell
pip install --upgrade git+https://github.com/CHTC/dask-chtc.git
```

try

```shell
dask-chtc --version
```

I encountered an incompatibility between `dask` & an old version of `dark_jobqueue` that was attempting to import the no-longer existing `dask.utilss.ignoring`. I had to do

```shell
pip install dask-jobqueue --upgrade
```




```cmd
"C:\Program Files\PuTTY\putty.exe" -ssh 
```


### Launch dask lab

```shell
dask-chtc jupyter run lab --port 8888
```


### Connect from user machine

```shell
ssh -L localhost:3000:localhost:8888 bheberlein@$SUBMIT
```
