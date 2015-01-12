(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

(**
   A forgetful coat check. You can give something to the coat check with
   a ticket and it will store that for you.
   You can never get your object back. The coat check can forget that it
   is holding on to something for you, if you ask it to.
   A questionably useful coat check!
*)

type t

type ticket_stub

val create : unit -> t

val ticket : t -> ticket_stub

val store : t -> ticket_stub -> 'a -> unit

val forget : t -> ticket_stub -> unit
