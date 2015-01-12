(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open Uv

let fd_ref = ref 0

let rec read_callback fs _ =
  match ok_exn (FS.result fs) with
    r when r < 0 -> Printf.printf "ok"
  | r when r = 0 -> ok_exn(FS.close !fd_ref ~cb:(fun _ -> ()))
  | r ->
     let buf = FS.buf fs in
     let buf2 = Bigarray.Array1.sub buf 0 r in
     ok_exn(FS.write ~offset:(-1) ~cb:write_callback 1 buf2)
and write_callback fs _ =
  if ok_exn(FS.result fs) < 0 then
    Printf.fprintf stderr "Write error\n"
  else
    let buf = Bigarray.(Array1.create char c_layout 1024) in
    ok_exn (FS.read ~offset:(-1) !fd_ref ~cb:read_callback buf)

let open_callback fs =
  let fd = ok_exn (FS.result fs) in
  let _ = fd_ref := fd in
  let buf = Bigarray.(Array1.create char c_layout 1024) in
  ok_exn (FS.read fd ~offset:0 ~cb:read_callback buf)

let () =
  if Array.length Sys.argv != 2 then
    Printf.fprintf stderr "Usage: %s <filename>\n" Sys.argv.(0)
  else
    let () = ok_exn (FS.openfile Sys.argv.(1) ~cb:open_callback 0) in
    let ret = Loop.run Loop.RunDefault in
    match ret with
      Ok _ -> exit 0
    | Error e -> failwith (error_to_string e)
