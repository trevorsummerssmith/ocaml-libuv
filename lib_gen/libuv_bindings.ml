open Ctypes

module C(F : Cstubs.FOREIGN) =
struct
  
  (**
     The first part of this giant file defines all of the types.
     These types need to be in here because the funptr type is defined
     in the Cstubs.FOREIGN module.
     
     The second part of the file defines the functions.

     Maybe later we'll split this up.

     NB the order the structs are sealed in matters.
     If struct a references struct b (ie has a non-pointer field to b)
     and struct b is not sealed you will receive a
     "Fatal error: exception Static.IncompleteType" when running libuv_bindgen
  *)

  (* types first, then callbacks, then structure fields *)

  (* TODO figure out what to do with this?*)
  type uv_sockaddr
  let uv_sockaddr : uv_sockaddr structure typ = structure "sockaddr"
  let sa_len = field uv_sockaddr "sa_len" uint8_t
  let sa_family = field uv_sockaddr "sa_family" uint8_t (* TODO typedef *)
  let sa_data = field uv_sockaddr "sa_data" (array 14 char)
  let () = seal uv_sockaddr

  type uv_sockaddr_in
  let uv_sockaddr_in : uv_sockaddr_in structure typ = structure "sockaddr_in"
  let sin_len = field uv_sockaddr_in "sin_len" uint8_t
  let sin_family = field uv_sockaddr_in "sin_family" uint8_t (* TODO Type *)
  let sin_data = field uv_sockaddr_in "sa_data" (array 14 char) (* XXX *)
  let () = seal uv_sockaddr_in
  (*let sin_port = field uv_sockaddr_in "sin_port" uint16_t (* TODO xplatform type *)
  let sin_addr = field uv_sockaddr_in "sin_addr" *)
  let uv_ip4_addr = F.foreign "uv_ip4_addr"
      (string @-> int @-> ptr uv_sockaddr_in @-> returning int)
  (* END *)

  (* PLATFORM SPECIFIC TYPES *)
  type uv__io
  let uv__io : uv__io structure typ = structure "uv__io_t"
  (* END PLATFORM SPECIFIC TYPES *)

  (* uv_loop *)
  type uv_loop = unit ptr
  let uv_loop : uv_loop typ = ptr void

  (* uv_buf *)
  type uv_buf
  let uv_buf : uv_buf structure typ = structure "uv_buf_t"
  let _uv_buf_base = field uv_buf "base" (ptr char) (* bigarray *)
  let _uv_buf_len = field uv_buf "len" size_t
  let () = seal uv_buf (* TODO this is a platform dependent type *)

  (* uv_handle *)
  type uv_handle
  let uv_handle : uv_handle structure typ = structure "uv_handle_s"
  let uv_close_cb = ptr uv_handle @-> returning void
  let uv_alloc_cb = ptr uv_handle @-> size_t @-> ptr uv_buf @-> returning void

  let add_handle_fields s =
    let ( -: ) ty label = field s label ty in
    let data = ptr void -: "data" in
    let loop = uv_loop -: "loop" in
    let handle_type = int -: "type" in
    let close_cb = Foreign.funptr uv_close_cb -: "close_cb" in
    let handle_queue = (array 2 (ptr void)) -: "handle_queue" in
    let reserved = (array 4 (ptr void)) -: "reserved" in
    (* UV_HANDLE_PRIVATE_FIELDS for unix XXX TODO *)
    let next_closing = ptr uv_handle -: "next_closing" in (* TODO check type *)
    let flags = uint -: "flags" in
    (* END*)
    (data, loop, handle_type, close_cb, handle_queue, reserved, next_closing, flags)

  let _ = add_handle_fields uv_handle
  let () = seal uv_handle

  (* uv_stream *)
  type uv_stream
  let uv_stream : uv_stream structure typ = structure "uv_stream_s"
  let uv_read_cb = ptr uv_stream @-> PosixTypes.ssize_t
                   @-> ptr uv_buf @-> returning void

  (* uv_tcp *)
  type uv_tcp
  let uv_tcp : uv_tcp structure typ = structure "uv_tcp_s"

  (* uv_shutdown *)
  type uv_shutdown
  let uv_shutdown : uv_shutdown structure typ = structure "uv_shutdown_s"

  (* uv_write *)
  type uv_write_t
  let uv_write_t : uv_write_t structure typ = structure "uv_write_s"

  (* uv_connect *)
  type uv_connect
  let uv_connect : uv_connect structure typ = structure "uv_connect_s"

  (* Callbacks *)
  let uv_connection_cb = ptr uv_stream @-> int @-> returning void
  (* Platform specific callbacks (Unix) *)
  let uv__io_cb = uv_loop @-> ptr uv__io @-> uint @-> returning void

  (* Structure Fields *)

  (* uv__io *)
  let make_uv__io_fields s =
    let ( -: ) ty label = field s label ty in    
    let cb = field uv__io "cb" (Foreign.funptr uv__io_cb) in
    let pending_queue = (array 2 (ptr void)) -: "pending_queue" in
    let watcher_queue = (array 2 (ptr void)) -: "watcher_queue" in
    let pevents = uint -: "pevents" in
    let events = uint -: "events" in
    let fd = int -: "fd" in
    (* UV_IO_PRIVATE_PLATFORM_FIELDS darwin TODO (for linux comment these out) *)
    let rcount = int -: "rcount" in
    let wcount = int -: "wcount" in
    (* END *)
    (cb, pending_queue, watcher_queue, pevents, events, fd, rcount, wcount)
  let _ = make_uv__io_fields uv__io
  let () = seal uv__io

  let add_stream_fields s =
    let ( -: ) ty label = field s label ty in
    let write_queue_size = size_t -: "write_queue_size" in
    let alloc_cb = Foreign.funptr uv_alloc_cb -: "alloc_cb" in
    let read_cb = Foreign.funptr uv_read_cb -: "read_cb" in
    (* UV_STREAM_PRIVATE_FIELDS for unix XXX TODO *)
    let connect_req = ptr uv_connect -: "connect_req" in
    let shutdown_req = ptr uv_shutdown -: "shutdown_req" in
    let io_watcher = uv__io -: "io_watcher" in
    let write_queue = (array 2 (ptr void)) -: "write_queue" in
    let write_completed_queue = (array 2 (ptr void)) -: "write_completed_queue" in
    let connection_cb = Foreign.funptr uv_connection_cb -: "connection_cb" in
    let delayed_error = int -: "delayed_error" in
    let accepted_fd = int -: "accepted_fd" in
    let queued_fds = ptr void -: "queued_fds" in
    (* UV_STREAM_PRIVATE_PLATFORM_FIELDS darwin TODO *)
    let select = ptr void -: "select" in
    (* END *)
    (* END *)
    (write_queue_size, alloc_cb, read_cb,
     connect_req, shutdown_req, io_watcher, write_queue, write_completed_queue,
     connection_cb, delayed_error, accepted_fd, queued_fds, select)
  let _ = add_handle_fields uv_stream
  let _ = add_stream_fields uv_stream

  let () = seal uv_stream

  (* uv_tcp *)
  let _ = add_handle_fields uv_tcp
  let _ = add_stream_fields uv_tcp
  (* TODO private *)
  let () = seal uv_tcp

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

  (* uv_req *)
  let add_req_fields s =
    let ( -: ) ty label = field s label ty in
    let data          = ptr void -: "data" in
    let req_type      = long -: "type" in
    let active_queue  = (array 2 (ptr void)) -: "active_queue" in
    let reserved      = (array 4 (ptr void)) -: "reserved" in
    (data, req_type, active_queue, reserved) (* TODO private fields *)

  (* uv_shutdown *)
  let uv_shutdown_cb = ptr uv_shutdown @-> int @-> returning void
  let _ = add_req_fields uv_shutdown
  let _handle = field uv_shutdown "handle" (ptr uv_stream)
  let _shutdown_cb = field uv_shutdown "cb" (Foreign.funptr uv_shutdown_cb)
  let () = seal uv_shutdown (* TODO private *)

  (* uv_write *)
  let uv_write_cb = ptr uv_write_t @-> int @-> returning void
  let add_write_req_fields s =
    let ( -: ) ty label = field s label ty in
    let cb = Foreign.funptr uv_write_cb -: "cb" in
    let send_handle = ptr uv_stream -: "send_handle" in
    let handle = ptr uv_stream -: "handle" in (* TODO do these need accessors? *)
    (* UV_WRITE_PRIVATE_FIELDS for unix *)
    let queue = array 2 (ptr void) -: "queue" in
    let write_index = uint -: "write_index" in
    let bufs = ptr uv_buf -: "bufs" in
    let nbufs = uint -: "nbufs" in
    let error = int -: "error" in
    let bufsml = array 4 uv_buf -: "bufsml" in
    (* END *)
    (cb, send_handle, handle, queue, write_index, bufs, nbufs, error, bufsml)
  let _ = add_req_fields uv_write_t
  let _ = add_write_req_fields uv_write_t
  let () = seal uv_write_t

  (* uv_connect *)
  let uv_connect_cb = ptr uv_connect @-> ptr uv_stream @-> int @-> returning void
  let _ = add_req_fields uv_connect
  let _connect_cb = field uv_connect "cb" (Foreign.funptr uv_connect_cb)
  let _handle = field uv_connect "handle" (ptr uv_stream)
  (* UV_CONNECT_PRIVATE_FIELDS unix TODO *)
  let _queue = field uv_connect "queue" (array 2 (ptr void))
  (* END *)
  let () = seal uv_connect

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

  (* uv_dirent *)
  type uv_dirent
  let uv_dirent : uv_dirent structure typ = structure "uv_dirent_s"

  let ( -: ) ty label = field uv_dirent label ty
  let _name = string -: "name"
  let _type = long -: "type"
  let () = seal uv_dirent

  (* Begin functions *)

  (* uv_handle functions *)
  let uv_close = F.foreign "uv_close"
      (ptr uv_handle @-> Foreign.funptr_opt uv_close_cb @-> returning void)

  (* uv_stream functions *)
  let uv_listen = F.foreign "uv_listen"
      (ptr uv_stream @-> int @-> Foreign.funptr_opt uv_connection_cb @-> returning int)

  let uv_accept = F.foreign "uv_accept"
      (ptr uv_stream @-> ptr uv_stream @-> returning int)

  let uv_read_start = F.foreign "uv_read_start"
      (* TODO is this alloc cb optional? *)
      (ptr uv_stream @-> Foreign.funptr uv_alloc_cb @->
       Foreign.funptr_opt uv_read_cb @-> returning int)

  let uv_write = F.foreign "uv_write"
      (* TODO should the ptr buf_t be array buf_t? *)
      (ptr uv_write_t @-> ptr uv_stream @-> ptr uv_buf @-> uint @->
       Foreign.funptr_opt uv_write_cb @-> returning int)

  (* tcp functions *)
  let uv_tcp_init = F.foreign "uv_tcp_init"
      (uv_loop @-> ptr uv_tcp @-> returning int)

  let uv_tcp_bind = F.foreign "uv_tcp_bind"
      (ptr uv_tcp @-> ptr uv_sockaddr @-> uint @-> returning int)

  (* uv_loop functions *)
  let uv_default_loop = F.foreign "uv_default_loop" (void @-> returning uv_loop)

  let uv_run = F.foreign "uv_run" (uv_loop @-> int @-> returning int)

  (* uv_fs functions *)
  let uv_fs_req_cleanup = F.foreign "uv_fs_req_cleanup"
      (ptr uv_fs @-> returning void)

  let uv_fs_close = F.foreign "uv_fs_close"
      (uv_loop @-> ptr uv_fs @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_open = F.foreign "uv_fs_open"
      (uv_loop @-> ptr uv_fs @-> string @-> int @->
       int @-> Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_read = F.foreign "uv_fs_read"
      (uv_loop @-> ptr uv_fs @-> int @-> ptr uv_buf @->
       int @-> long @-> Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_unlink = F.foreign "uv_fs_unlink"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_write = F.foreign "uv_fs_write"
      (uv_loop @-> ptr uv_fs @-> int @-> ptr uv_buf @->
       int @-> long @-> Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_mkdir = F.foreign "uv_fs_mkdir"
      (uv_loop @-> ptr uv_fs @-> string @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_mkdtemp = F.foreign "uv_fs_mkdtemp"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_rmdir = F.foreign "uv_fs_rmdir"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  (* Scandir is not present until 1.0.0, which I don't have installed.
   * let uv_fs_scandir = F.foreign "uv_fs_scandir"
   *     (uv_loop @-> ptr uv_fs @-> string @-> int @->
   *      Foreign.funptr_opt uv_fs_cb @-> returning int)
   *
   * let uv_fs_scandir_next = F.foreign "uv_fs_scandir_next"
   *     (ptr uv_fs @-> ptr uv_dirent @-> returning int) *)

  let uv_fs_stat = F.foreign "uv_fs_stat"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_fstat = F.foreign "uv_fs_fstat"
      (uv_loop @-> ptr uv_fs @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_lstat = F.foreign "uv_fs_lstat"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_rename = F.foreign "uv_fs_rename"
      (uv_loop @-> ptr uv_fs @-> string @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_fsync = F.foreign "uv_fs_fsync"
      (uv_loop @-> ptr uv_fs @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_fdatasync = F.foreign "uv_fs_fdatasync"
      (uv_loop @-> ptr uv_fs @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_ftruncate = F.foreign "uv_fs_ftruncate"
      (uv_loop @->ptr uv_fs @-> int @-> int64_t @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_sendfile = F.foreign "uv_fs_sendfile"
      (uv_loop @-> ptr uv_fs @-> int @-> int @->
       int64_t @-> size_t @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_chmod = F.foreign "uv_fs_chmod"
      (uv_loop @-> ptr uv_fs @-> string @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_fchmod = F.foreign "uv_fs_fchmod"
      (uv_loop @-> ptr uv_fs @-> int @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_utime = F.foreign "uv_fs_utime"
      (uv_loop @-> ptr uv_fs @-> string @-> double @-> double @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_futime = F.foreign "uv_fs_futime"
      (uv_loop @-> ptr uv_fs @-> int @-> double @-> double @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_link = F.foreign "uv_fs_link"
      (uv_loop @-> ptr uv_fs @-> string @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_symlink = F.foreign "uv_fs_symlink"
      (uv_loop @-> ptr uv_fs @-> string @-> string @-> int @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_readlink = F.foreign "uv_fs_readlink"
      (uv_loop @-> ptr uv_fs @-> string @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_chown = F.foreign "uv_fs_chown"
      (uv_loop @-> ptr uv_fs @-> string @->
       PosixTypes.uid_t @-> PosixTypes.gid_t @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)

  let uv_fs_fchown = F.foreign "uv_fs_fchown"
      (uv_loop @-> ptr uv_fs @-> int @->
       PosixTypes.uid_t @-> PosixTypes.gid_t @->
       Foreign.funptr_opt uv_fs_cb @-> returning int)
end
