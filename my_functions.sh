cd() {    #@ Change directory, storing new directory on DIRSTACK
	local dir error           ## variables for directory and return code

	while : ; do              ## ignore all options
		case $1 in 
			--) break ;;
			-*) shift ;;
			 *) break ;;
		esac
	done
	
	dir=$1

	if [ -n "$dir" ]; then   ## if $dir is not empty
		pushd "$dir"         ## change directory and store $dir in DIRSTACK
	else
		pushd "$HOME"        ## go HOME if nothing on the command line
	fi 2>/dev/null           ## error message should come from cd, not pushd

	error=$?

	if [ $error -ne 0 ]; then
		builtin cd "$dir"
	fi
	return "$error"
} > /dev/null

menu() {
	local IFS=$' \t\n'
	local num n=1 opt item cmd
	echo

	for item ; do
		printf "  %3d. %s\n" "$n" "${item%%:*}"
		n=$(( $n + 1 ))
	done
	echo
    
	if [ $# -lt 10 ]; then
		opt=-sn1
	else
		opt=
	fi
	read -p " (1 to $#) ==> " $opt num

	case $num in 
		[qQ0] | "") return ;;
		*[!0-9]* | 0*)
			printf "\aInvalid response: %s\n" "$num" >&2
			return 1
			;;
	esac
	echo
	
	if [ "$num" -le "$#" ]; then
		eval "${!num#*:}"
	else
		printf "\aInvalid response: %s\n" "$num" >&2
		return 1
	fi	
}

cdm() {
	local dir IFS=$'\n' item
	for dir in $(dirs -l -p); do
		[ "$dir" = "$PWD" ] && continue
		case ${item[*]} in
			*"$dir:"*) ;;
			*) item+=( "$dir:cd '$dir'") ;;
		esac
	done
	menu "${item[@]}" Quit:
}

function lsr() {  #@ List most recently modified files
	num=10
	short=0
	ls_opts=(--time-style='+%d-%b-%Y %H:%M:%S')
 
	opts=Aadn:os

	while getopts $opts opt; do
		case $opt in
			a|A|d) ls_opts+=(-$opt) ;;
			n) num=$OPTARG ;;
			o) ls_opts+=(-r) ;;
			s) short=$(( $short + 1 )) ;;
		esac
	done
	shift $(( $OPTIND - 1 ))

	case $short in
		0) ls_opts+=(-l -t) ;;
		*) ls_opts+=( -t ) ;;
	esac

	ls "${ls_opts[@]}" "$@" | {
		read
		case $line in
			total*) ;;
			*) printf "%s\n" "$REPLY" ;;
		esac
		cat
	} | head -n$num
}

