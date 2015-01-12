(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

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
