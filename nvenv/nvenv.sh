#!/bin/bash

GREEN_START="\u001b[32m"
GREEN_STOP="\u001b[0m"
RED_START="\u001b[31m"
RED_STOP="\u001b[0m"

DEFAULT_PYTHON="3.11"

INDENT_LINE="━━━━━━━━━━━━━━━┫"

SCRIPT_DIR="$(dirname "$0")"

crazy_print_green() {
	echo -e "${GREEN_START}${INDENT_LINE} $1 ${GREEN_STOP}"
}

crazy_print_red() {
	echo -e "${RED_START}${INDENT_LINE} $1 ${RED_STOP}"
}

fail_if_needed() {
	if [ $? -ne 0 ] || [ "$1" == "1" ]; then
		crazy_print_red "ERROR IN INSTALL"
		echo -e "${RED_START}"
		cat $SCRIPT_DIR/haha_failure.txt
		echo -e "${RED_STOP}"
		exit 1
	fi
}

print_help() {
	echo -e "${GREEN_START}"
	echo "utility to quickly set up a python venv at dls"
	echo "  $ nvenv [-v <python version> -n -c] <directory to use (default \".\")>"
	echo "    -h|--help"
	echo "        print this help message"
	echo "    -v|--version"
	echo "        specify the python version (default $DEFAULT_PYTHON)"
	echo "    -n|--new"
	echo "        delete the old venv and create a new one (will happen"
	echo "        automatically if the python version is different to the"
	echo "        one specified)"
	echo "    -c|--clear"
	echo "        if using an already present venv set it up with --clear"
	echo "        (may as well use -n here but I thought I'd give the option)"
	echo "    -e|--editor"
	echo "        open vscode for the directory specified once finished"
	echo -e "${GREEN_STOP}"
}

########################## PARSE ARGUMENTS
NEW=0
CLEAR=0
DIR="."
EDITOR=0
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
	case $1 in
	-v | --version)
		PYTHON_VERSION="$2"
		shift # past argument
		shift # past alue
		;;
	-c | --clear)
		CLEAR=1
		shift # past argument
		;;
	-n | --new)
		NEW=1
		shift # past argument
		;;
	-h | --help)
		print_help
		exit 0
		;;
	-e | --editor)
		EDITOR=1
		shift
		;;
	-* | --*)
		crazy_print_red "unknown option '$1'"
		exit 1
		;;
	*)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift                   # past argument
		;;
	esac
done

if [ ${#POSITIONAL_ARGS[@]} -ge 2 ]; then
	crazy_print_red "multiple directories passed in '${POSITIONAL_ARGS[*]// / }'"
	fail_if_needed 1
fi

if [ ${#POSITIONAL_ARGS[@]} -eq 1 ]; then
	for i in "${POSITIONAL_ARGS[*]}"; do
		DIR=$i
	done
fi

if [ ! -d "$DIR" ]; then
	crazy_print_red "given directory '$DIR' is not a directory"
	fail_if_needed 1
fi

DIR="$(pwd)/$DIR"
crazy_print_green "using directory $DIR"
cd $DIR

if [ "$PYTHON_VERSION" == "" ]; then
	crazy_print_green "using default python version '$DEFAULT_PYTHON'"
	PYTHON_VERSION=$DEFAULT_PYTHON
else
	crazy_print_green "using provided python version '$PYTHON_VERSION'"
fi

########################## SET UP NEW VENV OR CLEAR EXISTING VENV IF NEEDED
if [ -d ".venv" ]; then

	if [ -f ".venv/bin/python" ]; then
		current_venv_version="$(.venv/bin/python -c "import sys; x=sys.version_info; print(f'{x[0]}.{x[1]}')")"
		fail_if_needed "failed finding python version in existing .venv/bin/python, just run with 'nvenv -n'"
	else
		current_venv_version="[version not found]"
	fi

	if [ "$NEW" == "1" ] || [ "$current_venv_version" != "$PYTHON_VERSION" ]; then
		if [ "$NEW" == "1" ]; then
			crazy_print_green "'--new' specified, deleting exisitng .venv"
		else
			if [ "$current_venv_version" != "$PYTHON_VERSION" ]; then
				crazy_print_green "python '$PYTHON_VERSION' differs from existing .venv version '$current_venv_version', deleting existing .venv"
			fi
		fi

		rm -rf .venv

		if [ -d ".venv" ]; then
			crazy_print_red ".venv was not successfully deleted, trying again..."
			rm -rf ".venv"
			fail_if_needed
			crazy_print_green ".venv was deleted that time! weird you have to ask twice huh"
		else
			crazy_print_green ".venv deleted"
		fi
	else
		crazy_print_green "using already existing .venv"
	fi
fi

if [ ! -d ".venv" ]; then
	crazy_print_green "creating new .venv"
	module load python/$PYTHON_VERSION &&
		mkdir ".venv" &&
		python -m venv --clear ".venv"
	fail_if_needed

	conda deactivate
	fail_if_needed
else
	if [ $CLEAR -eq 1 ]; then
		crazy_print_green "clearing already existing venv - might take a while with dls' fantastic filesystem :("
		python -m venv --clear ".venv"
		fail_if_needed
	fi

fi

########################## INSTALL REQUIREMENTS
crazy_print_green "upgrading pip, the diamond conda pip is normally pretty old"
.venv/bin/pip install --upgrade "pip"
fail_if_needed

if [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then
	crazy_print_green "installing editable executable"
	.venv/bin/pip install "-e" ".[dev]"
	fail_if_needed
fi

if [ -f "requirements.txt" ]; then
	crazy_print_green "installing requirements in requirements.txt"
	.venv/bin/pip install -r "requirements.txt"
	fail_if_needed
fi

if [ -f "requirements-dev.txt" ]; then
	crazy_print_green "installing dev requirements in requirements-dev.txt"
	.venv/bin/pip install -r "requirements-dev.txt"
	fail_if_needed
fi

if [ $EDITOR -eq 1 ]; then
	crazy_print_green "opening vscode"
	module "load vscode/latest"
	code "."
fi

crazy_print_green "ENJOY YOUR PYTHON/$PYTHON_VERSION IN $(pwd)/.venv"
echo -e "${GREEN_START}"
cat $SCRIPT_DIR/haha_happy.txt
echo -e "${GREEN_STOP}"
