---
title: "HyPro CHTC Documentation"
author:
- Brendan Heberlein^[UW--Madison, bheberlein@wisc.edu]
date: '2024-03-08'
output:
  html_document: default
---

# Getting Started With Image Processing on CHTC

## References
- [CHTC Website](https://chtc.cs.wisc.edu)
- [HTCondor Documentation](https://htcondor.readthedocs.io/en/latest/)

## About CHTC

The Center for High-Throughput Computing (CHTC) uses a task scheduling & management system called **HTCondor** to facilitate distributed high-throughput and high-performance computing.

Programs are submitted to HTCondor as jobs, which are matched with candidates from among a pool of available machines (computers) meeting the job's requirements. When a match is found, job instructions (code) and inputs (data) are passed to this machine to run. HTCondor tracks the job and its requirements throughout its life cycle.

In order to use CHTC services, you will need to request an account.


## Requesting a CHTC Account

To request an account with CHTC, fill out the [request form](https://chtc.cs.wisc.edu/form). You will need to provide some detailed information about how you expect to use CHTC. You will have to meet with CHTC staff to discuss this further to get approved, so discuss these details with your supervisor ahead of time if you are unsure about anything.

In your request, be sure to ask for access to Staging (CHTC large data temporary storage). Also, request to have your user added to the `townsend_hyspex` user group.


## CHTC Filesystem

%% TODO

**Staging**


## CHTC Servers

%% TODO

- `transfer.chtc.wisc.edu`
- `townsend-submit.chtc.wisc.edu`

<hr>

%% TODO

Job submission should be done through our designated **submit server**, `townsend-submit.chtc.wisc.edu`.

Large data inputs are stored temporarily or *staged* on CHTC's Staging server. Transfer of inputs and outputs to and from Staging should be done via the **transfer server**, `transfer.chtc.wisc.edu`. Currently, the recommended way to do this is using `smbclient`, although for smaller files it may be convenient to use e.g. WinSCP. Note that transfer of files via WinSCP is generally much slower.

<hr>



## Setting up on CHTC

%% TODO

The instructions in this section only need to be followed once, after you 

- **Source files**
  - Job instructions
    - Submit file
    - Executable
  - Bash utilities
  - HTCondor usage.cpf

- "Packages"
  - HyPro (Python code for reflectance processing)
  - Conda (Python environment with dependencies installed)

- Support files
  - Job lists

- Other
  - Config files

### Set aliases in `.bashrc`

> **NOTE:** Before running these commands, first log in to `townsend-submit.chtc.wisc.edu`.

It can be helpful to define aliases for frequently-used commands.

Aliases can be defined in `~/.bashrc` & will be renewed at the start of each shell session.

I like to make a separate file to keep aliases separate from everything else in `.bashrc`. Make a `~/.bash_aliases` file:

```bash
vi .bash_aliases
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


## Basics of HTCondor

...


## Managing processing jobs on CHTC

### Submitting Jobs

#### Submit Files

##### Submit variables

- [Variables in the Submit Description File](https://htcondor.readthedocs.io/en/latest/users-manual/submitting-a-job.html#variables-in-the-submit-description-file)


##### Including submit commands from other files

In your submit file, you can use the `include` command to incorporate the contents of another file into your submit description:

```
include : ./s3-credentials.sub
```

Alternatively, follow the statement by a pipe/bar character (`|`) to execute the indicated file & incorporate its output into your submit description:

```
include : ./list-input-files.sh |
```



### Environment variables

You can pass environment variables to jobs using the `environment` command in your submit file:

```
# Pass condor job ID as an environment variable
environment = CONDOR_JOB_ID=$(Cluster).$(Process)
```



### Conditional statements

you can use `if... else... endif`

```
if $(condition)
   ...
else
	 ...
endif
```



`elif` is also viable.



See: https://htcondor.readthedocs.io/en/latest/users-manual/submitting-a-job.html#using-conditionals-in-the-submit-description-file



#### Example: *Check if variable is defined & modify arguments accordingly*

```
if defined project
   arguments=$(arguments) $(project)
endif
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


or within a loop:

```bash
# SITE=BASS
# YEAR=20180629
# LINES="01 02 03"
# 
# TODO: Need to figure out how to loop through line numbers along with disk, memory
#
# for LINE in $LINES; do
#   condor_submit $SUBMIT joblist="($SITE, $DATE, $LINE, ???)"
# done
```





```bash
function unpack {
  echo ${f%.tar.gz}
  tar -xzf $f && rm $f
}
```




### 



### Pass submit variables directly to `condor_submit`

It is possible to use variables inside your submit file which are not defined in the submit file, but rather are passed in via `condor_submit`:

```
condor_submit my_job.sub disk=100GB memory=30GB
```





## Job management & troubleshooting

##### References

- [HTCondor Job ClassAd Attributes](https://htcondor.readthedocs.io/en/latest/classad-attributes/job-classad-attributes.html?highlight=JobStatus)
- [CHTC - Learning About Your Jobs Using `condor_q`](https://chtc.cs.wisc.edu/uw-research-computing/condor_q)

##### Investigating held jobs

`condor_q --hold` will list held jobs & the reason for being held.

For more-fine-grained control over the information displayed, instead provide a constraint to `condor_q`:

`condor_q -constraint "JobStatus == 5" -af ClusterId ProcId HoldReason`

Note that `JobStatus == 5` will match jobs that are currently held. See the [ClassAd attributes reference](https://htcondor.readthedocs.io/en/latest/classad-attributes/job-classad-attributes.html?highlight=JobStatus).



Multiple constraints can be chained together. The following will find jobs that are neither running nor held:

`condor_q -constraint "JobStatus != 5" -constraint "JobStatus != 2" -af ClusterId ProcId`

##### Investigate jobs in-depth

`condor_q -analyze`

Query specific job attributes such as `ClusterId`, `ProcId`, `RequestMemory`, `RequestDisk`, `DiskUsage`, `MemoryUsage`, ...



Use `-af:j` to list the job ID first:

````
-bash-4.2$ condor_q -af:j RequestMemory
89980.3 392192
89980.4 320512
89980.6 305152
````



You can combine with other flags, for example:

```shell
condor_q --held -af:j HoldReason
```



See the [`condor_q` man page](https://htcondor.readthedocs.io/en/latest/man-pages/condor_q.html) for more information.






##### Rescuing a job that exceeded its requested disk or memory

It may be helpful to check how much memory the job requested vs. how much it used before it was held with `condor_q xxxxx.y -af RequestMemory MemoryUsage`  (`xxxxx.y` is the job ID, and the output is in MiB):

```
-bash-4.2$ condor_q 80293.0 -af RequestMemory MemoryUsage
32768 34180
```

You can then set `RequestMemory` to an appropriate value using `condor_qedit xxxxx.y RequestMemory X`  (where `X` is the new requested size, in MiB):

```
-bash-4.2$ condor_qedit 80293.0 RequestMemory 40000
Set attribute "RequestMemory" for 1 matching jobs.
-bash-4.2$ condor_q 80293.0 -af RequestMemory
40000
```

Note you can pass multiple job identifiers to `condor_qedit`, but you must specify both the cluster & process ID:

```
condor_qedit 88980.1 88980.15 88980.16 RequestMemory 45000
```

If you specify only the cluster ID, the attribute will be set for all jobs in the cluster.

```
-bash-4.2$ condor_qedit 80293 RequestMemory 40000
```



Then you can release the job, hopefully to complete successfully: `condor_release xxxxx.y`, or release all jobs in a cluster with `condor_release xxxxx`:

```
-bash-4.2$ condor_release 80923
All jobs in cluster 80293 have been released
```

The above examples use `RequestMemory` and `MemoryUsage`, but you can run the same commands substituting with `RequestDisk` and `DiskUsage`.

*NOTE: Confusingly, disk space is reported in **KiB**, while memory is reported in **MiB**.*

If you need to raise either the disk or memory for a job, it might be a good idea to increase both



```
boost() {
  # Resolve boosting factor (resource requests will be scaled by this amount)
  [[ -z "${BOOST_FACTOR+x}" ]] && BOOST_FACTOR=1.6
  # Select resources to augment
  if [[ -n "${2+x}" ]]; then
    local TARGET=($2)
  else
    local TARGET=('Disk' 'Memory')
  fi
  # Augment resource requests
  for tgt in ${TARGET[@]}; do
    local INITIAL=$(condor_q $1 -af Request${TARGET})
    local USAGE=$(condor_q $1 -af ${TARGET}Usage)
    local REQUEST=$(bc <<< "$BOOST_FACTOR * $USAGE")
    echo "Updating ${tgt,,} request for job $1:"
    echo "   > Initial: $INITIAL"
    echo "   > Usage: $USAGE"
    echo "   > Request: $REQUEST"
    condor_qedit $1 Request${TARGET} $REQUEST;
  done
  # Release the job
  condor_release $1
}
```








