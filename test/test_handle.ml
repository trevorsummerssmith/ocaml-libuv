open OUnit

open Uv

let test_accessors () =
  let loop = Loop.default_loop () in
  let handle = TCP.init ~loop:loop () in
  let handle2 = TCP.init ~loop:loop () in
  Printf.printf "loop: 0x%Lx\nHandle: 0x%Lx\nHandle: 0x%Lx\n" (Loop.ok loop) (Loop.ok (Handle.loop handle)) (Loop.ok (Handle.loop handle2));
  assert_equal loop (Handle.loop handle);
  assert_equal (Handle.loop handle) (Handle.loop handle2)

let test_loop () =
  let loop = Loop.default_loop () in
  let loop2 = Loop.default_loop () in
  assert_equal loop loop2

let suite =
  "handle suite">:::
  [
    "accessors">::test_accessors;
    "loop">::test_loop
  ]
