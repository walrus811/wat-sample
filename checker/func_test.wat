(module
  (memory $mem 1)
  (global $WHITE i32 (i32.const 2))
  (global $BLACK i32 (i32.const 1))
  (global $CROWN i32 (i32.const 4))

  ;; 8X8 board
  (func $indexForPosition (param $x i32) (param $y i32) (result i32)
    (i32.add
      (i32.mul
        (i32.const 8)
        (local.get $y)
      )
      (local.get $x)
    )
  )

  ;; each spot take 4 bytes
  (func $offsetForPosition (param $x i32) (param $y i32) (result i32)
      (i32.mul
        (call $indexForPosition (local.get $x) (local.get $y))
        (i32.const 4)
      )
  ) 
  ;; 0x00000001 - Black, 0x00000002 - Black, 0x00000004 - Crowned 

  (func $isCrowned (param $piece i32) (result i32)
      (i32.eq
        (i32.and (local.get $piece) (global.get $CROWN))
        (global.get $CROWN)
      )
  )

  (func $isWhite (param $piece i32) (result i32)
      (i32.eq
        (i32.and (local.get $piece) (global.get $WHITE))
        (global.get $WHITE)
      )
  )

  (func $isBlack (param $piece i32) (result i32)
      (i32.eq
        (i32.and (local.get $piece) (global.get $BLACK))
        (global.get $BLACK)
      )
  )

  (func $withCrown (param $piece i32) (result i32)
      (i32.or (local.get $piece) (global.get $CROWN))
  )

  (func $withoutCrown (param $piece i32) (result i32)
      (i32.and (local.get $piece) (i32.const 3))
  )

  (export "offsetForPosition" (func $offsetForPosition))
  (export "isCrowned" (func $isCrowned))
  (export "isWhite" (func $isWhite))
  (export "isBlack" (func $isBlack))
  (export "withCrown" (func $withCrown))
  (export "withoutCrown" (func $withoutCrown))
)
