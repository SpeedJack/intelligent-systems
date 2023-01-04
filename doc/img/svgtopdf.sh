#!/bin/bash

for f in *.svg; do
	if [ ! -f "${f/.svg/.pdf}" ]; then
		convert -density 300 "${f}" "${f/.svg/.pdf}"
	fi
done

