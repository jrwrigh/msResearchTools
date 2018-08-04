#!/bin/bash

grep -A 3 -B 3 "wall clock" $1 | tail -5

