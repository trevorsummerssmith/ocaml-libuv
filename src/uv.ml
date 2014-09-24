open Ctypes
open Foreign

(* buffer -- TODO platform dependent uv-unix.h
typedef struct uv_buf_t {
  char* base;
  size_t len;
} uv_buf_t;
*)
type uv_buf
let uv_buf : uv_buf structure typ = structure "uv_buf"
let uv_buf_base = field uv_buf "uv_buf_base" string
let uv_buf_len = field uv_buf "uv_buf_len" size_t
let () = seal uv_buf

(* timespec *)

type uv_timespec
let uv_timespec : uv_timespec structure typ = structure "uv_timespec"
let tv_sec = field uv_timespec "tv_sec" long
let tv_nsec = field uv_timespec "tv_nsec" long
let () = seal uv_timespec

(*
Examples of call back https://github.com/ocamllabs/ocaml-ctypes/blob/master/examples/fts/foreign/fts.ml
*)

module Loop =
  struct
    type uv_loop = unit ptr
    let uv_loop : uv_loop typ = ptr void
    type t = uv_loop
    type run_mode = RunDefault | RunOnce | RunNoWait

    let run_mode_to_int = function
	RunDefault -> 0
      | RunOnce -> 1
      | RunNoWait -> 2

    let default_loop () =
      let _default_loop =
	foreign "uv_default_loop" (void @-> returning uv_loop)
      in
      _default_loop ()

    let run loop run_mode =
      let f = foreign "uv_run" (uv_loop @-> int @-> returning int)
      in
      f loop (run_mode_to_int run_mode)
  end

