# Getting Started With Image Processing on CHTC



## References

- [CHTC Website](https://chtc.cs.wisc.edu)
- [CHTC Guides](https://chtc.cs.wisc.edu/uw-research-computing/guides.html)
- [HTCondor Documentation](https://htcondor.readthedocs.io/en/latest/)



- [CHTC Status](https://status.chtc.wisc.edu)



## About CHTC

The Center for High-Throughput Computing (CHTC) uses a task scheduling & management system called **HTCondor** to facilitate distributed high-throughput and high-performance computing.

Programs are submitted to HTCondor as jobs, which are matched with candidates from among a pool of available machines (computers) meeting the job's requirements. When a match is found, job instructions (code) and inputs (data) are passed to this machine to run. HTCondor tracks the job and its requirements throughout its life cycle.

In order to use CHTC services, you will need to request an account.



## Requesting a CHTC Account

To request an account with CHTC, fill out the [request form](https://chtc.cs.wisc.edu/form). You will need to provide some detailed information about how you expect to use CHTC. You will have to meet with CHTC staff to discuss this further to get approved, so discuss these details with your supervisor ahead of time if you are unsure about anything.

In your request, be sure to ask for access to Staging (CHTC large data temporary storage). Also, request to have your user added to the `townsend_airborne` user group.



## Overview of CHTC

As a distributed computing system, the general idea of CHTC is that processing tasks, usually called **jobs**, are **submitted** to a **task manager** (HTCondor) which then delegates & distributes the tasks among a **worker pool** (i.e. a number of remote machines within the CHTC network) for execution.

Large data inputs are stored temporarily or *staged* on CHTC's **Staging** server to make them accessible to machines in the worker pool. Transfer of inputs and outputs to and from Staging should be done via the **transfer server**, `transfer.chtc.wisc.edu`.

### Staging

Staging is the primary filesystem server for making large files available to machines in the worker pool. Files should generally be copied from Staging to the worker node for processing.

Staging is a [CephFS](https://docs.ceph.com/en/reef/cephfs/) volume, available via a mount point at `/staging` (which links to `/mnt/cephfs/kernel/staging`) from the Transfer server, as well as the various submit servers.

Users & user groups wishing to use Staging must request an allocation. A Staging allocation is specified by **quota**, which sets limits on the **total amount of data** as well as the **total number of files** allowed. Attempts to write data beyond the set quota will be encounter a permission error.

### Transfer

The Transfer server (`transfer.chtc.wisc.edu`) is a dedicated server for moving large files (or large numbers of files) to & from Staging. **Avoid using the submit server for managing large data transfers** — especially the general-use submit servers `ap2001` & `ap2002`.




## Managing processing jobs on CHTC

### Submitting Jobs

> ***NOTE:** Here, we will deal primarily with jobs in the "vanilla" universe. Other job submission frameworks exist, including interactive jobs & jobs in the Docker universe.*

In general, job submission requires two things

- A **submit file**, which defines the job to be run & is parsed by the task manager to determine e.g. what the job's requirements are; and
- A **job executable**, which is a script to be run that implements the job's processing logic. Often this is a Shell (`*.sh`) or Python (`*.py`) script.

#### Submit Files

The submit file is a simple text file (often with `.sub` extension) which defines the jobs to be run & dictates how the jobs should be queued by the task manager.

The submit file provides detailed information about the job & its requirements. It includes everything HTCondor needs to know in order to match the job with candidate machines capable of running it, and to start the job on a remote worker node. For example, the submit file can be used to

- Impose constraints on the worker machine *(e.g. operating system, number of CPU cores, available disk & memory)*
- Indicate the job executable file
- Specify how any arguments should be passed to the executable
- Specify how jobs or batches of jobs should be queued *(e.g. from a text file containing parameters for individual jobs on each line)*
- Configure HTCondor's automatic file transfer mechanism
- Configure input & output logs

Additionally, within the submit file you can

- Define & use variables
- Implement simple logic

##### Submit variables

- [Variables in the Submit Description File](https://htcondor.readthedocs.io/en/latest/users-manual/submitting-a-job.html#variables-in-the-submit-description-file)

##### Environment variables

You can pass environment variables to jobs using the `environment` command in your submit file:

```
# Pass condor job ID as an environment variable
environment = CONDOR_JOB_ID=$(Cluster).$(Process)
```

##### Conditional statements

You can use `if... else... endif` to implement conditional logic:

```
if $(condition)
   ...
else
	 ...
endif
```

Note that `elif` is also viable. [See the HTCondor documentation](https://htcondor.readthedocs.io/en/latest/users-manual/submitting-a-job.html#using-conditionals-in-the-submit-description-file) for more information.

###### Example: *Check if variable is defined & modify arguments accordingly*

```
if defined project
   arguments=$(arguments) $(project)
endif
```

##### Including submit commands from other files

In your submit file, you can use the `include` command to incorporate the contents of another file into your submit description:

```
include : ./s3-credentials.sub
```

Alternatively, follow the statement by a pipe/bar character (`|`) to execute the indicated file & incorporate its output into your submit description:

```
include : ./list-input-files.sh |
```



### Queue Statement

The `queue` statement is an essential part of the submit file which is responsible for initiating one or more tasks to be scheduled. 

#### Queueing from a file

Create a file, e.g. `joblist/BASS_2018_JobList.txt`, for each site. The contents of the file should provide job parameters for each flightline: 

```text
BASS, 20180629, 01, 47GB, 11GB
BASS, 20180629, 02, 59GB, 13GB
BASS, 20180629, 03, 57GB, 13GB
```

Then the jobs can be submitted as follows:

```bash
condor_submit source/hypro/HyProRotated.sub joblist="joblist/BASS_2018_JobList.txt"
```

This can be embedded in a loop over sites:

```bash
SITES="BASS CHER CLOV SYEN MKWO COLA BLUF"
YEAR=2018

SUBMIT=source/hypro/hypro.sub

for SITE in $SITES; do
  condor_submit $SUBMIT joblist="joblist/${SITE}_${YEAR}_JobList.txt"
done
```


#### Queueing from a string

A single job can easily be queued from a string:

```bash
condor_submit $SUBMIT joblist="(BASS, 20180629, 01, 50GB, 20GB)"
```



### Pass submit variables directly to `condor_submit`

It is possible to use variables inside your submit file which are not defined in the submit file, but rather are passed in via `condor_submit`:

```shell
condor_submit my_job.sub disk=100GB memory=30GB
```



## Job management & troubleshooting

##### References

- [HTCondor Job ClassAd Attributes](https://htcondor.readthedocs.io/en/latest/classad-attributes/job-classad-attributes.html?highlight=JobStatus)
- [CHTC - Learning About Your Jobs Using `condor_q`](https://chtc.cs.wisc.edu/uw-research-computing/condor_q)

##### Investigating held jobs

By itself, `condor_q --hold` (or `--held`) will list held jobs & the reason for being held.

For more-fine-grained control over the information displayed, instead provide a constraint to `condor_q`:

```shell
condor_q -constraint "JobStatus == 5" -af ClusterId ProcId HoldReason
```

Note that `JobStatus == 5` will match jobs that are currently held. See the [ClassAd attributes reference](https://htcondor.readthedocs.io/en/latest/classad-attributes/job-classad-attributes.html?highlight=JobStatus).

Multiple constraints can be chained together. The following will find jobs that are neither running nor held:

```shell
condor_q -constraint "JobStatus != 5" -constraint "JobStatus != 2" -af ClusterId ProcId
```

##### Investigate jobs in-depth

```shell
condor_q -analyze
```

Query specific job attributes such as `ClusterId`, `ProcId`, `RequestMemory`, `RequestDisk`, `DiskUsage`, `MemoryUsage`, and more.

Use `-af:j` to list the job ID first:

````shell
condor_q -af:j RequestMemory
````

> ```
> 89980.3 392192
> 89980.4 320512
> 89980.6 305152
> ```

You can combine with other flags, for example to list disk request & usage parameters for held jobs only:

```shell
condor_q --held -af:j DiskUsage RequestDisk
```

See the [`condor_q` man page](https://htcondor.readthedocs.io/en/latest/man-pages/condor_q.html) for more information.




##### Rescuing a job that exceeded its requested disk or memory

It may be helpful to check how much memory the job requested vs. how much it used before it was held with `condor_q xxxxx.y -af RequestMemory MemoryUsage`  (`xxxxx.y` is the job ID, and the output is in MiB):

```shell
condor_q 80293.0 -af RequestMemory MemoryUsage
```

> ```
> 32768 34180
> ```
>

You can then set `RequestMemory` to an appropriate value using `condor_qedit xxxxx.y RequestMemory X`  (where `X` is the new requested size, in MiB):

```shell
condor_qedit 80293.0 RequestMemory 40000
```

> ```
> Set attribute "RequestMemory" for 1 matching jobs.
> ```

```shell
condor_q 80293.0 -af RequestMemory
```

> ```
> 40000
> ```
>

Note you can pass multiple job identifiers to `condor_qedit`, but you must specify both the cluster & process ID:

```shell
condor_qedit 88980.1 88980.15 88980.16 RequestMemory 45000
```

If you specify only the cluster ID, the attribute will be set for all jobs in the cluster.

```shell
condor_qedit 80293 RequestMemory 40000
```

Then you can release the job, hopefully to complete successfully: `condor_release xxxxx.y`, or release all jobs in a cluster with `condor_release xxxxx`:

```shell
condor_release 80923
```

> ```
> All jobs in cluster 80293 have been released
> ```
>

The above examples use `RequestMemory` and `MemoryUsage`, but you can run the same commands substituting with `RequestDisk` and `DiskUsage`.

> ***NOTE:** Confusingly, disk space is reported in **KiB**, while memory is reported in **MiB**.*

If you need to raise either the disk or memory for a job, it might be a good idea to increase both.

