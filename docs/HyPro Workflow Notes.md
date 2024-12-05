# Processing Hyperspectral Imagery with HyPro

## About HyPro

HyPro is a Python package for processing raw imaging spectrometer data with a focus on airborne applications.



## Notes

### Filepaths

- **Pay careful attention to the filepaths** in the examples here. In particular, pay attention to **whether or not the path begins with a slash** (`/`) , which indicates that the path is **absolute**, i.e. expressed relative to the filesystem root. By comparison, **relative paths** (which do not begin with a slash) are expressed and interpreted relative to the current working directory, or the directory from which a command or script is called.

### Accessing CHTC

- You will ned to get a CHTC account.
- You will need to be added to `townsend_group` to access the shared Staging space.

### How to read the examples

Various examples below use variables (e.g. `$SESSION`) as placeholders to more clearly illustrate the standard naming conventions. Examples of actual values these variables might take for a particular image are shown below:

```shell
PROJECT=FRAX_2023
SITE=LOEW
SESSION=LOEW_20230621
FLIGHTLINE=LOEW_20230621_01
```

Additionally, certain domain names & filepaths have been abbreviated:

```shell
CHTC_GROUP=townsend_airborne
FARNSWORTH=farnsworth.russell.wisc.edu
TRANSFER=transfer.chtc.wisc.edu
STAGING=/staging/groups/$CHTC_GROUP
```



## Processing Inputs

### Primary Data Inputs

- Semi-permanent datasets kept on CHTC Staging
  - **Atmospheric lookup tables**
  - **Surface elevation model** (i.e. DEM or DSM)
- Included in the `hypro*.tar.gz` file pulled by the jobs
  - **Sensor calibration files**
  - **Sensor geometric model**
- Included in the raw data input `*.tar.gz` files pulled by the jobs
  - **Raw DN images** & header files
  - **Navigation data** (camera positions & orientations for each frame in the image)

### Supporting Files for CHTC

For CHTC processing, some additional files com into play:

- Packages

  - HyPro (Python code for reflectance processing)
  - Conda (Python environment with dependencies installed)

- Support files

  - Job lists

  - Config files



## Running Processing

### Overview

- **Running processing with HyPro**

  - You can use HyPro to process raw imaging spectrometer DN images to surface reflectance images by calling the main workflow

    ```shell
    python $src/hypro/workflow/main.py $config
    ```

    where `$src` is the HyPro source code directory (usu. `src` within top-level directory of the HyPro repository) and `$config` is the path to the processing configuration JSON file).

  - A processing configuration JSON file (*"config file"*) is required to run HyPro in this manner.

    - This is a JSON file that specifies processing parameters (e.g. input & output directories, pixel size, surface elevation model (DEM or DSM), or region of interest (ROI) polygon).

  - When running in a "local" context (i.e. on your own machine vs. on a distributed computing system), this is all that's really needed to run the processing (apart from the various input files, of course, i.e. the `*.hyspex` images, their associated `*.hdr` files, and the navigation data `*.txt` files; the surface elevation model; the calibration files & geometric models for the imaging sensors; and the atmospheric lookup tables).

- **Running HyPro on CHTC**

  - The CHTC workflow is ultimately just a wrapper around the local workflow, shown above.
  - The CHTC workflow is set up to manage inputs & options to HyPro across a **batch** of flightlines to be processed (jobs to be run).
    - The **job list** file lists the **input parameters** & **resource requirements** for each flightline, one per line.
    - Jobs are queued from the job list and, for each job, the executable attempts to locate the **config file** using the flightline parameters (site, date, line number) which are passed as arguments.
  - Before the CHTC workflow can be run, the necessary files must be transferred to CHTC servers.
    - The **raw data inputs** (`*.tar.gz`) must be transferred to **CHTC Staging** (`$STAGING/data/raw`).
    - The **config file(s)** must be transferred to **CHTC Staging** (`$STAGING/config`). The config files may be defined on a per-site, -session or -flightline basis. These are JSON files that are used to configure the processing options.
    - The **job list** (`*_JobList.txt`) must be transferred to CHTC (e.g. **either** to `$STAGING/joblist` or to your user home on `townsend-submit`). The job list is a plaintext file that defines a batch of jobs, providing the flightline parameters (site name, date & flightline number) and resource requirements (disk & memory requests) for each job, one per line.
  - Other files that must be available on Staging include:
    - Atmospheric lookup tables
    - Surface elevation model (DEM or DSM)
  - Once you are set up on a remote machine with the necessary files & code in place, running HyPro on a CHTC worker node is exactly the same as running it locally on your machine! But a lot of additional code is needed to set up the workspace, transfer files, etc. which is all contained in the job executable.



