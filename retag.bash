#!/bin/bash

gKexcludes="Documentation samples scripts tools LICENSES"

gUsageString="
Build cscope and ctags database:
- abstracting advanced cscope/ctags usage 
- easing inclusion/exclusion of files/directories
Improves cscope/ctags performance:
- reduces disk space for cscope and ctags DB
- reduces DB build time 
- reduces symbol clutter since unwanted files are not parsed

Usage: $(basename $0) <Options>
Options:
    -h              - displays this help message & exits (discards other args)
    -v              - verbose output (print time taken & size of DB files)
    -x <directory>  - directory (list) to exclude from cscope/ctags database;
                      e.g. -x build bin x86 Documentation tools
    -xi <main/sub>  - include <sub> folder, exclude all other folders in <main>
    -k <platform>   - linux-kernel specific, allows skipping unwanted arch src
                     -k skips unwanted folders (smartly wrapping -x, -xi).
                      e.g. '-k arm64' => '-xi arch/arm64 -x $gKexcludes'

NOTES:
- After a run with -k/-x/-xi, lateral $0 runs without these uses previously
  created file-list to create DB. Invoke $0 with -k/-x/-xi for fresh list
- -xi can be given multiple times to for different folders or sub-folders
- -x with no arguments $0 excludes .git and also tries excluding '$gKexcludes'
- '$gKexcludes' are usually unwanted folders for kernel source cscope/ctags.
  But user is prompted to choose to include them. 

"

_usage () {
	printf "$gUsageString\n\n"
	exit $1
}

gVerbose=false
gExcludes=(".git")
gExclusiveIncludes=()
gKXI=""
gCscopeOpts="-Rb"
gCtagsOpts="-R"
gRetagFiles=".retag.files"
gFresh=false
t0=$SECONDS

echo2 ()
{
	echo "ERROR: ${@}" >/dev/stderr
}

AddExcludes ()
{
	local count=0
	local xtype="$1"; shift 1
	if [ "$xtype" == "x" ]; then
		for dir in "${@}"; do
			[ -z "$dir" ] && break
			[ ! -d "$dir" ] && echo2 "x Skip $dir, not a folder" && continue
			gExcludes+=("$dir")
			((count++))
		done
		return $count
	fi
	[ ! -d "$1" ] && echo2 "xi $1 folder not found!" && _usage -2
	[ "$(dirname $1)" == "." ] && echo2 "xi $1 not a sub-folder" && _usage -3 
	gExclusiveIncludes+=("$1")
	return 0
}

# Parse the options
while [[ $# -gt 0 ]]; do
	case $1 in
		-h) _usage 0 ;;
		-v) gVerbose=true; shift 1 ;;
		-x) shift 1; AddExcludes x "${@%%-*}"; shift $?; gFresh=true ;;
		-xi) AddExcludes xi "$2"; shift 2; gFresh=true ;;
		-k) gKXI="$2"; shift 2; gFresh=true ;;
		*) echo2 "Invalid argument: $1" && _usage -1 ;;
	esac
done

[ -d arch ] && (grep -q "Linux Kernel" COPYING 2>/dev/null) && ktag="-k"

if $gFresh; then
	rm -rf $gRetagFiles
	# Fresh build needed!
	if [ -n "$ktag" ]; then
		# Update excludes with default kernel-excludes list (gKexcludes)
		read -r -a gKexcludes <<< "$gKexcludes"
		echo "Excluding rarely visited kernel folders: "
		for ((i=0; i<${#gKexcludes[@]}; i++)); do echo "($i) ${gKexcludes[$i]}"; done
		read -p "Enter spaced index list to include folders or ENTER: " addBacks
		IFS=' ' read -ra arr <<< "$addBacks"
		for fidx in "${arr[@]}"; do
			if [[ $fidx -lt 0 ]] || [[ $fidx -ge ${#gKexcludes[@]} ]]; then
				echo2 "Invalid spaced index list: $addBacks" ; exit -4
			fi
			unset gKexcludes[$fidx]
		done
		gKexcludes=("${gKexcludes[@]}")
		gExcludes+=("${gKexcludes[@]}")
		[ -n "$gKXI" ] && AddExcludes xi "arch/$gKXI"
	fi

	# Setup find cmd to find c/h files recursively with required exclusions
	fopts=""
	for dir in "${gExcludes[@]}"; do
		[ -n "$fopts" ] && fopts="$fopts -o "
		fopts="$fopts -path './$dir/*'"
	done
	for eidir in "${gExclusiveIncludes[@]}"; do
		[ -n "$fopts" ] && fopts="$fopts -o "
		fopts="$fopts -path './$(dirname $eidir)/*' ! -path './$eidir' ! -path './$eidir/*'"
	done

	# Apply the above find cmd and generated file list to build retag DB
	fscope="/tmp/fscope-$(basename ${PWD})-$(date +%s%3N).sh"
	echo "find . \( ${fopts} \) -prune -o -type f -name \"*.[ch]\" -print > $gRetagFiles" > ${fscope}
	bash ${fscope} && rm -rf ${fscope}
fi

if [ -s $gRetagFiles ]; then
	gCscopeOpts="-Rb $ktag -i $gRetagFiles"
	gCtagsOpts="-L $gRetagFiles"
fi

cscope $gCscopeOpts & cscope_pid=$!
ctags $gCtagsOpts
wait $cscope_pid

if $gVerbose; then
	tdiff=$(($SECONDS-$t0))
	printf "\nDB build duration (mm:ss) : $(($tdiff/60)):$(($tdiff%60))\n"
	dbfiles=(tags cscope.out ncscope.out $gRetagFiles)
	dbsz=0
	for file in ${dbfiles[@]}; do
		[ ! -f ${file} ] && continue
		fsz=$(du -hb ${file} | awk '{print $1}')
		printf "%-26s: $fsz Bytes\t ($(numfmt --to=iec $fsz))\n" "${file}"
		dbsz=$((dbsz+$fsz))
	done
	printf "%-26s: $dbsz Bytes\t ($(numfmt --to=iec $dbsz))\n\n" "Total DB size"
fi	

exit 0
