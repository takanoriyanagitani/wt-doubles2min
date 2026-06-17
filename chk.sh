#!/bin/bash

wsm=./opt.wasm
wsm=./floats2min64.wasm

input0() {
	printf ''
}

input1() {
	printf '0000 004a 78de b141' | xxd -r -ps
}

input2() {
	(
		printf '0000 004a 78de b141'
		printf '0000 0000 00aa 8f40'
	) | xxd -r -ps
}

input3() {
	(
		printf '0000 004a 78de b141'
		printf '0000 0000 00aa 8f40'
		printf '0000 0000 00d0 7640'
	) | xxd -r -ps
}

input4() {
	(
		printf '0000 004a 78de b141'
		printf '0000 0000 00aa 8f40'
		printf '0000 0000 0000 4540'
		printf '0000 0000 00d0 7640'
	) | xxd -r -ps
}

input5() {
	(
		printf '0000 004a 78de b141'
		printf '0000 0000 00aa 8f40'
		printf '0000 0000 0000 4540'
		printf '6666 6666 6612 71c0'
		printf '0000 0000 00d0 7640'
	) | xxd -r -ps
}

min4wazero() {
	wazero run "${wsm}"
}

min4iwasm() {
	iwasm "${wsm}"
}

min4wasmtime() {
	wasmtime run "${wsm}"
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

input2 |
	min4wasmtime |
	min4human