## DEM Processing

A raster DEM or DSM is needed for best results when processing imagery in HyPro. The DEM file is one of the important data inputs, and should be placed on Staging in the `townsend_hyspex` space, within `data/surface`. Note that the configuration JSON file must have the correct filepath, which should be an absolute path pointing to Staging (i.e. to a file within `$STAGING/data/surface`).

- DEM should be a regularly-gridded raster in **ENVI format**, with the grid oriented **north-up**.
- Horizontal coordinate system is **WGS84/UTM**, usually zone **16N** or **15N** (**EPSG:32616** or **32615**; units are **meters**).
- Vertical units are **meters**; vertical datum may be ellipsoid- or geoid-referenced.
- If you need to reproject the data, **don't use nearest-neighbor resampling**! This will distort the surface & create processing artifacts. Use any proper interpolation technique, e.g. linear, cubic or cubic spline.



## Reflectance Processing

### Preprocessing

Launch the **"CHTC Preprocessing**" Jupyter notebook & run the code cells to do the following:

1. **Query database to find images to be processed.**
   - [x] Verify the total number of images/sessions
   
   - [x] Verify pixel size
   
   - [x] Verify DEM & vertical datum
   
2. **Package up the raw data input files into `.tar.gz` archives.**

   - Each archive will contain 6 files (2 each of `*.hyspex`, `*.hdr`, `*.txt`).

3. **Move input archives to CHTC Staging via Globus.**

4. **Generate the job list.**

   - Place in `$STAGING/joblist`.

5. **Generate the processing configuration file (JSON).**

   - Config can be generated at the level of **project**, **session** or **flightline**. To be found by the CHTC job script, the config must be named according to the correct naming conventions. The script will look for the following files, in order, and use the first one that it finds.
     1. A **flightline-level** config file <u>nested in a session directory</u>, named as **`${SESSION}/${FLIGHTLINE}_Config.json`**.
     2. A **session-level** config, named as **`${SESSION}_Config.json`**.
     3. A **season-level** config, named as **`${SITE}_${YEAR}_Config.json`**.
     4. A **project-level** config, named as **`${PROJECT}_Config.json`**.
   - Place in `$STAGING/config`.



### Copying files to & from CHTC Staging

Connect to the **Transfer server** (`transfer.chtc.wisc.edu`) to move large files (or large numbers of files) to & from CHTC Staging.

