(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

(**
   Locking:
     This is the most straight-forward implementation of thread safe locking.
     Once we get this going and profiled it is likely we'll want to replace
     it with something more performant.
*)

module HashPhysical = Hashtbl.Make
    (struct
      type t = int
      let hash = Hashtbl.hash
      let equal = ( == )
    end)

type t = {tbl : Obj.t HashPhysical.t; lock : Mutex.t}

type ticket_stub = int

let create () =
  let tbl = HashPhysical.create 10 in
  let lock = Mutex.create () in
  {tbl; lock}

let ticket _ =
  Oo.id (object end)

let store {tbl; lock} id s =
  let obj = Obj.repr s in
  Mutex.lock lock;
  HashPhysical.add tbl id obj;
  Mutex.unlock lock

let forget {tbl; lock} id =
  Mutex.lock lock;
  HashPhysical.remove tbl id;
  Mutex.unlock lock
