open Ctypes
open Foreign

type error = Uv_consts.error
(** Error type returned by functions or passed to callbacks *)

val error_to_string : error -> string
(** Error to a human readable message *)

type 'a result = Ok of 'a | Error of error

type status = unit result
(** Return value for most functions *)

val ok : status
(** Convenience. Most all functions return Ok ().*)

val ok_exn : 'a result -> 'a
(** Convenience function. Failswith the error message if not Ok. *)

type timespec = {
  tv_sec : int64;
  tv_nsec : int64 (* TODO what type should these be? *)
}

type stat = {
  (* Note a lot of these types have standard Posix types. libuv, being
     a cross platform library, does not use these types, and uses uint64_t
     for all of these fields. This struct follows suit.
   *)
  st_dev : int64;
  st_mode : int64;
  st_nlink : int64;
  st_uid : int64;
  st_gid : int64;
  st_rdev : int64;
  st_ino : int64;
  st_size : int64;
  st_blksize : int64;
  st_blocks : int64;
  st_flags : int64;
  st_gen : int64;
  st_atim : timespec;
  st_mtim : timespec;
  st_ctim : timespec;
  st_birthtim : timespec
}

module Loop :
sig
  type t

  type run_mode = RunDefault | RunOnce | RunNoWait

  val default_loop : unit -> t

  val run : ?loop:t -> run_mode -> status
end

module Request :
sig
  type 'a t

  (* Types that don't need their own modules *)

  type write_req
  (** Phantom type identifying write requests *)

  type write = write_req t
  (** The type of write requests *)

  val cancel : 'a t -> unit
end

module Handle :
sig
  type 'a t

  val loop : 'a t -> Loop.t

  val close : ?cb:('a t -> unit) -> _ t -> unit
end

module Stream :
sig
  type 'a stream
  (** Phantom type *)

  type 'a t = 'a stream Handle.t

  val listen : ?cb:('a t -> int -> unit) -> 'a t -> int -> unit
  val accept : 'a t -> 'a t -> unit
  val read_start : ?cb:('a t -> int -> Buf.t -> unit) -> 'a t -> unit
  val write : ?cb:(Request.write -> int -> unit) -> 'a t -> Buf.t -> Request.write
end

module Shutdown :
sig
  type shutdown
  type t = shutdown Request.t
end

type iobuf = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

module FS :
sig
  type fs
  type t = fs Request.t

  val openfile : ?loop:Loop.t -> ?perm:int -> cb:(t -> unit) -> string -> int -> status (* TODO unix flags *)
  val close : ?loop:Loop.t -> cb:(t -> unit) -> int -> status

  val read : ?loop:Loop.t -> ?offset:int -> cb:(t -> iobuf -> unit) -> int -> iobuf -> status
  (** offset defaults to -1 which is use current offset. *)

  val write : ?loop:Loop.t -> ?offset:int -> cb:(t -> iobuf -> unit) -> int -> iobuf -> status
  (** offset defaults to -1 which is use current offset. *)

  val stat : ?loop:Loop.t -> cb:(t -> stat -> unit) -> string -> status
  val fstat : ?loop:Loop.t -> cb:(t -> stat -> unit) -> int -> status
  val lstat : ?loop:Loop.t -> cb:(t -> stat -> unit) -> string -> status
  val unlink : ?loop:Loop.t -> cb:(t -> unit) -> string -> status
  val mkdir : ?loop:Loop.t -> ?mode:int -> cb:(t -> unit) -> string -> status
  val mkdtemp : ?loop:Loop.t -> cb:(t -> unit) -> string -> status
  val rmdir : ?loop:Loop.t -> cb:(t -> unit) -> string -> status
  val rename : ?loop:Loop.t -> cb:(t -> unit) -> string -> string -> status
  val fsync : ?loop:Loop.t -> cb:(t -> unit) -> int -> status
  val fdatasync : ?loop:Loop.t -> cb:(t -> unit) -> int -> status
  val ftruncate : ?loop:Loop.t -> cb:(t -> unit) -> int -> int -> status
  val sendfile : ?loop:Loop.t -> ?offset:int -> cb:(t -> unit) -> int -> int ->
    int -> status
  val chmod : ?loop:Loop.t -> cb:(t -> unit) -> string -> int -> status
  (* TODO: scandir *)

  (* Accessor functions *)

  val buf : t -> iobuf
  val result : t -> int result
  val path : t -> string
end

type mysock
type myossock
val ip4_addr : string -> int -> mysock

module TCP :
sig
  type tcp
  type t = tcp Stream.t
  type connect
  type c = connect Request.t

  val init : ?loop:Loop.t -> unit -> t
  val bind : t-> mysock (* TODO sockaddr *) -> int (* TODO flags*) -> status
  val connect : t -> mysock -> cb:(c -> int -> unit) -> status
  val nodelay : t -> int -> status
  val keepalive : t -> int -> Unsigned.uint -> status
  val simultaneous_accepts : t -> int -> status
  val getsockname : t -> mysock -> status
  val getpeername : t -> mysock -> status
  val open_socket : t -> myossock -> status
end