- For MacOS or Linux, use `scp` or [`rclone`](https://rclone.org) (command line) or [FileZilla](https://filezilla-project.org) (GUI).
- For Windows, connect via [PuTTY](https://www.putty.org) (command line) or [WinSCP](https://www.winscp.net) (GUI).

#### Using `scp`

We can move data between Farnsworth drive & CHTC Staging **using `scp` on Krusty**. This is possible because there is a network mount point on Krusty.

To copy the contents of a directory from Staging to Farnsworth, for example,

```shell
scp -r $USER@$TRANSFER:$STAGING/data/processed/$SESSION
$FARNSWORTH/data/processed/airborne/$PROJECT/$YEAR/refl
```

> **NOTE:** For `scp`, similar to `ssh` & other tools, the user & address of a remote machine can be specified along with the file path as `user@address:/path`.

#### Using `rclone`

##### Configure remotes

To transfer files with `rclone`, you first need to register the remote machine.

Locate the config file with

```shell
rclone config file
```

##### Copy files

```shell
rclone copy -P "remote:..."
```

#### Using WinSCP

> **NOTE:** By default, WinSCP will open multiple connections to transfer files in parallel. While this achieves faster transfer speeds overall, it can be annoying when you are repeatedly asked to authenticate with MFA Duo. In *Preferences* > *Transfer* > *Background*, under "background Transfers" uncheck *"Use multiple connections for single transfer"*. This will ensure you only authenticate once per transfer, with some loss of speed.



### Submitting jobs on CHTC

- Connect to the **submit server** to submit jobs.
  
  - We have our own dedicated submit server hardware at **`townsend-submit.chtc.wisc.edu`**.
    - *Let CHTC know in your application form that you will need access to `townsend-submit` & our `townsend_hyspex` group allocation on Staging.*
  - CHTC has general-use submit servers at `ap2001.chtc.wisc.edu` & `ap2002.chtc.wisc.edu`.
    - We don't usually use these, but they can serve as a backup if `townsend-submit` is having issues or otherwise needing maintenance.
    - *If you have only used `townsend-submit` in the past, you may need to request access.*
  - Make sure that you have prepared your workspace on the submit server (see [Setting up CHTC Workspace](#setting-up-chtc-workspace), below). This only needs to be done once (though you may occasionally need to pull updates to the `hypro-chtc` repo, i.e. usually `git pull origin dev`).

- Job submission
  
  > ***NOTE:** You should be in a terminal session on `townsend-submit` or one of the other submit servers.*
  
  1. **Navigate into the `hypro-chtc` repo directory:**
     
     ```shell
     cd ~/hypro-chtc
     ```
  
  2. **Submit a batch of jobs from a job list text file** (this is how we will usually submit jobs):
     
     ```shell
     condor_submit source/hypro/hypro.sub joblist=$STAGING/joblist/${PROJECT}_JobList.txt
     ```
     
     > **NOTES:** The `joblist` argument needs to be a complete, valid filepath, either relative or absolute. If the path begins with `/`, it will be interpreted relative to the filesystem root (i.e. absolute path); otherwise, it will be interpreted **relative to the working directory** (directory from which `condor_submit` is run).
     
     **Or, submit a single job** from a job list string (can be useful for testing):
     
     ```shell
     condor_submit source/hypro/hypro.sub joblist="(HARS, 20240610, 01, 62GB, 19GB)"
     ```
     
     - Optional command-line arguments:
       - Sometimes we may choose to specify `project`
         - *Primarily used to control which config file is selected (see below).*
       - For non-north-up images, specify `rotation`
         - *The rotation angle should be given in **units of degrees**, **CCW positive**.*
  
  3. **Monitor job status using `status` command.**
     
     - Job identifiers
       - Each job has a job ID & a cluster (batch) ID.
       - Jobs queued from the same `condor_submit` call will have the same cluster ID.
       - The full job identifier is given first by the cluster ID, then the job ID, separated by a period, i.e. `${cluster_id}.${job_id}`
         - `162573` will match all jobs in cluster 162573.
         - `162573.001` and `162573.1` will match job 1 within cluster 162573.
     - Job status under `@` column:
       - `I`: idle
       - `R`: running
       - `H`: held

  4. **Watch for jobs to be held or removed from the queue.**
     
     - If any jobs are held, you'll need to diagnose the error before resubmitting.
       
       - Use `condor_q` to determine why the job was held:
         
         ```shell
         condor_q $job_id -af HoldReason
         ```
         
         where `$job_id` is a sequence of one or more valid identifiers, separated by space, each of which could be either the full job ID, or just the batch/cluster ID (which will give info for all jobs in the batch).
         
         > ***NOTE:** If querying for multiple jobs, it is valuable to use `-af:j` , which prefixes each line of the output with the corresponding job ID.*
       
       - **Usually the problem is that we did not request sufficient disk or memory.**
       
       - Use the `boost` utility to amend disk & memory requests & resubmit jobs:
         
         ```shell
         # Source the `boost` function from Bash utilities
         . utils/htcondor.sh
         # Boost the disk & memory requests for matching jobs
         boost $job_id $disk_factor $memory_factor
         ```
         
         where `$disk_factor` and `$memory_factor` are scaling factors to be multiplied by the original disk & memory resource requests, respectively. For example, to boost the requested memory by 20% while leaving the disk request unchanged, you can run
         
         ```shell
         boost $job_id 1.0 1.2
         ```
         
         > **NOTES:** Currently there may be some bugs in the `boost` utility. To accomplish this manually,
         >
         > 1. Use `condor_q $job_id -af HoldReason` to determine whether it is the disk or memory request that needs to be increased (or both).
         >
         > 2. Check the current usage of the job using `condor_q` to query either the `DiskUsage` or `MemoryUsage` of the job:
         >
         >    ```shell
         >    condor_q $job_id -af DiskUsage
         >    ```
         >
         >    **Note that the reported units will be different for disk (MiB) vs. memory (KiB).**
         >
         > 3. Determine boosting factors for disk & memory. To leave either one unchanged, pass a value of `1` or `1.0`.
         >
         >    - Usually a 10–30% increase will be sufficient to get the job to complete successfully; often, you can just go for a boost factor of 1.2 (20% increase).
         >
         > 4. Use `condor_qedit` to update the resource requests by modifying either the `RequestDisk` or `RequestMemory` job attributes:
         >
         >    ```shell
         >    condor_qedit $job_id RequestDisk $disk_request
         >    ```
         >
         >    where `$disk_request` is the updated disk resource request, calculated by multiplying the original request by the boosting factor. Or, if this value is still less than the current disk usage of the job as reported by `condor_q`, instead multiply the current usage by the boot factor.
         >
         > 5. Release the job with `condor_release`:
         >
         >    ```shell
         >    condor_release $job_id
         >    ```
         >
         >    The job will return to the queue in an idle state & wait to be matched with a machine for job execution.
     
     - When a job is removed from the queue, it has finished — it could have completed successfully, or encountered an error.
       
       - Check whether there are `*_Processed.tar.gz` files in the output directory.
       - Sometimes the `.tar.gz` files exist, but are very small — e.g. 0–100 KB. This usually indicates a problem, i.e. the processing failed somehow, even if HTCondor thinks the job completed successfully.
     
     - When a job fails, ...
     
       1. Look in the `*.err` files in `~/logs` on `townsend-submit` (open with a text editor).
          - Look for error messages & stack traces, especially at the end of the log, as an indication of anything that may have gone wrong.
          - If the reflectance processing completed successfully, there should be a log statement near the end that says *"All flightlines processed!"*. Other errors could still occur after that, but these would most often indicate an issue with e.g. file paths, permissions or quotas on Staging.
     
     - Can use Python code to find failed jobs (`find_failed_jobs.py`) by comparing existing `*.err` logs against existing `*_Processed.tar.gz` files.
       
       - *It's a crude solution, but will work for most cases.*
  
  5. **Resubmit failed jobs as needed until all jobs are complete.**
  
  6. **Copy processed data back to Farnsworth.**
  
     - Processed data from CHTC jobs is written to `$STAGING/data/processed` as `*_Processed.tar.gz`
     - Copy to `$FARNSWORTH/data/processed/airborne` on Farnsworth drive
       - Create directory `Project/year` folders
       - Create nested `refl` folder (all processed data should be copied to here)
       - **NOTE:** Preserve session directory structure when copying back from Staging
  
  7. **Extract processed data archives.**
     
     - Open `refl` directory & right-click to launch Git Bash terminal
       
       ```shell
       # NOTE: There shouldn't be anything else in the directory, just subdirectories & .TAR.GZ files
       for d in *; do
         echo ">>> $d"
         cd "$d"
         for f in *_Processed.tar.gz; do
           echo "$f"
           tar -xzf "$f" && rm "$f"
         done
       done
       ```



## After Reflectance Processing

### Verify all images have processed successfully

Use the **"Inventory Processed Outputs**" Jupyter notebook to verify that all jobs have been completed & outputs have been copied back.

- Input parameters are the file paths to the `refl` directory & the job list file.
- Will create a `Processed.csv` table that will help you find any jobs that may not have finished successfully yet



### Build QGIS map project

We can build a map project to facilitate easy inspection of the images.

**To build a map project from the Python console in QGIS:**

1. Open Command Prompt

2. Activate Conda environment
   
   ```shell
   conda activate cole
   ```

3. Launch QGIS from command line
   
   ```shell
   qgis
   ```

4. Open Python console in QGIS
   
   - Basically, run commands from `script/demos/pyqgis/load_images.py` (in the `enspec` repo)
     - `image_directory` should be the path to the `refl` directory
     - `label` is somewhat arbitrary, but would generally be the project name

5. **Save the QGIS project** in the project directory.



### Inspect images

As a final check, we should visually assess the processed imagery to see that it looks reasonable, e.g.

- Reflectance values should generally range from 0 – 10,000 (0 – 100%).
- Vegetation pixels should have characteristic features, i.e. green peak, red edge, NIR plateau, IR water absorption bands.
- Vegetation pixels peak around 40 – 70% reflectance in the NIR.
- Image features should line up well with basemap imagery or other spatial data (offset less than 2 – 3 pixels, ideally).
- Hopefully, overlapping flightlines will also show good alignment.



## BRDF Corrections

### Notes & Background

BRDF corrections will be applied to the processed reflectance images (i.e. run HyPro on CHTC first, then apply BRDF corrections on the reflectance outputs).



#### File Structure

The reflectance images will remain on Farnsworth when running the BRDF corrections. Because Krusty has a direct mount (at `/mnt/farnsworth`), the imagery can be directly read from & written to the processed data directory on Farnsworth (`data/processed/airborne`).

Prior to running the BRDF workflow, the processed reflectance files should be structured like

```shell
└── $PROJECT
    └── *_LinesDict.json
    └── refl
        └── $SESSION
            └── $FLIGHTLINE
```

**Or**, if the `--grouped-by-site` option is passed, an additional directory level will be added above the session level to organized files by site:

```shell
└── $PROJECT
    └── *_LinesDict.json
    └── refl
        └── $SITE (*)
            └── $SESSION
                └── $FLIGHTLINE
```



### Determine good images for BRDF fitting

1. Generate a template lines dictionary file.
   
   - Use `generate_lines_dict` function from `enspec.processing.utilities.lines_dict`
     
     - Pass path to `refl` directory as positional argument
       
     ```python
     from enspec.processing.utilities.lines_dict import generate_lines_dict
     
     generate_lines_dict('/data/processed/airborne/Hancock_ARS/2024/refl')
     ```
     
     **NOTE:** This assumes all images are suitable to use for fitting BRDF. We want to manually remove the numbers of any bad images/flightlines.

2. **Open QGIS project to inspect imagery.**

3. **Toggle through image layers one by one** to verify they appear OK
   
   - Primarily, bad images will be those with **> 10% cloud shadow or cloud pixels**.
   - *If you're not sure if an image is good or bad, ask Brendan.*
   - **NOTE:** Bad images will be withheld during **fitting** of the BRDF correction, but the correction will be **applied** to all of the images.

4. **Bad images** (i.e. > 10% cloud shadow) **should be removed** from the JSON file.
   1. Open the JSON in a text editor.
   2. Find the corresponding session in the JSON structure (look for e.g. `"LOEW_20230621": [...],`).
   3. Find the image number in the associated list & remove it. (Make sure to remove the comma as well!)

5. **Save modified lines dictionary.**

6. Place lines dictionary JSON in the data directory (e.g. `/$PROJECT`).



### Run BRDF corrections

1. Log in to Krusty (`krusty.russell.wisc.edu`)

2. Check that the processed reflectance images are in place on Farnsworth (proper directory structure, etc.)
   
   - Need to extract `*_Processed.tar.gz` first
   - Need to place site/session folders inside `refl` directory (within data directory)
   - Need lines dictionary JSON file in place

3. Activate Conda environment
  
   ```shell
   conda activate xeno
   ```

4. Run BRDF processing
  
   - Navigate to `enspec` repo first
     
     ```shell
     cd git/enspec
     ```
     
   - The simplest way to call BRDF processing is
     
     ```shell
     python brdf_batch_process.py -d $data_directory --invert-mask
     ```
     
   - Optionally, specify the lines dictionary file to use by appending to the command above
     
      ```shell
      -f path/to/$PROJECT/$PROJECT_LinesDict.json
      ```
     
     By default, (no `-f` flag) the script looks for a file with the same basename as the data directory, e.g. `HARS_2024_LinesDict.json`
   
   - Use the `--grouped-by-site` option when the project has multiple sites & the session directories are nested inside of the site directories (this adds an extra level of organization in the directory structure).
   
   - **Use the `--invert-mask` option to invert the data mask.** This is used when the input data mask is generated with the opposite interpretation as used by HyTools, as is currently the case for HyPro.
     
     ```shell
     python src/enspec/processing/workflows/brdf_batch_process.py -d $data_directory --invert-mask
     ```



## Appendices

### Servers

**EnSpec Servers**

###### Filesystem Servers (Storage)

- `farnsworth.russell.wisc.edu`

###### Workstation Servers (Processing)

- `krusty.russell.wisc.edu`
- `uwspex.russell.wisc.edu`

**CHTC Servers**

###### Transfer Server

- `transfer.chtc.wisc.edu`

###### Submit Servers

- `townsend-submit.chtc.wisc.edu`
- `ap2001.chtc.wisc.edu`
- `ap2002.chtc.wisc.edu`



### Setting up CHTC Workspace

> ***NOTE:** The instructions in this section only need to be followed once to set up your workspace on a particular submit server.*

> ***NOTE:** Before running these commands, first log in to `townsend-submit.chtc.wisc.edu` (or your submit server of choice).*

#### Setting up your user space on the submit server

1. **Clone the [`hypro-chtc` repository](https://github.com/enspec/hypro-chtc)** into your user home on `townsend-submit` (or other submit server).

   ```shell
   git clone http://github.com/enspec/hypro-chtc
   git fetch --all
   ```

   In most cases we will be working on the `dev` branch,

   ```shell
   git checkout dev
   ```

   but features on this branch may be unstable (i.e. prone to errors) during active development. Works in progress should be prototyped on `dev` or another branch, cleaned up by rebasing, tested, & merged into the `main` branch *via* pull request.

   This repo provides all the source files needed to run HyPro processing on CHTC, including

   - Submit file
   - Job executable
   - Bash utilities
   - HTCondor formatting templates

2. **Set up shell aliases** (i.e. `status` command).

   It can be helpful to define aliases for frequently-used commands.

   Aliases can be defined in `~/.bashrc` & will be renewed at the start of each shell session.

   I like to make a separate file to keep aliases separate from everything else in `.bashrc`. Make a `~/.bash_aliases` file:

   ```bash
   vim .bash_aliases
   ```

   Press `i` to switch to "insert" mode. Then, write alias statements to the file, one per line:

   ```
   alias status='condor_q -pr ~/htcondor/usage.cpf'
   ```

   Save & close (escape, then `:wq` followed by enter). Then edit (or create) `~/.bashrc`:

   ```bash
   vi .bashrc
   ```

   Add the following to load aliases from the `.bash_aliases` file:

   ```bash
   if [ -f ~/.bash_aliases ]; then
     . ~/.bash_aliases;
   fi
   ```



#### Checking usage quotas

User & group allocations on CHTC Staging have associated **quotas** — limits on both the overall amount of data as well as the total number of files that can be stored. Check quotas on Staging allocations you have access to using `get_quotas`, e.g.

```shell
get_quotas $STAGING
```
