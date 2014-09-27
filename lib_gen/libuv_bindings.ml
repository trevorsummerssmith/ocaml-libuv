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
  let uv_buf : uv_buf structure typ = structure "uv_buf"
  let _uv_buf_base = field uv_buf "uv_buf_base" (ptr char) (* bigarray *)
  let _uv_buf_len = field uv_buf "uv_buf_len" size_t
  let () = seal uv_buf (* TODO this is a platform dependent type *)

  (* uv_timespec *)
  type uv_timespec
  let uv_timespec : uv_timespec structure typ = structure "uv_timespec"
  let _tv_sec = field uv_timespec "_tv_sec" long
  let _tv_nsec = field uv_timespec "_tv_nsec" long
  let () = seal uv_timespec

  (* uv__work *)
  type uv__work (* we'll keep their convention of 2 underscores? *)
  let uv__work : uv__work structure typ = structure "uv__work"
  let uv__work_work_cb = ptr uv__work @-> returning void
  let uv__work_done_cb = ptr uv__work @-> int @-> returning void

  let uv__work_work = field uv__work "uv__work_work" (Foreign.funptr uv__work_work_cb)
  let uv__work_done = field uv__work "uv__work_done" (Foreign.funptr uv__work_done_cb)
  let uv__work_loop = field uv__work "uv__work_loop" uv_loop
  let uv__work_wq = field uv__work "uv__work_wq" (array 2 (ptr void))
  let () = seal uv__work

  (* uv_stat *)
  type uv_stat
  let uv_stat : uv_stat structure typ = structure "uv_stat"
  let _st_dev = field uv_stat "_st_dev" uint64_t
  let _st_mode = field uv_stat "_st_mode" uint64_t
  let _st_nlink = field uv_stat "_st_nlink" uint64_t
  let _st_uid = field uv_stat "_st_uid" uint64_t
  let _st_gid = field uv_stat "_st_gid" uint64_t
  let _st_rdev = field uv_stat "_st_rdev" uint64_t
  let _st_ino = field uv_stat "_st_ino" uint64_t
  let _st_size = field uv_stat "_st_size" uint64_t
  let _st_blksize = field uv_stat "_st_blksize" uint64_t
  let _st_blocks = field uv_stat "_st_blocks" uint64_t
  let _st_flags = field uv_stat "_st_flags" uint64_t
  let _st_gen = field uv_stat "_st_gen" uint64_t
  let _st_atim = field uv_stat "_st_atim" uv_timespec
  let _st_mtim = field uv_stat "_st_mtim" uv_timespec
  let _st_ctim = field uv_stat "_st_ctim" uv_timespec
  let _st_birthtim = field uv_stat "_st_birthtim" uv_timespec
  let () = seal uv_stat

  (* uv_fs *)
  type uv_fs
  let uv_fs : uv_fs structure typ = structure "uv_fs"
  let uv_fs_cb = ptr uv_fs @-> returning void

  let ( -: ) ty label = field uv_fs label ty
  let _data          = ptr void -: "_data"
  let _uv_req_type   = long -: "_uv_req_type"
  let _active_queue  = (array 2 (ptr void)) -: "_active_queue"
  let _fs_type       = long -: "_fs_type"
  let _uv_fs_uv_loop = uv_loop -: "_uv_fs_uv_loop"
  let _cb            = Foreign.funptr uv_fs_cb -: "_cb"
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
