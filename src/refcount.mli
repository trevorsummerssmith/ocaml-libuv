(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

(* A reference counter: maintains a reference to an object until its count goes
 * to zero; useful for preventing GC cleaning up function callbacks passed to
 * libuv calls *)
type 'a t

(* Empty reference counter *)
val create : unit -> 'a t

(* Increment the number of references to an object *)
val incr : 'a t -> 'a -> unit

(* Decrement the number of references to an object, removing it if the count
 * drops to zero *)
val decr : 'a t -> 'a -> unit
