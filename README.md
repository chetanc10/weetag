# Cscope/Ctags DB Helpers
This is basically a container of 1 mise toml and a shell script supporting different OS's which are added to PATH at a global level.

retag script is a wrapper for cscope and ctags with disk and time friendly improvements for C-language based projects like linux-kernel.

## Prerequisites
Must have - System must have already installed https://github.com/jdx/mise tool which is the basis of using weetag

Good to have - Users can pre-install wee tool from https://github.com/chetanc10/wee that works along with mise to help users setup and maintain many wee enabled repos.

# Installation
## With mise
The repo can be cloned or it can downloaded or a set of files can be downloaded and copied to relevant bin path that is already added to PATH.

## With wee
For systems already having wee installed:
1. Install weetag using wee: ```wee install https://github.com/chetanc10/weetag```
2. ```cd ~/.config/mise/ ; wee add chetanc10/weetag ; cd -``` => installs the toml and OS specific scripts globally
3. ```cd ~/.config/mise/ ; wee remove chetanc10/weetag ; cd -``` => removes the toml and OS specific scripts globally

# Features
- Directory exclusion:  
  Specific directories could be excluded using -x option saving time and disk-space.
- Kernel DB build:  
  Developers usually work on a single platform at a time with a kernel-clone, such cases don't need to include other platform code for scoping code. Using -k, users could select specific platform.  
  Also, retag automatically tries to remove some unwanted folders like Documentation, scripts, etc. However, user is prompted to choose if removing such folders from DB build.
  Additional to -k, user can also exclude other directories using -x
- Verbose DB build-time and size logs:
  -v option enables verbose logs to display total DB build-time and size, helps compare different retag runs with -k/-x//-xi on a source directory
- detag:
  An alias that removes all cscope, ctags and retag files from current directory
- Reduced runtime cluttered view:
  -k/-x/-xi can reduce redefined symbols in DB, thus reducing runtime cluttered view of redefined symbols.

# Examples
```retag```
- If ```.retag.files``` file is present and builds csccope/ctags DB using the files listed in ```.retag.files```
- Otherwise, it effectively does ```cscope -Rb &; ctags -R```

```retag -v```  
- Same as above, but additionally enables verbose mode to show the DB size and DB generation time

```retag -k arm64 -x drivers/gpu sound```  
- Excludes all arch/* subfolders except arch/arm64, excludes folders drivers/gpu and sound, creates fresh ```.retag.files``` and then creates cscope/ctags DB using the freshly generated ```.retag.files```  
- After this command, further retag invocations automatically detect ```.retag.files``` (unless detag deletes the file) to build DB, so user needs to give this retag with folder exclusion arguments just once per source until a ```detag```.

```retag -x drivers/gpu sound -xi arch/arm64```  
- Effectively same as the above.
- '-k' is provided to draw attention to the way retag could be used to simplify cscope/ctags build using retag.
