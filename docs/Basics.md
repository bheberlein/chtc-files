# The Basics

## Key Things to Know

- A filepath that starts with `/` is an **absolute path**. It will be interpreted relative to the **filesystem root**.
- A filepath that **does NOT** start with `/` is a **relative filepath**. It will be interpreted relative to the **current working directory**.

## Filesystems & Filepaths

A [**filesystem**](https://en.wikipedia.org/wiki/File_system) is a computing framework for managing file storage. Various types of filesystems exist, but the most common & widely used filesystems (e.g. FAT, NTFS, APFS) employ a similar conceptual scheme that describes the total filesystem as a **hierarchical tree**.

Within the hierachical filesystem concept, **files** can placed inside **directories** (or folders), which can in turn be placed inside other directories. In this way, files and folders can be organized into a tree.

Every file & every directory has a **parent**, the directory within which it is located. If you traverse from this directory to its parent, and then to its parent, and so on up the tree, you will eventually arrive at the **root directory** within which all files and folders are contained.

### The filesystem tree concept

(Concisely explain how the file/directory scheme leads to a tree model. Each node is either a file or a directory. Each file or folder has a parent. All directories are contained within a single root directory. A file's **path** is composed of its own name and the names of all its ancestors in order. This construction, commonly called a **filepath**, uniquely identifies the file and locates it within the filesystem. For example,
```commandline
.               <--------------------- ROOT
└── path/           <------------┐
    └── to/            <---------+---- DIRECTORIES
        └── my/           <------┘
            └── file.ext      <------- FILE
```

is rendered as
```commandline
/path/to/my/file.ext
```
)

### Filepath conventions

#### UNIX Systems

In Linux & macOS, the filepath components (directories) are separated by a forward slash (`/`):
```commandline
/path/to/my/file.ext
```

Note that the root directory is specified as `/`.

### Windows Systems
In Windows, the filesystem root is specified by a drive letter (usu. `C:\` for the main internal drive), and components are separated by **backward slashes** (`\`):
```commandline
C:\path\to\my\file.ext
```

Note that the backslash functions as an [escape character](https://en.wikipedia.org/wiki/Escape_character) in UNIX systems and various other areas of computing (e.g. Python). This glaring incompatibility between the two types of systems is a source of significant frustration for people who interact with both.

### File extensions

...

Strictly speaking, the extension is just part of the filename, and doesn't actually _do_ anything; it's purpose is just to signify what wind of data the file contains, and how it should be read.


## Local, Nonlocal & Distributed Filesystems

A **local filesystem** (LFS) is stored on a machine's internal hard drive. The local filesystem is the filesystem most users are accustomed to interacting with. Your computer has its own filesystem, for example, which includes all the files & folders on your machine.

A **nonlocal** or **network filesystem** is a different machine's local filesystem (i.e. an LFS on a different computer which is connected to yours by a network). The filesystem is exposed over the network so that other machines can connect to it and view its files as if they were stored on their own local filesystem. Really, though, they are stored on the _remote_ machine's local filesystem.

A **distributed filesystem** (DFS) actually distributes file storage across multiple machines. There are many different DFS architectures in use. These are generally newer and more complex systems developed for distributed & cloud computing.

> **NOTE:**
> Distributed filesystems may also be referred to as a **network filesystem**, but are not to be confused with network fileystems (nonlocal filesystems) of the sort described above.



## Absolute & Relative Paths

**Absolute filpaths**