(* threadpool.h -- uv__work
struct uv__work {
  void ( *work)(struct uv__work *w);
  void ( *done)(struct uv__work *w, int status);
  struct uv_loop_s* loop;
  void* wq[2];
};
*)
type uv__work (* we'll keep their convention of 2 underscores? *)
let uv__work : uv__work structure typ = structure "uv__work"
let uv__work_work_cb = ptr uv__work @-> returning void
let uv__work_done_cb = ptr uv__work @-> int @-> returning void

let uv__work_work = field uv__work "uv__work_work" (funptr uv__work_work_cb)
let uv__work_done = field uv__work "uv__work_done" (funptr uv__work_done_cb)
let uv__work_loop = field uv__work "uv__work_loop" Loop.uv_loop
let uv__work_wq = field uv__work "uv__work_wq" (array 2 (ptr void))
let () = seal uv__work

(* Stat *)
(*

typedef struct {
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
} uv_stat_t;

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
let st_mtim = field uv_stat "st_mtim" uv_timespec
let st_ctim = field uv_stat "st_ctim" uv_timespec
let st_birthtim = field uv_stat "st_birthtim" uv_timespec
let () = seal uv_stat

module Request =
  struct
    type 'a t = 'a
    let cancel req = failwith "Not Implemented"
  end

type request_type =
    Unknown
   | Req
   | Connect
   | Write
   | Shutdown
   | UDPSend
   | FS
   | Work
   | GetAddrInfo
   | GetNameInfo
   | Private
   | Max

let request_type_to_int = function
    Unknown -> 0
   | Req -> 1
   | Connect -> 2
   | Write -> 3
   | Shutdown -> 4
   | UDPSend -> 5
   | FS -> 6
   | Work -> 7
   | GetAddrInfo -> 8
   | GetNameInfo -> 9
   | Private -> 10
   | Max -> 11

type fs_type =
    Unknown
  | Custom
  | Open
  | Close
  | Read
  | Write
  | Sendfile
  | Stat
  | LState
  | FStat
  | FTruncate
  | UTime
  | FUTime
  | Chmod
  | FChmod
  | FSync
  | FDatasync
  | Unlink
  | Rmdir
  | Mkdir
  | Mkdtemp
  | Rename
  | Readdir
  | Link
  | Symlink
  | Readlink
  | Chown
  | FChown

let fs_type_to_int = function
    Unknown -> -1
  | Custom -> 0
  | Open -> 1
  | Close -> 2
  | Read -> 3
  | Write -> 4
  | Sendfile -> 5
  | Stat -> 6
  | LState -> 7
  | FStat -> 8
  | FTruncate -> 9
  | UTime -> 10
  | FUTime -> 11
  | Chmod -> 12
  | FChmod -> 13
  | FSync -> 14
  | FDatasync -> 15
  | Unlink -> 16
  | Rmdir -> 17
  | Mkdir -> 18
  | Mkdtemp -> 19
  | Rename -> 20
  | Readdir -> 21
  | Link -> 22
  | Symlink -> 23
  | Readlink -> 24
  | Chown -> 25
  | FChown -> 26

module FS =
  struct
    type uv_fs
    let uv_fs : uv_fs structure typ = structure "uv_fs"
    let uv_fs_cb = ptr uv_fs @-> returning void

    type fs = { req : uv_fs structure ptr }
    type t = fs Request.t

    let ( -: ) ty label = field uv_fs label ty
    let _data          = ptr void -: "_data"
    let _uv_req_type   = long -: "_type" (* readonly TODO ENUM *)
    let _active_queue  = (array 2 (ptr void)) -: "_active_queue"
    let _fs_type       = long -: "_fs_type" (* TODO ENUM *)
    let _uv_fs_uv_loop = Loop.uv_loop -: "_uv_fs_uv_loop" (* TODO naming *)
    let _cb            = (funptr uv_fs_cb) -: "_cb"  (* TODO I think this is just type uv_fs_cb and NOT funptr? *)
    let _result        = PosixTypes.ssize_t -: "_result"
    let _uv_fs_ptr     = ptr void -: "_uv_fs_ptr"
    let _path          = string -: "_path"
    let _statbuf       = uv_stat -: "_statbuf"
    (* UV_FS_PRIVATE_FIELDS for Unix below *)
    let _new_path      = string -: "_new_path"
    let _file          = int -: "_file" (* TODO type is platform dependent *)
    let _flags         = int -: "_flags"
    let _mode          = PosixTypes.mode_t -: "_mode"
    let _nbufs         = uint -: "_nbufs"
    let _bufs          = ptr uv_buf -: "_bufs"
    let _off           = PosixTypes.off_t -: "_off"
    let _uid           = PosixTypes.uid_t -: "_uid"
    let _gid           = PosixTypes.gid_t -: "_gid"
    let _atime         = double -: "_atime"
    let _mtime         = double -: "_mtime"
    let _work_req      = uv__work -: "_work_req"
    let _bufsml        = (array 4 uv_buf) -: "_bufsml"
    let () = seal uv_fs

    let uv_fs_stat =
      foreign "uv_fs_stat" (Loop.uv_loop @-> ptr uv_fs @-> string @-> funptr uv_fs_cb @-> returning int)

    let stat (loop : Loop.t) (filename : string) (cb : t -> unit) =
      let data = make uv_fs in
      let addy = addr data in
      let guy : fs Request.t = {req = addy} in
      let cb' = (fun _uv_fs -> cb guy) in
      let _ = uv_fs_stat loop addy filename cb' in (* TODO raise exception *)
      guy

  (* Accessors *)
    let path fs = getf !@(fs.req) _path

  end

(* Loop *)
(*type uv_loop = unit ptr
let uv_loop : uv_loop typ = ptr void

let uv_default_loop =
  foreign "uv_default_loop" (void @-> returning uv_loop)

let uv_run =
  foreign "uv_run" (uv_loop @-> int @-> returning int)*)
(* TODO should be an enum not an int for second arg *)

(* Files *)



(*let uv_fs_open =
  foreign "uv_fs_open" (Loop.uv_loop @-> ptr uv_fs @-> string @-> int (* flags *) @-> int (* mode *) @-> funptr uv_fs_cb @-> returning int)

let uv_fs_stat =
  foreign "uv_fs_stat" (Loop.uv_loop @-> ptr uv_fs @-> string @-> funptr uv_fs_cb @-> returning int)*)
