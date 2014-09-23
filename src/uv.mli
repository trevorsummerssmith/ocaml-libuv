open Ctypes
open Foreign

module Loop :
sig
  type t

  type run_mode = RunDefault | RunOnce | RunNoWait

  val default_loop : unit -> t

  val run : t -> run_mode -> int
end

module FS :
sig
  type uv_fs
  val uv_fs : uv_fs structure typ
  val uv_fs_cb : (uv_fs structure ptr -> unit) fn
  val uv_fs_stat : Loop.t -> uv_fs structure ptr -> string -> (uv_fs structure ptr -> unit) -> int
  val path : (string, (uv_fs, [ `Struct ]) structured) field

  type t
  val stat : Loop.t -> string -> (t -> unit) -> t

(* TODO interface thoughts below XXX
  (* Accessor functions *)
  val req_type : t -> req_type
  val fs_type : t -> fs_type
  val result : t -> long (* TODO what type should this be? *)
  val path : t -> string
  (* TODO statbuf -- should we just let everyone access it? Or try to change the 
   signatures for the methods that actually use it? *)

  (* Functions *)
  (* TODO all functions below will want named params and more thought ot signatures *)
  (* TODO uv_fs_req_cleanup -- shoild this just be called within other functions? *)
  val close : Loop.t -> File.t -> (t -> unit) -> t
  val fs_open : Loop.t -> string -> flags -> mode -> (t -> unit) -> t
  val read : Loop.t -> File.t -> Bufs.t -> long (* offset *) -> (t -> unit) -> t (* TODO bufs *)
  val unlink : Loop.t -> string -> (t -> unit) -> t
  val write : Loop.t -> File.t -> Bufs.t -> long -> (* offset *) -> (t -> unit) -> t (* TODO bufs *)
  val mkdir : Loop.t -> string -> mode -> (t -> unit) -> t
  val mkdtemp : Loop.t -> string (* prefix *) -> (t -> unit) (* TODO deal with XXXX thing *)
  val rmdir : Loop.t -> string -> (t -> unit) -> t
  val readdir : Loop.t -> string -> flags -> (t -> unit) -> t (* TODO flags *)
  val readdir_next : t -> Dirent.t -> int (* TODO this signature needs to be thought through *)
  val stat : Loop.t -> string -> (t -> unit) -> t
  val fstat : Loop.t -> File.t -> (t -> unit) -> t (* TODO file *)
  val rename : Loop.t -> string -> string -> (t -> unit) -> t
  val fsync : Loop.t -> File.t -> (t -> unit) -> t
  val fdatasync : Loop.t -> File.t -> (t -> unit) -> t
  val ftruncate : Loop.t -> File.t -> long (* offset *) -> (t -> unit) -> t
  val sendfile : Loop.t -> File.t -> File.t -> long (* offset *) -> long (* length *) -> (t -> unit) -> t
  val chmod : Loop.t -> string -> mode -> (t -> unit) -> t (* TODO mode *)
  val utime : Loop.t -> string -> double -> double -> (t -> unit) -> t (* TODO signature *)
  val futime : Loop.t -> File.t -> double -> double -> (t -> unit) -> t (* TODO signature; FIle *)
  val lstat : Loop.t -> string -> (t -> unit) -> t
  val link : Loop.t -> string -> string -> (t -> unit) -> t
  val symlink : Loop.t -> string -> string -> flags -> (t -> unit) -> t (* TODO flags *)
  val readlink : Loop.t -> string -> (t -> unit) -> t
  val fchmod : Loop.t -> File.t -> mode -> (t -> unit) -> t (* TODO file, mode *)
  val chown : Loop.t -> string -> Uid.t -> Gid.t -> (t -> unit) -> t (* TODO uid, gid modules or just types? *)
  val fchown : Loop.t -> File.t -> Uid.t -> Gid.t -> (t -> unit) -> t (* TODO uid, gid modules or just types? *)
 END INTERFACE THOUGHTS *)
end

(* EXAMPLE THOUGHTS FOR HANDLE INTERFACE
module FS_event =
  (* Example handle type (init method etc) *)
  struct
    val init : Loop.t -> t
    val start : t -> (t -> unit) -> string -> flags -> t (* TODO return or int? *)
    val stop : t -> unit (* TODO int or exception? *)
    val getpath : t -> Buf.t -> int (* TODO buf or bufs? return type? *)
  end
 *)
