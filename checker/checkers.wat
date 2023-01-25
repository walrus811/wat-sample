(module
  (import "events" "piecemoved"
    (func $notify_piecemoved (param $fromX i32) (param $fromY i32)
                             (param $toX i32) (param $toY i32))
  )
  (import "events" "piececrowned"
    (func $notify_piececrowned (param $fromX i32) (param $fromY i32))
  )

  (memory $mem 1) ;;allocate memory 1 page(64kb)
  (global $WHITE i32 (i32.const 2))
  (global $BLACK i32 (i32.const 1))
  (global $CROWN i32 (i32.const 4))
  ;; black - 1, white - 2
  (global $currentTurn (mut i32) (i32.const 0))

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
  
  (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
    (i32.store
      (call $offsetForPosition
        (local.get $x)
        (local.get $y)
      )
      (local.get $piece)
    )
  )

  (func $getPiece (param $x i32) (param $y i32) (result i32)
    (if (result i32)
      (block (result i32)
        (i32.and
          (call $inRange
            (i32.const 0)
            (i32.const 7)
            (local.get $x)
          )
          (call $inRange
            (i32.const 0)
            (i32.const 7)
            (local.get $y)
          )
        )
      )
      (then
        (i32.load
          (call $offsetForPosition
            (local.get $x)
            (local.get $y)
          )
        )
      )
      (else
        (unreachable)
      )
    )
  )

  (func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $value) (local.get $low))
      (i32.le_s (local.get $value) (local.get $high))
    )
  )

  (func $getTurnOwner (result i32)
    (global.get $currentTurn)
  )

  (func $toggleTurnOwner
    (if (i32.eq (call $getTurnOwner) (i32.const 1))
      (then (call $setTurnOwner (i32.const 2)))
      (else (call $setTurnOwner (i32.const 1)))
    )
  )

  (func $setTurnOwner (param $piece i32)
    (global.set $currentTurn (local.get $piece))
  )

  (func $isPlayersTurn (param $player i32) (result i32)
    (i32.gt_s
      (i32.and (local.get $player) (call $getTurnOwner))
      (i32.const 0)
    )
  )

  (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
    (i32.or
      (i32.and
        (i32.eq
          (local.get $pieceY)
          (i32.const 0)
        )
        (call $isBlack (local.get $piece))
      )

      (i32.and
        (i32.eq
          (local.get $pieceY)
          (i32.const 7)
        )
        (call $isWhite (local.get $piece))
      )
    )
  )

  (func $crownPiece (param $x i32) (param $y i32)
    (local $piece i32)
    (local.set $piece (call $getPiece (local.get $x) (local.get $y)))

    (call $setPiece (local.get $x) (local.get $y)
      (call $withCrown (local.get $piece))
    )
    ;;implmented by host
    (call $notify_piececrowned (local.get $x) (local.get $y))
  )
  
  (func $distance (param $x i32) (param $y i32) (result i32)
    (i32.sub (local.get $x) (local.get $y))
  )

  (func $isValidMove (param $fromX i32) (param $fromY i32)
                     (param $toX i32) (param $toY i32) (result i32)
    (local $player i32)
    (local $target i32)

    (local.set $player (call $getPiece (local.get $fromX) (local.get $fromY)))
    (local.set $target (call $getPiece (local.get $toX) (local.get $toY)))

    (if (result i32)
      (block (result i32)
        (i32.and
          (call $validJumpDistance (local.get $fromY) (local.get $toY))
          (i32.and
            (call $isPlayersTurn (local.get $player))
            (i32.eq (local.get $target) (i32.const 0))
          )
        )
      )
      (then
        (i32.const 1)
      )
      (else 
        (i32.const  0)
      )
    )
  )

  (func $validJumpDistance (param $from i32) (param $to i32) (result i32)
    (local $d i32)
    (local.set $d
      (if (result i32)
        (i32.gt_s (local.get $to) (local.get $from))
        (then
          (call $distance (local.get $to) (local.get $from))
        )
        (else
          (call $distance (local.get $from) (local.get $to))
        ))
    )
    (i32.le_u
      (local.get $d)
      (i32.const 2)
    )
  )

  (func $move (param $fromX i32) (param $fromY i32)
                     (param $toX i32) (param $toY i32) (result i32)
    (if (result i32)
      (block (result i32)
        (call $isValidMove (local.get $fromX) (local.get $fromY)
                           (local.get $toX) (local.get $toY)
        )
      )
      (then
        (call $do_move (local.get $fromX) (local.get $fromY)
                           (local.get $toX) (local.get $toY)
        )
      )
      (else
        (i32.const 0)
      )
    )
  )

  (func $do_move (param $fromX i32) (param $fromY i32)
                     (param $toX i32) (param $toY i32) (result i32)
    (local $curpiece i32)
    (local.set $curpiece (call $getPiece (local.get $fromX) (local.get $fromY)))

    (call $toggleTurnOwner)
    (call $setPiece (local.get $toX) (local.get $toY) (local.get $curpiece))
    (call $setPiece (local.get $fromX) (local.get $fromY) (i32.const 0))
    (if (call $shouldCrown (local.get $toY) (local.get $curpiece))
    (then (call $crownPiece (local.get $toX) (local.get $toY))))
    (call $notify_piecemoved (local.get $fromX) (local.get $fromY)
    (local.get $toX) (local.get $toY))
    (i32.const 1)
  )

  (func $initBoard 
    (call $setPiece (i32.const 1) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 3) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 5) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 7) (i32.const 0) (i32.const 2))
    (call $setPiece (i32.const 0) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 2) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 4) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 6) (i32.const 1) (i32.const 2))
    (call $setPiece (i32.const 1) (i32.const 2) (i32.const 2))
    (call $setPiece (i32.const 3) (i32.const 2) (i32.const 2))
    (call $setPiece (i32.const 5) (i32.const 2) (i32.const 2))
    (call $setPiece (i32.const 7) (i32.const 2) (i32.const 2))

    (call $setPiece (i32.const 0) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 2) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 4) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 6) (i32.const 5) (i32.const 1))
    (call $setPiece (i32.const 1) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 3) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 5) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 7) (i32.const 6) (i32.const 1))
    (call $setPiece (i32.const 0) (i32.const 7) (i32.const 1))
    (call $setPiece (i32.const 2) (i32.const 7) (i32.const 1))
    (call $setPiece (i32.const 4) (i32.const 7) (i32.const 1))
    (call $setPiece (i32.const 6) (i32.const 7) (i32.const 1))

    (call $setTurnOwner (i32.const 1))
  )

  (export "getPiece" (func $getPiece))
  (export "isCrowned" (func $isCrowned))
  (export "initBoard" (func $initBoard))
  (export "getTurnOwner" (func $getTurnOwner))
  (export "move" (func $move))
  (export "memory" (memory $mem))
)