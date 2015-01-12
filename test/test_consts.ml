(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open OUnit

(* This is here to ensure that the plumbing works in the whole
   compile consts from c to ocaml. *)

let test_error_to_int _ =
  assert_equal (Uv_consts.error_to_int Uv_consts.UV_EOF) (-4095)

let test_int_to_error _ =
  assert_equal (Uv_consts.int_to_error (-4095)) Uv_consts.UV_EOF

let suite =
  "consts suite">:::
  ["error -> int">::test_error_to_int;
  "int -> error">::test_int_to_error;
  ]
