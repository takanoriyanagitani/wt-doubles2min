#!/bin/bash

wsm=./opt.wasm
wsm=./floats2min64.wasm

aot=./floats2min64.aot

input1GiB(){
  dd \
    if=/dev/zero \
    bs=1048576 \
    count=1024 \
    status=progress |
    cat \
      - \
      <(printf '6666 6666 6612 71c0' | xxd -r -ps)
}

input16GiB(){
  dd \
    if=/dev/zero \
    bs=1048576 \
    count=16384 \
    status=progress |
    cat \
      - \
      <(printf '6666 6666 6612 71c0' | xxd -r -ps)
}

min4human() {
	ifun='import functools;'
	iopr='import operator;'
	isys='import sys;'
	istr='import struct;'
	imports="${ifun} ${iopr} ${isys} ${istr}"

	python3 -c "${imports}"' functools.reduce(
    lambda state, f: f(state),
    [
      struct.Struct("<d").unpack,
      operator.itemgetter(0),
      print,
    ],
    sys.stdin.buffer.read(8),
  )'
}

bench4wazero(){
  input16GiB |
    \time -l wazero run "${wsm}" |
    min4human
}

bench4iwasm(){
  input16GiB |
    \time -l iwasm "${wsm}" |
    min4human
}

bench4iwasm_aot(){
  input16GiB |
    \time -l iwasm "${aot}" |
    min4human
}

bench4wasmedge(){
  input1GiB |
    \time -l wasmedge run "${wsm}" |
    min4human
}

#bench4wasmedge
bench4wazero
#bench4iwasm_aot
