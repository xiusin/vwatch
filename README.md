# VWatch - A hot-reloading tool developed with V Language

VWatch is a tool for **hot-reloading** that allows developers to restructure and rerun projects when files are changed or repository versions are updated, using the configuration file `vwatch.toml` to configure relevant parameters. It is mainly used for real-time debugging during the development process.

# Features
- Automatic project restructuring and recompiling upon file changes or repository updates
- Customizable configurations through vwatch.toml file
- Easy integration with V Language projects
- No dependencies, concise and compact.

# Getting Started

## Installation
1. Clone this repository
2. Build the project using `v -prod -o vwatch vwatch.v`
3. Move the vwatch executable to your desired location

# Usage
1. Navigate to your project directory
2. Create a vwatch.toml configuration file and configure it as desired
3. Run the vwatch executable
4. Make changes to your project files and see the changes reflected in real-time
# Configuration
The `vwatch.toml` file can be used to configure various parameters such as the project path, file extensions to watch, and any necessary commands to run upon file changes or repository updates. See the example below:

```toml
# Limit the number of files that can be watched
max_file_cnt = 3000

# The file extensions to be watched for changes
watch_extensions = [".go", ".v"]

# The directory to be watched for changes (default is current directory)
watch_dir = ""

# The command to be executed when a change is detected
build_on_change = ["go", "build"]

# The name of the executable to be built (default is auto-generated)
build_bin_name = ""

# The pattern of files or directories to be ignored
ignores_pattern = ""

# Whether to pull updates from Git repository
git_pull = false

# Whether to print startup information
print_startup_info = true
```

# Demo

```
$ v run vwatch.v                                                                                                                                                                ✹
[INFO] start watching... 
[INFO] Register /Users/xiusin/projects/src/github.com/xiusin/vwatch/vwatch.v
[INFO] Register /Users/xiusin/projects/src/github.com/xiusin/vwatch/main.go
[INFO] Content is updated and rebuilt...
[INFO] build use time: 218.577ms
^C[INFO] exit sub process closed.
double string.free() detected
[INFO]👋🏻 ByeBye...
```

# License
This project is licensed under the MIT License - see the LICENSE file for details.

# Contributing
Contributions are welcome! Please feel free to submit pull requests or open issues if you encounter any problems.
