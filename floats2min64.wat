(module

  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))

  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (import "wasi_snapshot_preview1" "fd_read"
    (func $fd_read (param i32 i32 i32 i32) (result i32)))

  (global $STDIN i32 (i32.const 0))
  (global $STDOUT i32 (i32.const 1))
  (global $STDERR i32 (i32.const 2))

  (global $READ_BUF_SIZE i32 (i32.const 32768))

  (global $NAN64bits i64 (i64.const 0x7ff8_0000_0000_0000))

  (global $FD_READ_IOVEC_PTR i32 (i32.const 0x0001_0000))
  (global $FD_READ_IOBUF_PTR i32 (i32.const 0x0002_0000))
  (global $FD_READ_BREAD_PTR i32 (i32.const 0x0003_0000))

  (global $FD_WRIT_IOVEC_PTR i32 (i32.const 0x0004_0000))
  (global $FD_WRIT_IOBUF_PTR i32 (i32.const 0x0005_0000))
  (global $FD_WRIT_BWRIT_PTR i32 (i32.const 0x0006_0000))

  (memory (export "memory") 7)

  (func $doubles2min (export "doubles2min")
    (param $ptr i32)
    (param $num_values i32)

    (result i32 f64)

    (local $min f64)

    (local $cur_ptr i32)
    (local $end_ptr i32)

    ;; results:
    ;;   i32: 0 on no data, 1 w/ data
    ;;   f64: the min

    ;; init the cur ptr
    local.get $ptr
    local.set $cur_ptr

    local.get $num_values
    i32.eqz
    if
      i32.const 0
      f64.const 0.0
      return
    end

    i32.const 1
    local.get $ptr
    f64.load
    local.set $min

    ;; compute the end pointer
    local.get $ptr
    local.get $num_values
    i32.const 3
    i32.shl
    i32.add
    local.set $end_ptr

    loop
      local.get $end_ptr
      local.get $cur_ptr
      i32.le_u
      if
        i32.const 1
        local.get $min
        return
      end

      ;; load the value
      local.get $cur_ptr
      f64.load

      ;; compute the min
      local.get $min
      f64.min

      ;; update the min
      local.set $min

      local.get $cur_ptr
      i32.const 8
      i32.add
      local.set $cur_ptr

      br 0
    end

    unreachable
  )

  (func $fd2buf
    (param $fd i32)
    (param $iovec_ptr i32)
    (param $iobuf_ptr i32)
    (param $bread_ptr i32)

    (param $len i32)

    (result i32)

    local.get $iovec_ptr
    local.get $iobuf_ptr
    i32.store
    local.get $iovec_ptr
    local.get $len
    i32.store offset=4

    local.get $fd
    local.get $iovec_ptr
    i32.const 1 ;; single buffer
    local.get $bread_ptr
    call $fd_read
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
    end

    local.get $bread_ptr
    i32.load
  )

  (func $fd2buf_full_or_eof
    (param $fd i32)
    (param $iovec_ptr i32)
    (param $iobuf_ptr i32)
    (param $bread_ptr i32)

    (param $len i32)

    (result i32)

    (local $cur_bytes_read i32)
    (local $tot_bytes_read i32)

    (local $bytes2read i32)

    (local $ptr i32)

    i32.const 0
    local.tee $cur_bytes_read
    local.set $tot_bytes_read

    loop
      local.get $tot_bytes_read
      local.get $len
      i32.eqz
      if
        local.get $len
        return
      end

      ;; compute the bytes to read
      local.get $len
      local.get $tot_bytes_read
      i32.sub
      local.set $bytes2read

      ;; compute the ptr
      local.get $iobuf_ptr
      local.get $tot_bytes_read
      i32.add
      local.set $ptr

      local.get $fd
      local.get $iovec_ptr
      local.get $ptr
      local.get $bread_ptr
      local.get $bytes2read
      call $fd2buf
      local.tee $cur_bytes_read
      i32.eqz
      ;; return on EOF
      if
        local.get $tot_bytes_read
        return
      end

      ;; update the tot bytes read
      local.get $cur_bytes_read
      local.get $tot_bytes_read
      i32.add
      local.set $tot_bytes_read

      br 0
    end

    unreachable
  )

  (func $stdin2buf (param $len i32) (result i32)
    global.get $STDIN
    global.get $FD_READ_IOVEC_PTR
    global.get $FD_READ_IOBUF_PTR
    global.get $FD_READ_BREAD_PTR
    local.get $len
    call $fd2buf_full_or_eof
  )

  (func $stdin2min_scalar (result i32 f64)
    (local $num_doubles i32)
    global.get $READ_BUF_SIZE
    call $stdin2buf
    i32.const 3
    i32.shr_u
    local.set $num_doubles

    global.get $FD_READ_IOBUF_PTR
    local.get $num_doubles
    call $doubles2min
  )

  (func $min2stdout (param $min f64)
    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 8 ;; 64-bit float = 8 bytes
    i32.store offset=4

    ;; copy the val
    global.get $FD_WRIT_IOBUF_PTR
    local.get $min
    f64.store

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 8
    i32.ne
    if
      i32.const 1
      call $proc_exit
    end
  )

  (func $doubles2min_simd_unroll0 (export "doubles2min_simd_unroll0")
    (param $ptr i32)
    (param $num_vecs i32)

    (result i32 v128)

    (local $cur_ptr i32)
    (local $end_ptr i32)

    (local $min v128)

    ;; results:
    ;;   i32: 0 on no data, 1 w/ data
    ;;   v128: the min

    ;; return on no data
    local.get $num_vecs
    i32.eqz
    if
      i32.const 0
      v128.const i64x2 0 0
      return
    end

    ;; init the current ptr
    local.get $ptr
    local.set $cur_ptr

    ;; compute the end pointer
    local.get $ptr
    local.get $num_vecs
    i32.const 4
    i32.shl
    i32.add
    local.set $end_ptr

    ;; init the min
    local.get $ptr
    v128.load
    local.set $min

    loop
      local.get $end_ptr
      local.get $cur_ptr
      i32.le_u
      if
        i32.const 1
        local.get $min
        return
      end

      ;; load the value
      local.get $cur_ptr
      v128.load

      ;; compute the min
      local.get $min
      f64x2.min

      ;; update the min
      local.set $min

      ;; update the ptr
      local.get $cur_ptr
      i32.const 16
      i32.add
      local.set $cur_ptr

      br 0
    end

    unreachable
  )

  (func $doubles2min_simd_unroll4x_only (export "doubles2min_simd_unroll4x_only")
    (param $ptr i32)
    (param $num_groups i32) ;; number of the groups(4x v128)

    (result i32 v128)

    (local $cur_ptr i32)
    (local $end_ptr i32)

    (local $min v128)

    ;; init the cur ptr
    local.get $ptr
    local.set $cur_ptr

    ;; compute the end ptr
    local.get $ptr
    local.get $num_groups ;; 4x v128 = 64 bytes
    i32.const 6
    i32.shl
    i32.add
    local.set $end_ptr

    ;; return on no data
    local.get $num_groups
    i32.eqz
    if
      i32.const 0
      v128.const f64x2 0.0 0.0 ;; dummy
      return
    end

    ;; init the min
    local.get $ptr
    v128.load
    local.set $min

    loop
      local.get $end_ptr
      local.get $cur_ptr
      i32.le_u
      if
        i32.const 1
        local.get $min
        return
      end

      ;; get the values 0,1
      local.get $cur_ptr
      v128.load offset=0
      local.get $cur_ptr
      v128.load offset=16
      ;; compute the min of 0,1
      f64x2.min

      ;; get the values 2,3
      local.get $cur_ptr
      v128.load offset=32
      local.get $cur_ptr
      v128.load offset=48
      ;; compute the min of 2,3
      f64x2.min

      ;; compute the min of 0,1,2,3
      f64x2.min

      ;; update the min
      local.set $min

      ;; update the ptr
      local.get $cur_ptr
      i32.const 64
      i32.add
      local.set $cur_ptr

      br 0
    end

    unreachable
  )

  (func $doubles2min_simd_unroll4x (export "doubles2min_simd_unroll4x")
    (param $ptr i32)
    (param $num_vecs i32)

    (result i32 v128)

    (local $num_groups i32)
    (local $num_left_vecs i32)

    (local $ptr_v i32)

    (local $ret_v i32)
    (local $ret_g i32)

    (local $rslt_v v128)
    (local $rslt_g v128)

    (local $min v128)

    ;; compute the num of groups(4x v128)
    local.get $num_vecs
    i32.const 2
    i32.shr_u
    local.tee $num_groups
    i32.eqz
    ;; just call the normal version on no groups
    if
      local.get $ptr
      local.get $num_vecs
      call $doubles2min_simd_unroll0
      return
    end

    ;; compute the num of left vecs
    local.get $num_vecs
    local.get $num_groups
    i32.const 2
    i32.shl
    i32.sub
    local.tee $num_left_vecs
    i32.eqz
    ;; just call the unrolled version on no left vecs
    if
      local.get $ptr
      local.get $num_groups
      call $doubles2min_simd_unroll4x_only
      return
    end

    ;; compute the ptr to the left vec
    local.get $ptr
    local.get $num_groups
    i32.const 6 ;; 4x v128 = 64 bytes
    i32.shl
    i32.add
    local.set $ptr_v

    ;; process the groups
    local.get $ptr
    local.get $num_groups
    call $doubles2min_simd_unroll4x_only
    local.set $rslt_g
    local.set $ret_g

    ;; process the vecs
    local.get $ptr_v
    local.get $num_left_vecs
    call $doubles2min_simd
    local.set $rslt_v
    local.set $ret_v

    ;; compute the min
    local.get $rslt_v
    local.get $rslt_g
    f64x2.min
    local.set $min

    i32.const 1 ;; ret_{v,g} should be 1
    local.get $min
  )

  (func $doubles2min_simd (export "doubles2min_simd")
    (param $ptr i32)
    (param $num_vecs i32)

    (result i32 v128)

    local.get $ptr
    local.get $num_vecs
    ;;call $doubles2min_simd_unroll0
    call $doubles2min_simd_unroll4x
  )

  (func $results2result
    (param $rv i32) (param $v v128) (param $rs i32) (param $f f64)
    (result i32 f64)

    (local $vf f64)

    ;; just return the scalar val on no vec result
    local.get $rv
    i32.eqz
    if
      local.get $rs
      local.get $f
      return
    end

    ;; compute the min of the vec
    local.get $v
    f64x2.extract_lane 0
    local.get $v
    f64x2.extract_lane 1
    f64.min
    local.set $vf

    ;; just return the min of the vec on no scalar result
    local.get $rs
    i32.eqz
    if
      local.get $rv
      local.get $vf
      return
    end

    i32.const 1

    ;; compute the min
    local.get $vf
    local.get $f
    f64.min
  )

  (func $doubles2min_simd_common (export "doubles2min_simd_common")
    (param $ptr i32)
    (param $num_doubles i32)

    (result i32 f64)

    (local $num_vecs i32)
    (local $num_scalar i32)

    (local $ptr_s i32)

    (local $ret_v i32)
    (local $ret_s i32)

    (local $min_s f64)
    (local $min_v v128)

    ;; compute the num of vecs
    local.get $num_doubles
    i32.const 1
    i32.shr_u
    local.tee $num_vecs
    i32.eqz
    ;; just call the scalar version if no vecs
    if
      local.get $ptr
      local.get $num_doubles
      call $doubles2min
      return
    end

    ;; compute the num of scalars
    local.get $num_doubles
    local.get $num_vecs
    i32.const 1
    i32.shl
    i32.sub
    local.set $num_scalar

    ;; compute the scalar ptr
    local.get $ptr
    local.get $num_vecs
    i32.const 4
    i32.shl
    i32.add
    local.set $ptr_s

    ;; process the vecs
    local.get $ptr
    local.get $num_vecs
    call $doubles2min_simd
    local.set $min_v
    local.set $ret_v

    ;; process the scalars
    local.get $ptr_s
    local.get $num_scalar
    call $doubles2min
    local.set $min_s
    local.set $ret_s

    local.get $ret_v
    local.get $min_v
    local.get $ret_s
    local.get $min_s
    call $results2result
  )

  (func $stdin2min_simd_common (result i32 f64)
    (local $num_doubles i32)
    global.get $READ_BUF_SIZE
    call $stdin2buf
    i32.const 3
    i32.shr_u
    local.set $num_doubles

    global.get $FD_READ_IOBUF_PTR
    local.get $num_doubles
    call $doubles2min_simd_common
  )

  (func $stdin2min (result i32 f64)
      ;;call $stdin2min_scalar
      call $stdin2min_simd_common
  )

  (func $stdin2min_all (param $alt f64) (result f64)
    (local $min f64)
    (local $min_cur f64)

    (local $is_first i32)

    ;; init the min
    local.get $alt
    local.set $min

    i32.const 1
    local.set $is_first

    loop
      call $stdin2min
      local.set $min_cur
      i32.eqz
      if
        local.get $min
        return
      end

      ;; init the min
      local.get $is_first
      i32.const 1
      i32.eq
      if
        local.get $min_cur
        local.set $min

        i32.const 0
        local.set $is_first
      end

      ;; update the min
      local.get $min
      local.get $min_cur
      f64.min
      local.set $min

      br 0
    end

    unreachable
  )

  (func $main (export "_start")
    global.get $NAN64bits
    f64.reinterpret_i64
    call $stdin2min_all
    call $min2stdout
  )

)
