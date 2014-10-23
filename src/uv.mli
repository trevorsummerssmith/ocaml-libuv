open Ctypes
open Foreign

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

  val ok : t -> int64

  val default_loop : unit -> t

  val run : ?loop:t -> run_mode -> int
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

  val openfile : ?loop:Loop.t -> ?cb:(t -> unit) -> ?perm:int -> string -> int -> t (* TODO unix flags *)
  val close : ?loop:Loop.t -> ?cb:(t -> unit) -> int -> t
  val read : ?loop:Loop.t -> ?cb:(t -> unit) -> ?offset:int -> int -> t
  val write : ?loop:Loop.t -> ?cb:(t -> unit) -> ?offset:int -> int -> iobuf -> t
  val stat : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> t
  val fstat : ?loop:Loop.t -> ?cb:(t -> unit) -> int -> t
  val lstat : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> t
  val unlink : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> t
  val mkdir : ?loop:Loop.t -> ?cb:(t -> unit) -> ?mode:int -> string -> t
  val mkdtemp : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> t
  val rmdir : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> t
  val rename : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> string -> t
  val fsync : ?loop:Loop.t -> ?cb:(t -> unit) -> int -> t
  val fdatasync : ?loop:Loop.t -> ?cb:(t -> unit) -> int -> t
  val ftruncate : ?loop:Loop.t -> ?cb:(t -> unit) -> int -> int -> t
  val sendfile : ?loop:Loop.t -> ?cb:(t -> unit) -> ?offset:int -> int -> int ->
    int -> t
  val chmod : ?loop:Loop.t -> ?cb:(t -> unit) -> string -> int -> t
  (* TODO: scandir *)

  (* Accessor functions *)
  val buf : t -> iobuf
  val result : t -> int64
  val path : t -> string
  val statbuf : t -> stat
  (* TODO statbuf -- should we just let everyone access it? Or try to change the 
   signatures for the methods that actually use it? *)
end

type mysock
val ip4_addr : string -> int -> mysock

module TCP :
sig
  type tcp
  type t = tcp Stream.t

  val init : ?loop:Loop.t -> unit -> t
  val bind : t -> mysock (* TODO sockaddr *) -> int (* TODO flags*) -> unit
end
