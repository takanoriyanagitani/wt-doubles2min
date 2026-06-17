# Simple Benchmark

## SIMD version(w/o unroll), mac

| tool   | opt | input  | real | user | sys | rss     | rate      | ratio  |
|:------:|:---:|:------:|:----:|:----:|:---:|:-------:|:---------:|:------:|
| wazero | no  | 16 GiB | 4.9  | 1.3  | 1.1 | 7.8 MiB | 3.3 GiB/s |  100%  |
| wazero | yes | 16 GiB | 4.9  | 1.3  | 1.1 | 7.6 MiB | 3.3 GiB/s |   99%  |

## SIMD version(w/ unroll 4x), mac

| tool      | opt | input  | real | user | sys | rss      | rate      | ratio  |
|:---------:|:---:|:------:|:----:|:----:|:---:|:--------:|:---------:|:------:|
| wazero    | no  | 16 GiB |  4.4 | 0.8  | 1.1 |  7.7 MiB | 3.6 GiB/s |  110%  |
| wazero    | yes | 16 GiB |  4.4 | 0.8  | 1.1 |  7.7 MiB | 3.6 GiB/s |  110%  |
| iwasm/aot | no  | 16 GiB |  4.3 | 0.4  | 1.2 | 10.3 MiB | 3.7 GiB/s |  113%  |
| iwasm/aot | yes | 16 GiB |  5.0 | 1.1  | 1.3 | 10.3 MiB | 3.2 GiB/s |   98%  |
| wasmi     | no  | 16 GiB |  9.1 | 7.0  | 0.7 |  8.2 MiB | 1.8 GiB/s |   53%  |
| wasmi     | yes | 16 GiB |  9.0 | 6.8  | 0.6 |  8.1 MiB | 1.8 GiB/s |   54%  |
| wasmer    | yes | 16 GiB | 13.2 | 3.8  | 6.5 | 24.3 MiB | 1.2 GiB/s |   37%  |

## SIMD version(w/ unroll 4x), linux

| tool      | opt | input  | real | user | sys | rss      | rate      |
|:---------:|:---:|:------:|:----:|:----:|:---:|:--------:|:---------:|
| wazero    | no  | 16 GiB | 3.1  | 0.7  | 1.9 |  7.6 MiB | 5.2 GiB/s |
| wazero    | yes | 16 GiB | 3.0  | 0.8  | 1.8 |  7.8 MiB | 5.3 GiB/s |

## Scalar version, mac

| tool   | opt | input  | real | user | sys | rss     | rate      | ratio  |
|:------:|:---:|:------:|:----:|:----:|:---:|:-------:|:---------:|:------:|
| wazero | no  | 16 GiB | 4.9  | 2.2  | 0.7 | 7.6 MiB | 3.3 GiB/s | (100%) |
| wazero | yes | 16 GiB | 4.8  | 2.2  | 0.7 | 7.7 MiB | 3.3 GiB/s |  101%  |

## Environment Info

- mac: macOS 26 w/ M3 Max
- linux: ubuntu 26.04 w/ 13th Gen Core i7-13700
