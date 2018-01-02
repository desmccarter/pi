#!/bin/bash

IFS=$'\n'

for i in `git status | grep "modified:" | sed s/".*modified:[ |	]*\(.*\)$"/"\1"/g`
do
	git add $i
done

git status

git commit -m"Updating modifications"

git push
