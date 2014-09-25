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
let _tv_sec = field uv_timespec "_tv_sec" long
let _tv_nsec = field uv_timespec "_tv_nsec" long
let () = seal uv_timespec

type timespec = {
  tv_sec : int64;
  tv_nsec : int64 (* TODO what type should these be? *)
}

let from_uv_timespec uv_t =
  let tv_sec = Signed.Long.to_int64 (getf uv_t _tv_sec) in
  let tv_nsec = Signed.Long.to_int64 (getf uv_t _tv_nsec) in
  {tv_sec; tv_nsec}


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

let default_loop = Loop.default_loop ()

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

module Request =
  struct
    type 'a t = 'a
    let cancel req = failwith "Not Implemented"
  end

module FS =
  struct
    type uv_fs
    let uv_fs : uv_fs structure typ = structure "uv_fs"
    let uv_fs_cb = ptr uv_fs @-> returning void

    type fs = { req : uv_fs structure ptr }
    type t = fs Request.t

    let ( -: ) ty label = field uv_fs label ty
    let _data          = ptr void -: "_data"
    let _uv_req_type   = long -: "_uv_req_type"
    let _active_queue  = (array 2 (ptr void)) -: "_active_queue"
    let _fs_type       = long -: "_fs_type"
    let _uv_fs_uv_loop = Loop.uv_loop -: "_uv_fs_uv_loop"
    let _cb            = funptr uv_fs_cb -: "_cb"
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
      foreign "uv_fs_stat" (Loop.uv_loop @-> ptr uv_fs @-> string @-> funptr_opt uv_fs_cb @-> returning int)

    let refs = Refcount.create ()
    let ref_incr = Refcount.incr refs
    let ref_decr = Refcount.decr refs

    let make_callback cb =
      (* There's something kind of subtle here:
         we need to pass the Ocaml user's callback function (cb) to libuv, so
         we'll need to wrap the user's function in a method that converts the
         ctype passed to the callback into an OCaml value. Call the ctype
         callback (ie the actual callback called by libuv cb').
         So basically this look likes:

         let cb' arg = cb(make_ctype_into_ocaml_type(arg))

         However we don't want that callback to get gc'd before it is called.
         So we keep track of the callbacks (cb' mind you) in a hashtbl. We add
         cb' to the hash right before passing it to libuv. And we remove cb'
         from the hashtbl right after calling the user's callback, cb.

         make_callback, does all of that. Looks a little dense, not so bad.
       *)
      let rec callback cb _uv_fs =
	let finally () = ref_decr cb in
	let fs = {req=_uv_fs} in
	try cb fs
	with exn -> (* we got an exception. Clear gc ref and re-raise *)
	  (finally ();
	   raise exn)
	finally ()
      in
      ref_incr cb;
      callback cb

    let make_callback_opt = function
	None -> None
      | Some cb -> Some (make_callback cb)

    let stat ?(loop=default_loop) ?cb (filename : string) =
      let data = addr (make uv_fs) in
      let cb' = make_callback_opt cb in
      let _ = uv_fs_stat loop data filename cb' in (* TODO raise exception *)
      {req=data}

  (* Accessors *)
    let path fs = getf !@(fs.req) _path

    let statbuf fs =
      let sb = getf !@(fs.req) _statbuf in
      let f conv field = conv (getf sb field) in
      let i = f Unsigned.UInt64.to_int64 in
      let t = f from_uv_timespec in
      let st_dev = i _st_dev in
      let st_mode = i _st_mode in
      let st_nlink = i _st_nlink in
      let st_uid = i _st_uid in
      let st_gid = i _st_gid in
      let st_rdev = i _st_rdev in
      let st_ino = i _st_ino in
      let st_size = i _st_size in
      let st_blksize = i _st_blksize in
      let st_blocks = i _st_blocks in
      let st_flags = i _st_flags in
      let st_gen = i _st_gen in
      let st_atim = t _st_atim in
      let st_mtim = t _st_mtim in
      let st_ctim = t _st_ctim in
      let st_birthtim = t _st_birthtim in
      {st_dev; st_mode; st_nlink; st_uid; st_gid; st_rdev; st_ino; st_size;
       st_blksize; st_blocks; st_flags; st_gen; st_atim; st_mtim; st_ctim;
       st_birthtim}

  end
