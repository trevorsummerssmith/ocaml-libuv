(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

type 'a t = ('a, int) Hashtbl.t

let create () = Hashtbl.create 10 (* TODO figure out what this should be *)

let incr t s =
    if Hashtbl.mem t s then
        Hashtbl.replace t s ((Hashtbl.find t s) + 1)
    else
        Hashtbl.add t s 0

let decr t s =
    let count = Hashtbl.find t s in
    if count > 0 then
        Hashtbl.replace t s (count - 1)
    else
        Hashtbl.remove t s
