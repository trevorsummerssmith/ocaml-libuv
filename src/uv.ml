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
let uv__work_loop = field uv__work "uv__work_loop" uv_loop
let uv__work_wq = field uv__work "uv__work_wq" (array 2 (ptr void))
let () = seal uv__work

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

// UV_FS_PRIVATE_FIELDS for unix:
 const char *new_path;                                                       \
  uv_file file;                                                               \
  int flags;                                                                  \
  mode_t mode;                                                                \
  unsigned int nbufs;                                                         \
  uv_buf_t* bufs;                                                             \
  off_t off;                                                                  \
  uv_uid_t uid;                                                               \
  uv_gid_t gid;                                                               \
  double atime;                                                               \
  double mtime;                                                               \
  struct uv__work work_req;                                                   \
  uv_buf_t bufsml[4];
};

*)
let data = field uv_fs "data" (ptr void)
let uv_req_type = field uv_fs "type" long (* TODO enum *)
let active_queue = field uv_fs "active_queue" (array 2 (ptr void))
(* TODO UV_REQ_PRIVATE_FIELDS currently not defined for any platforms *)
let fs_type = field uv_fs "fs_type" long (* TODO enum *)
let uv_fs_uv_loop = field uv_fs "uv_fs_uv_loop" uv_loop (* TODO naming *)
let cb = field uv_fs "cb" (funptr uv_fs_cb) (* TODO I think this is just type uv_fs_cb and NOT funptr? *)
let result = field uv_fs "result" PosixTypes.ssize_t
let uv_fs_ptr = field uv_fs "uv_fs_ptr" (ptr void)
let path = field uv_fs "path" string
let statbuf = field uv_fs "statbuf" uv_stat
(* TODO UV_FS_PRIVATE_FIELDS currently not defined for any platforms *)
let new_path = field uv_fs "new_path" string
let file = field uv_fs "file" int (* TODO type is platform dependent *)
let flags = field uv_fs "flags" int
let mode = field uv_fs "mode" PosixTypes.mode_t
let nbufs = field uv_fs "nbufs" uint
let bufs = field uv_fs "bufs" (ptr uv_buf)
let off = field uv_fs "off" PosixTypes.off_t
let uid = field uv_fs "uid" PosixTypes.uid_t (* TODO platform specific uv-unix.h*)
let gid = field uv_fs "gid" PosixTypes.gid_t (* TODO platform specific uv-unix.h*)
let atime = field uv_fs "atime" double
let mtime = field uv_fs "mtime" double
let work_req = field uv_fs "work_req" uv__work
let bufsml = field uv_fs "bufsml" (array 4 uv_buf)
let () = seal uv_fs

let uv_fs_open =
  foreign "uv_fs_open" (uv_loop @-> ptr uv_fs @-> string @-> int (* flags *) @-> int (* mode *) @-> funptr uv_fs_cb @-> returning int)

let uv_fs_stat =
  foreign "uv_fs_stat" (uv_loop @-> ptr uv_fs @-> string @-> funptr uv_fs_cb @-> returning int)
