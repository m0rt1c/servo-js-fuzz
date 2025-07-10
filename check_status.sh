#!/bin/bash

for target in $(find ./out -maxdepth 1 -mindepth 1 -type d)
do
	echo $target
	cargo afl whatsup -s -m $target
done

