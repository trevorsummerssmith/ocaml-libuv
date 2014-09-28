open Ctypes

module C(F : Cstubs.FOREIGN) =
struct
  
  (**
     The first part of this giant file defines all of the types.
     These types need to be in here because the funptr type is defined
     in the Cstubs.FOREIGN module.
     
     The second part of the file defines the functions.

     Maybe later we'll split this up.
  *)

  (* uv_loop *)
  type uv_loop = unit ptr
  let uv_loop : uv_loop typ = ptr void
  
  (* uv_buf *)
  type uv_buf
  let uv_buf : uv_buf structure typ = structure "uv_buf_t"
  let _uv_buf_base = field uv_buf "base" (ptr char) (* bigarray *)
  let _uv_buf_len = field uv_buf "len" size_t
  let () = seal uv_buf (* TODO this is a platform dependent type *)

  (* uv_timespec *)
  type uv_timespec
  let uv_timespec : uv_timespec structure typ = structure "uv_timespec_t"
  let _tv_sec = field uv_timespec "tv_sec" long
  let _tv_nsec = field uv_timespec "tv_nsec" long
  let () = seal uv_timespec

  (* uv__work *)
  type uv__work (* we'll keep their convention of 2 underscores? *)
  let uv__work : uv__work structure typ = structure "uv__work"
  let uv__work_work_cb = ptr uv__work @-> returning void
  let uv__work_done_cb = ptr uv__work @-> int @-> returning void

  let uv__work_work = field uv__work "work" (Foreign.funptr uv__work_work_cb)
  let uv__work_done = field uv__work "done" (Foreign.funptr uv__work_done_cb)
  let uv__work_loop = field uv__work "loop" uv_loop
  let uv__work_wq = field uv__work "wq" (array 2 (ptr void))
  let () = seal uv__work

  (* uv_stat *)
  type uv_stat
  let uv_stat : uv_stat structure typ = structure "uv_stat_t"
  let _st_dev = field uv_stat "st_dev" uint64_t
  let _st_mode = field uv_stat "st_mode" uint64_t
  let _st_nlink = field uv_stat "st_nlink" uint64_t
  let _st_uid = field uv_stat "st_uid" uint64_t
  let _st_gid = field uv_stat "st_gid" uint64_t
  let _st_rdev = field uv_stat "st_rdev" uint64_t
  let _st_ino = field uv_stat "st_ino" uint64_t
  let _st_size = field uv_stat "st_size" uint64_t
  let _st_blksize = field uv_stat "st_blksize" uint64_t
  let _st_blocks = field uv_stat "st_blocks" uint64_t
  let _st_flags = field uv_stat "st_flags" uint64_t
  let _st_gen = field uv_stat "st_gen" uint64_t
  let _st_atim = field uv_stat "st_atim" uv_timespec
  let _st_mtim = field uv_stat "st_mtim" uv_timespec
  let _st_ctim = field uv_stat "st_ctim" uv_timespec
  let _st_birthtim = field uv_stat "st_birthtim" uv_timespec
  let () = seal uv_stat

  (* uv_fs *)
  type uv_fs
  let uv_fs : uv_fs structure typ = structure "uv_fs_s"
  let uv_fs_cb = ptr uv_fs @-> returning void

  let ( -: ) ty label = field uv_fs label ty
  let _data          = ptr void -: "data"
  let _uv_req_type   = long -: "type"
  let _active_queue  = (array 2 (ptr void)) -: "active_queue"
  let _reserved     = (array 4 (ptr void)) -: "reserved"
  let _fs_type       = long -: "fs_type"
  let _uv_fs_uv_loop = uv_loop -: "loop"
  let _cb            = Foreign.funptr uv_fs_cb -: "cb"
  let _result        = PosixTypes.ssize_t -: "result"
  let _uv_fs_ptr     = ptr void -: "ptr"
  let _path          = string -: "path"
  let _statbuf       = uv_stat -: "statbuf"
  (* UV_FS_PRIVATE_FIELDS for Unix below *)
  let _new_path      = string -: "new_path"
  let _file          = int -: "file" (* TODO type is platform dependent *)
  let _flags         = int -: "flags"
  let _mode          = PosixTypes.mode_t -: "mode"
  let _nbufs         = uint -: "nbufs"
  let _bufs          = ptr uv_buf -: "bufs"
  let _off           = PosixTypes.off_t -: "off"
  let _uid           = PosixTypes.uid_t -: "uid"
  let _gid           = PosixTypes.gid_t -: "gid"
  let _atime         = double -: "atime"
  let _mtime         = double -: "mtime"
  let _work_req      = uv__work -: "work_req"
  let _bufsml        = (array 4 uv_buf) -: "bufsml"
  (* end UV_FS_PRIVATE_FIELDS *)
  let () = seal uv_fs

  (* Begin functions *)

  (* uv_loop functions *)
  let uv_default_loop = F.foreign "uv_default_loop" (void @-> returning uv_loop)

  let uv_run = F.foreign "uv_run" (uv_loop @-> int @-> returning int)

  (* uv_fs functions *)
  let uv_fs_open = F.foreign "uv_fs_open"
      (uv_loop @-> ptr uv_fs @-> string @-> int @->
       int @-> Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_close = F.foreign "uv_fs_close"
      (uv_loop @-> ptr uv_fs @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_read = F.foreign "uv_fs_read"
      (uv_loop @-> ptr uv_fs @-> int @-> ptr uv_buf @->
       int @-> long @-> Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_write = F.foreign "uv_fs_write"
      (uv_loop @-> ptr uv_fs @-> int @-> ptr uv_buf @->
       int @-> long @-> Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_stat = F.foreign "uv_fs_stat"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)
end
