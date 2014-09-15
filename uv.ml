open Ctypes
open Foreign

(*
Examples of call back https://github.com/ocamllabs/ocaml-ctypes/blob/master/examples/fts/foreign/fts.ml
*)

(* Loop *)
type uv_loop = unit ptr
let uv_loop : uv_loop typ = ptr void

let uv_default_loop =
  foreign "uv_default_loop" (void @-> returning uv_loop)

let uv_run =
  foreign "uv_run" (uv_loop @-> int @-> returning int)
(* TODO should be an enum not an int for second arg *)

(* timespec *)

type uv_timespec
let uv_timespec : uv_timespec structure typ = structure "uv_timespec"
let tv_sec = field uv_timespec "tv_sec" long
let tv_nsec = field uv_timespec "tv_nsec" long
let () = seal uv_timespec

(* Stat *)
(*
uint64_t st_dev;
  uint64_t st_mode;
  uint64_t st_nlink;
  uint64_t st_uid;
  uint64_t st_gid;
  uint64_t st_rdev;
  uint64_t st_ino;
  uint64_t st_size;
  uint64_t st_blksize;
  uint64_t st_blocks;
  uint64_t st_flags;
  uint64_t st_gen;
  uv_timespec_t st_atim;
  uv_timespec_t st_mtim;
  uv_timespec_t st_ctim;
  uv_timespec_t st_birthtim;
*)
type uv_stat
let uv_stat : uv_stat structure typ = structure "uv_stat"
let st_dev = field uv_stat "st_dev" uint64_t
let st_mode = field uv_stat "st_mode" uint64_t
let st_nlink = field uv_stat "st_nlink" uint64_t
let st_uid = field uv_stat "st_uid" uint64_t
let st_gid = field uv_stat "st_gid" uint64_t
let st_rdev = field uv_stat "st_rdev" uint64_t
let st_ino = field uv_stat "st_ino" uint64_t
let st_size = field uv_stat "st_size" uint64_t
let st_blksize = field uv_stat "st_blksize" uint64_t
let st_blocks = field uv_stat "st_blocks" uint64_t
let st_flags = field uv_stat "st_flags" uint64_t
let st_gen = field uv_stat "st_gen" uint64_t
let st_atim = field uv_stat "st_atim" uv_timespec
let st_ctim = field uv_stat "st_ctim" uv_timespec
let st_birthtim = field uv_stat "st_birthtim" uv_timespec
let () = seal uv_stat

(* Files *)

type uv_fs
let uv_fs : uv_fs structure typ = structure "uv_fs"

let uv_fs_cb = ptr uv_fs @-> returning void

(*
#define UV_REQ_FIELDS                                                         \
  /* public */                                                                \
  void* data;                                                                 \
  /* read-only */                                                             \
  uv_req_type type;                                                           \
  /* private */                                                               \
  void* active_queue[2];                                                      \
  void* reserved[4];                                                          \
  UV_REQ_PRIVATE_FIELDS          

struct uv_fs_s {
  UV_REQ_FIELDS
  uv_fs_type fs_type;
  uv_loop_t* loop;
  uv_fs_cb cb;
  ssize_t result;
  void* ptr;
  const char* path;
  uv_stat_t statbuf;  /* Stores the result of uv_fs_stat() and uv_fs_fstat(). */
  UV_FS_PRIVATE_FIELDS
};

*)
let data = field uv_fs "data" (ptr void)
let uv_req_type = field uv_fs "type" int (* TODO enum *)
let active_queue = field uv_fs "active_queue" (array 2 (ptr void))
let reserved = field uv_fs "reserved" (array 4 (ptr void))
(* TODO UV_REQ_PRIVATE_FIELDS currently not defined for any platforms *)
let fs_type = field uv_fs "fs_type" int (* TODO enum *)
let uv_fs_uv_loop = field uv_fs "uv_fs_uv_loop" uv_loop (* TODO naming *)
let cb = field uv_fs "cb" (funptr uv_fs_cb) (* TODO I think this is just type uv_fs_cb and NOT funptr? *)
let result = field uv_fs "result" int (* TODO should be ssize_t *)
let uv_fs_ptr = field uv_fs "uv_fs_ptr" (ptr void)
let path = field uv_fs "path" string
let statbuf = field uv_fs "statbuf" uv_stat
(* TODO UV_FS_PRIVATE_FIELDS currently not defined for any platforms *)
let () = seal uv_fs

let uv_fs_open =
  foreign "uv_fs_open" (uv_loop @-> ptr uv_fs @-> string @-> int (* flags *) @-> int (* mode *) @-> funptr uv_fs_cb @-> returning int)
