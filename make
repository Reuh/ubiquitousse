#!/bin/sh
set -e

script="$(realpath $0)"
dir="$(dirname $0)"

cd "$dir"

case "$1" in
	can)
		canc $(find . -type f -iname '*.can')
	;;

	docs)
		ldoc .
	;;

	clean)
		rm -rf docs
		for f in $(find . -type f -iname '*.can'); do
			rm -f "${f%.can}.lua"
		done
	;;

	all)
		$script docs
		$script can
	;;

	*)
		echo "make all: build everything"
		echo "make can: build Candran files into Lua files"
		echo "make docs: build HTML documentation in docs/"
		echo "make clean: remove built documentation & Lua files"
	;;
esac
