# The Basics

## References

- [About Filesystems](https://en.wikipedia.org/wiki/File_system)
- [List of Filesystems](https://en.wikipedia.org/wiki/List_of_file_systems)

## Key Things to Know

- A filepath that starts with `/` is an **absolute path**, interpreted relative to the **filesystem root**.
- A filepath that **does NOT** start with `/` is a **relative path**, interpreted relative to the **current working directory**.

## Files & File Extensions

### File Extensions

A **file extension** is a suffix added to a file's name, typically after a dot (`.`), that indicates its type or function.

| Example        | Extension         | Type                       |
|----------------|-------------------|----------------------------|
| `document.txt` | `.txt`            | plain text file            |
| `document.doc` | `.doc` or `.docx` | Microsoft Word document    |
| `document.pdf` | `.pdf`            | Adobe PDF                  |
| `photo.jpg`    | `.jpg` or `.jpeg` | JPEG compressed image file |
| `photo.jpg`    | `.png`            | PNG lossless image file    |
| `audio.mp3`    | `.mp3`            | MP3 audio file             |
| `script.sh`    | `.sh`             | shell script               |
| `script.py`    | `.py`             | Python script              |


Some file types use compound extensions, with multiple components delimited by dots.

While extensions are helpful, they are not always required or enforced. In fact, they are only symbolic hints at the type of data a file might contain, or how you might want to interact with a file, 

## Filesystems & Filepaths

A [**filesystem**](https://en.wikipedia.org/wiki/File_system) organizes how files and directories (also called folders) are stored and accessed on a computer. Most modern filesystems follow a **hierarchical tree model**:
- **Files** can contain data.
- **Directories** can contain files & other directories.
- The entire filesystem is organized within a single **root directory**.

### The Filesystem Tree Concept

The filesystem can be visualized as a tree structure with the filesystem root directory at its base, and files at the tips of its branches. For example:
```plaintext
.
└── path/
    └── to/
        └── my/
            └── file.ext
```
Here, a 

> **HOW TO INTERPRET THE TREE GRAPH:** The 

The path to `file.ext` is:
```plaintext
/path/to/my/file.ext
```

Every file or directory can be uniquely identified by its path, which starts at the root and lists all its parent directories, separated by slashes (`/`).

---

### Filepath Conventions

#### UNIX Systems
- Use **forward slashes** (`/`) to separate directories.
- The root directory is specified as `/`.
- Example:
  ```plaintext
  /path/to/my/file.ext
  ```

#### Windows Systems
- Use **backward slashes** (`\`) to separate directories.
- The filesystem root is specified by a **drive letter** (e.g., `C:\`).
- Example:
  ```plaintext
  C:\path\to\my\file.ext
  ```

> **Note:** The backslash (`\`) is also an **escape character** in many systems (e.g., Python or UNIX shells). This can lead to errors if a Windows-style path is used without adjustments.

---


## Local, Nonlocal & Distributed Filesystems

- A **local filesystem** is stored on a computer's internal storage.
- A **network filesystem** accesses files stored on another machine over a network. The remote files appear as part of the local filesystem but have different access paths or prefixes depending on the system used to connect.
- A **distributed filesystem** spreads data across multiple machines, often used in cloud environments.

> **Tip:** When accessing network files, check the path’s prefix (e.g., `/mnt/network_drive/` vs. `\\server\share\`) to ensure it aligns with your system.

---

## Absolute & Relative Paths

### Absolute Paths
An **absolute path** specifies the location of a file starting from the root of the filesystem.
- UNIX example: `/path/to/file.txt`
- Windows example: `C:\path\to\file.txt`

### Relative Paths
A **relative path** specifies the location of a file relative to the current working directory.
- Example: If the current directory is `/path/to/my`, the relative path `file.txt` points to `/path/to/my/file.txt`.

### Special Characters in Paths
- `~`: Refers to your home directory (e.g., `/home/user` on Linux).
- `./`: Refers to the current directory.
- `../`: Refers to the parent of the current directory.

- Example: If the current directory is `/path/to/my`, the relative path `../other/file.txt` points to `/path/to/other/file.txt`.

---

## Common Stumbling Blocks

1. **Path Confusion Across Systems**:
   - UNIX uses `/`, Windows uses `\`.
   - Networked files may have different prefixes (e.g., `/mnt/network_drive/` on Linux vs. `\\server\share\` on Windows).

2. **Relative vs. Absolute Paths**:
   - Leading slashes (`/`) or drive letters (`C:\`) indicate absolute paths.
   - Missing these means the path is relative.

3. **Escape Characters on Windows Paths**:
   - In scripts, use double backslashes (`C:\\path\\to\\file.txt`) or raw strings (`r"C:\path\to\file.txt"`) to avoid errors.

By mastering these basics, you’ll be well-equipped to navigate and manage files on any system!
