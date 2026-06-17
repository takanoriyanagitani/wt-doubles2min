(module

  (memory 2)

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

  (func $test00 (export "test00_doubles2min_nodata") (result i32)
    i32.const 0 ;; dummy
    i32.const 0 ;; no data
    call $doubles2min
    drop ;; ignore the min
    i32.const 0
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test01 (export "test01_doubles2min_single") (result i32)
    ;; setup the mem
    i32.const 0x0001_0000
    f64.const 1013.25
    f64.store

    i32.const 0x0001_0000
    i32.const 1
    call $doubles2min
    f64.const 1013.25
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 1
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test02 (export "test02_doubles2min_multi") (result i32)
    ;; setup the mem
    ;;;; -- DATA 0 --
    i32.const 0x0001_0000
    f64.const 1013.25
    f64.store offset=0
    ;;;; -- DATA 1 --
    i32.const 0x0001_0000
    f64.const 0.5
    f64.store offset=8
    ;;;; -- DATA 2 --
    i32.const 0x0001_0000
    f64.const 299792458.0
    f64.store offset=16
    ;;;; -- DATA 3 --
    i32.const 0x0001_0000
    f64.const -0.125
    f64.store offset=24

    i32.const 0x0001_0000
    i32.const 4
    call $doubles2min
    f64.const -0.125
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 1
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
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

  (func $test10 (export "test10_doubles2min_simd_nodata") (result i32)
    i32.const 0 ;; dummy
    i32.const 0
    call $doubles2min_simd_unroll0
    drop ;; ignore the min
    i32.const 0
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test11 (export "test11_doubles2min_simd_single") (result i32)
    (local $min v128)
    (local $has_data i32)

    ;; init the mem
    i32.const 0x0001_0000
    v128.const f64x2 2.5 1.5
    v128.store

    i32.const 0x0001_0000
    i32.const 1
    call $doubles2min_simd_unroll0
    local.set $min
    local.tee $has_data
    i32.eqz
    if
      i32.const 1
      return
    end

    v128.const f64x2 2.5 1.5
    local.get $min
    i64x2.eq
    i64x2.all_true
    i32.eqz
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test12 (export "test12_doubles2min_simd_multi") (result i32)
    (local $min v128)
    (local $has_data i32)

    ;; init the mem
    ;;;; -- DATA 0 --
    i32.const 0x0001_0000
    v128.const f64x2 9.5 8.5
    v128.store offset=0
    ;;;; -- DATA 1 --
    i32.const 0x0001_0000
    v128.const f64x2 2.5 1.5
    v128.store offset=16
    ;;;; -- DATA 2 --
    i32.const 0x0001_0000
    v128.const f64x2 7.5 6.5
    v128.store offset=32

    i32.const 0x0001_0000
    i32.const 3
    call $doubles2min_simd_unroll0
    local.set $min
    local.tee $has_data
    i32.eqz
    if
      i32.const 1
      return
    end

    v128.const f64x2 2.5 1.5
    local.get $min
    i64x2.eq
    i64x2.all_true
    i32.eqz
    if
      i32.const 1
      return
    end

    i32.const 0
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

  (func $test20 (export "test20_results2result_nodata") (result i32)
    i32.const 0
    v128.const f64x2 0.0 0.0 ;; dummy
    i32.const 0
    f64.const 0.0 ;; dummy
    call $results2result
    drop ;; ignore
    i32.const 0
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test21 (export "test21_results2result_scalar_only") (result i32)
    (local $ret_s i32)
    (local $res_s f64)

    i32.const 0
    v128.const f64x2 0.0 0.0 ;; dummy
    i32.const 1
    f64.const 2.5
    call $results2result
    local.set $res_s
    local.tee $ret_s
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $res_s
    f64.const 2.5
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test22 (export "test22_results2result_vector_only") (result i32)
    (local $ret_s i32)
    (local $res_s f64)

    i32.const 1
    v128.const f64x2 1.5 2.5
    i32.const 0
    f64.const 0.0 ;; dummy
    call $results2result
    local.set $res_s
    local.tee $ret_s
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $res_s
    f64.const 1.5
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test23 (export "test23_results2result_both") (result i32)
    (local $ret_s i32)
    (local $res_s f64)

    i32.const 1
    v128.const f64x2 0.5 1.5
    i32.const 1
    f64.const 2.5
    call $results2result
    local.set $res_s
    local.tee $ret_s
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $res_s
    f64.const 0.5
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 0
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
    call $doubles2min_simd_unroll0
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

  (func $test30 (export "test30_doubles2min_simd_common_nodata") (result i32)
    i32.const 0 ;; dummy
    i32.const 0 ;; no data
    call $doubles2min_simd_common
    drop ;; ignore
    i32.const 0
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test31 (export "test31_doubles2min_simd_common_single") (result i32)
    (local $min f64)
    (local $res i32)

    ;; store the data
    ;; -- DATA 0 --
    i32.const 0x0001_0000
    f64.const 1013.25
    f64.store offset=0

    i32.const 0x0001_0000
    i32.const 1
    call $doubles2min_simd_common
    local.set $min
    local.tee $res
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    f64.const 1013.25
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test32 (export "test32_doubles2min_simd_common_vec_only") (result i32)
    (local $min f64)
    (local $res i32)

    ;; store the data
    ;; -- DATA 0 --
    i32.const 0x0001_0000
    f64.const 1013.25
    f64.store offset=0
    ;; -- DATA 1 --
    i32.const 0x0001_0000
    f64.const 299792458.0
    f64.store offset=8
    ;; -- DATA 2 --
    i32.const 0x0001_0000
    f64.const 42.0
    f64.store offset=16
    ;; -- DATA 3 --
    i32.const 0x0001_0000
    f64.const 3776.0
    f64.store offset=24

    i32.const 0x0001_0000
    i32.const 4
    call $doubles2min_simd_common
    local.set $min
    local.tee $res
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    f64.const 42.0
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test33 (export "test33_doubles2min_simd_common_both") (result i32)
    (local $min f64)
    (local $res i32)

    ;; store the data
    ;; -- DATA 0 --
    i32.const 0x0001_0000
    f64.const 1013.25
    f64.store offset=0
    ;; -- DATA 1 --
    i32.const 0x0001_0000
    f64.const 299792458.0
    f64.store offset=8
    ;; -- DATA 2 --
    i32.const 0x0001_0000
    f64.const 42.0
    f64.store offset=16
    ;; -- DATA 3 --
    i32.const 0x0001_0000
    f64.const 3776.0
    f64.store offset=24
    ;; -- DATA 4 --
    i32.const 0x0001_0000
    f64.const -42.0
    f64.store offset=32

    i32.const 0x0001_0000
    i32.const 5
    call $doubles2min_simd_common
    local.set $min
    local.tee $res
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    f64.const -42.0
    f64.ne
    if
      i32.const 1
      return
    end

    i32.const 0
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

  (func $test40 (export "test40_doubles2min_simd_unroll4x_only_nodat") (result i32)
    i32.const 0 ;; dummy
    i32.const 0 ;; no groups
    call $doubles2min_simd_unroll4x_only
    drop ;; ignore the min
    i32.const 0
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test41 (export "test41_doubles2min_simd_unroll4x_only_single") (result i32)
    (local $min v128)
    (local $ret i32)

    ;; save the group
    ;;;; -- GROUP 0, DATA 0 --
    i32.const 0x0001_0000
    v128.const f64x2 9.5 1.5
    v128.store offset=0
    ;;;; -- GROUP 0, DATA 1 --
    i32.const 0x0001_0000
    v128.const f64x2 2.5 0.5
    v128.store offset=16
    ;;;; -- GROUP 0, DATA 2 --
    i32.const 0x0001_0000
    v128.const f64x2 1.5 5.5
    v128.store offset=32
    ;;;; -- GROUP 0, DATA 3 --
    i32.const 0x0001_0000
    v128.const f64x2 6.5 7.5
    v128.store offset=48

    i32.const 0x0001_0000
    i32.const 1 ;; single group
    call $doubles2min_simd_unroll4x_only
    local.set $min
    local.tee $ret
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    v128.const f64x2 1.5 0.5
    f64x2.eq
    i64x2.all_true
    i32.eqz
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test42 (export "test42_doubles2min_simd_unroll4x_only_multi") (result i32)
    (local $min v128)
    (local $ret i32)

    ;; save the group 0
    ;;;; -- GROUP 0, DATA 0 --
    i32.const 0x0001_0000
    v128.const f64x2 9.5 1.5
    v128.store offset=0
    ;;;; -- GROUP 0, DATA 1 --
    i32.const 0x0001_0000
    v128.const f64x2 2.5 0.5
    v128.store offset=16
    ;;;; -- GROUP 0, DATA 2 --
    i32.const 0x0001_0000
    v128.const f64x2 1.5 5.5
    v128.store offset=32
    ;;;; -- GROUP 0, DATA 3 --
    i32.const 0x0001_0000
    v128.const f64x2 6.5 7.5
    v128.store offset=48

    ;; save the group 1
    ;;;; -- GROUP 1, DATA 0 --
    i32.const 0x0001_0000
    v128.const f64x2 9.5 0.1
    v128.store offset=64
    ;;;; -- GROUP 1, DATA 1 --
    i32.const 0x0001_0000
    v128.const f64x2 2.5 0.5
    v128.store offset=80
    ;;;; -- GROUP 1, DATA 2 --
    i32.const 0x0001_0000
    v128.const f64x2 0.2 5.5
    v128.store offset=96
    ;;;; -- GROUP 1, DATA 3 --
    i32.const 0x0001_0000
    v128.const f64x2 6.5 7.5
    v128.store offset=112

    i32.const 0x0001_0000
    i32.const 2 ;; 2 groups
    call $doubles2min_simd_unroll4x_only
    local.set $min
    local.tee $ret
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    v128.const f64x2 0.2 0.1
    f64x2.eq
    i64x2.all_true
    i32.eqz
    if
      i32.const 1
      return
    end

    i32.const 0
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
    call $doubles2min_simd_unroll0
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

  (func $test50 (export "test50_doubles2min_simd_unroll4x_nodata") (result i32)
    i32.const 0 ;; dummy
    i32.const 0 ;; no vecs
    call $doubles2min_simd_unroll4x
    drop ;; ignore
    i32.const 0
    i32.ne
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test51 (export "test51_doubles2min_simd_unroll4x_single") (result i32)
    (local $min v128)
    (local $has_data i32)

    ;; save the group 0, 3x v128
    ;;;; GROUP 0, vec 0
    i32.const 0x0001_0000
    v128.const f64x2 1.5 2.5
    v128.store offset=0
    ;;;; GROUP 0, vec 1
    i32.const 0x0001_0000
    v128.const f64x2 0.5 1.5
    v128.store offset=16
    ;;;; GROUP 0, vec 2
    i32.const 0x0001_0000
    v128.const f64x2 5.5 6.5
    v128.store offset=32

    i32.const 0x0001_0000
    i32.const 3 ;; 3 vecs, 1 group
    call $doubles2min_simd_unroll4x
    local.set $min
    local.tee $has_data
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    v128.const f64x2 0.5 1.5
    f64x2.eq
    i64x2.all_true
    i32.eqz
    if
      i32.const 1
      return
    end

    i32.const 0
  )

  (func $test52 (export "test52_doubles2min_simd_unroll4x_multi") (result i32)
    (local $min v128)
    (local $has_data i32)

    ;; save the group 0
    ;;;; GROUP 0, vec 0
    i32.const 0x0001_0000
    v128.const f64x2 1.5 2.5
    v128.store offset=0
    ;;;; GROUP 0, vec 1
    i32.const 0x0001_0000
    v128.const f64x2 9.5 1.3
    v128.store offset=16
    ;;;; GROUP 0, vec 2
    i32.const 0x0001_0000
    v128.const f64x2 5.5 6.5
    v128.store offset=32
    ;;;; GROUP 0, vec 3
    i32.const 0x0001_0000
    v128.const f64x2 7.5 8.5
    v128.store offset=48

    ;; save the group 1
    ;;;; GROUP 1, vec 0
    i32.const 0x0001_0000
    v128.const f64x2 1.5 2.5
    v128.store offset=64
    ;;;; GROUP 1, vec 1
    i32.const 0x0001_0000
    v128.const f64x2 0.1 1.5
    v128.store offset=80
    ;;;; GROUP 1, vec 2
    i32.const 0x0001_0000
    v128.const f64x2 5.5 6.5
    v128.store offset=96

    i32.const 0x0001_0000
    i32.const 7 ;; 7 vecs, 2 groups
    call $doubles2min_simd_unroll4x
    local.set $min
    local.tee $has_data
    i32.eqz
    if
      i32.const 1
      return
    end

    local.get $min
    v128.const f64x2 0.1 1.3
    f64x2.eq
    i64x2.all_true
    i32.eqz
    if
      i32.const 1
      return
    end

    i32.const 0
  )

)

(assert_return (invoke "test00_doubles2min_nodata") (i32.const 0))
(assert_return (invoke "test01_doubles2min_single") (i32.const 0))
(assert_return (invoke "test02_doubles2min_multi") (i32.const 0))

(assert_return (invoke "test10_doubles2min_simd_nodata") (i32.const 0))
(assert_return (invoke "test11_doubles2min_simd_single") (i32.const 0))
(assert_return (invoke "test12_doubles2min_simd_multi") (i32.const 0))

(assert_return (invoke "test20_results2result_nodata") (i32.const 0))
(assert_return (invoke "test21_results2result_scalar_only") (i32.const 0))
(assert_return (invoke "test22_results2result_vector_only") (i32.const 0))
(assert_return (invoke "test23_results2result_both") (i32.const 0))

(assert_return (invoke "test30_doubles2min_simd_common_nodata") (i32.const 0))
(assert_return (invoke "test31_doubles2min_simd_common_single") (i32.const 0))
(assert_return (invoke "test32_doubles2min_simd_common_vec_only") (i32.const 0))
(assert_return (invoke "test33_doubles2min_simd_common_both") (i32.const 0))

(assert_return (invoke "test40_doubles2min_simd_unroll4x_only_nodat") (i32.const 0))
(assert_return (invoke "test41_doubles2min_simd_unroll4x_only_single") (i32.const 0))
(assert_return (invoke "test42_doubles2min_simd_unroll4x_only_multi") (i32.const 0))

(assert_return (invoke "test50_doubles2min_simd_unroll4x_nodata") (i32.const 0))
(assert_return (invoke "test51_doubles2min_simd_unroll4x_single") (i32.const 0))
(assert_return (invoke "test52_doubles2min_simd_unroll4x_multi") (i32.const 0))
