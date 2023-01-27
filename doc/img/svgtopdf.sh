#!/bin/bash

for f in *.svg; do
	if [ ! -f "${f/.svg/.pdf}" ]; then
		echo "Converting ${f} to PDF..."
		convert -density 300 "${f}" "${f/.svg/.pdf}"
	fi
done

