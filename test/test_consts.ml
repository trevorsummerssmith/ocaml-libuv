open OUnit

(* This is here to ensure that the plumbing works in the whole
   compile consts from c to ocaml. *)

let test_a_const _ =
  (* Obviously this is brittle. But we just need something to ensure it is
     working. If it breaks, then we need to update the codebase. *)
  assert_equal Uv_consts.uv_eof (-4095)

let suite =
  "consts suite">:::
  ["const">::test_a_const]
