# Preparing a Portable Python Environment with Miniconda

These instructions were adapted from the [CHTC website](https://chtc.cs.wisc.edu/uw-research-computing/conda-installation.html).

## References

* [`conda` Documentation](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#)


## Preparing a New Environment

A new Python environment can be built from within your user home directory on the submit server.


1) **Download & install miniconda**

```{bash eval=F}
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh
source ~/.bashrc
```

Work through the prompts. You will be given a chance set a new save location, e.g. `/home/username/conda`

Say 'yes' to initialize.





2. **Build a conda environment**
   A custom Python environment can easily be built from .YML file:

  ```{bash eval=F}
conda env create -f htconda.yml
  ```

  The .YML file contains a simple plaintext description of the environment dependencies:

  ```{yml}
name: htconda
channels:
  - conda-forge
dependencies:
  - python>=3.8
  - gdal>=3.3
  - numpy>=1.20
  - matplotlib=3.3
  - pandas=1.2
  - scipy=1.6
  - numba
  - shapely
  - arosics
  - lxml
  ```

  An older one:

  ```{yml}
name: cattree
channels:
  - conda-forge
dependencies:
  - python=3.6
  - gdal=2.4.4
  - numpy=1.19.4
  - matplotlib=3.3.2
  - pandas=1.1.4
  - h5py=2.10.0
  - scipy=1.5.3
  - scikit-learn
  - numba
  ```

  Alternately, the environment can be built interactively using `conda`:

  ```{bash eval=F}
conda create -n cattree python=3.6 
conda activate cattree
conda install gdal scipy pandas numpy h5py scikit-learn numba
conda deactivate
  ```



3. **Package the environment into a .tar archive**
   Finally, the environment is packed from within the base environment:

  ```{bash eval=F
conda deactivate
conda install -c conda-forge conda-pack
  ```

  ```{bash eval=F}
conda pack -n htconda
chmod 644 htconda.tar.gz
  ```


4) Don't forget to clean up!
  ```{bash eval=F}
rm Miniconda3-latest-Linux-x86_64.sh
  ```


## Deploying a packaged environment

Set up the environment as

```{bash eval=F}
export PATH
mkdir $ENVDIR
tar -xzf $ENVNAME.tar.gz -C $ENVDIR
. $ENVDIR/bin/activate
```



Deactivate if needed with

```{bash eval=F}
source $ENVDIR/bin/deactivate
```

