open OUnit

open Uv

let test_accessors () =
  let loop = Loop.default_loop () in
  let handle = TCP.init ~loop:loop () in
  assert_equal loop (Handle.loop handle)

let suite =
  "handle suite">:::
  [
    "accessors">::test_accessors;
  ]
