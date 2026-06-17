#!/bin/bash

wst=./floats2min64.wast
wtj=./floats2min64.json

wast2json "${wst}"
spectest-interp "${wtj}"
