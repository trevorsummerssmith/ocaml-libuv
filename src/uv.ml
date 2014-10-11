open Ctypes
open Foreign

module C = Libuv_bindings.C(Libuv_generated)

type iobuf = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type timespec = {
  tv_sec : int64;
  tv_nsec : int64 (* TODO what type should these be? *)
}

let from_uv_timespec uv_t =
  let tv_sec = Signed.Long.to_int64 (getf uv_t C._tv_sec) in
  let tv_nsec = Signed.Long.to_int64 (getf uv_t C._tv_nsec) in
  {tv_sec; tv_nsec}

module Loop =
struct
  type t = C.uv_loop
  type run_mode = RunDefault | RunOnce | RunNoWait

  let run_mode_to_int = function
      RunDefault -> 0
    | RunOnce -> 1
    | RunNoWait -> 2

  let default_loop = C.uv_default_loop

  let run ?(loop=default_loop()) run_mode = C.uv_run loop (run_mode_to_int run_mode)
end

let default_loop = Loop.default_loop ()

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
  type 'a t = unit ptr

  type write_req
  type write = write_req t

  let cancel req = failwith "Not Implemented"
end

module Handle =
struct
  type 'a t = unit ptr

  let close ?cb handle =
    (* assume handle is a void ptr *)
    let cb' = match cb with None -> None | Some f -> Some (fun x -> f(to_voidp x)) in
    let handle_ptr = from_voidp C.uv_handle handle in
    let _ = C.uv_close handle_ptr cb' in (* TODO exn *)
    ()
end

module Stream =
struct
  type 'a stream
  type 'a t = 'a stream Handle.t

  let refs = Refcount.create ()
  let ref_incr = Refcount.incr refs
  let ref_decr = Refcount.decr refs

  let read_cb_refs = Refcount.create ()
  let read_cb_ref_incr = Refcount.incr read_cb_refs
  let read_cb_ref_decr = Refcount.decr read_cb_refs

  let write_cb_refs = Refcount.create ()
  let write_cb_ref_incr = Refcount.incr write_cb_refs
  let write_cb_ref_decr = Refcount.decr write_cb_refs

  let make_callback (cb : 'a t -> int -> unit) =
    let rec callback cb uv_stream =
      let finally () = ref_decr callback in
      (* This receives a uv_stream but we need a void ptr *)
      let stream : 'a t = to_voidp uv_stream in
      try cb stream
      with exn -> (* we got an exception. Clear gc ref and re-raise *)
        (finally ();
         raise exn)
          finally ()
    in
    ref_incr callback;
    callback cb

  let make_callback_opt = function
      None -> None
    | Some cb -> Some (make_callback cb)

  let make_read_callback (cb : 't -> int -> Buf.t -> unit) =
    let rec callback cb uv_stream size buf =
      let finally () = read_cb_ref_decr cb in
      (* This receives a uv_stream but we need a void ptr *)
      let stream : 'a t = to_voidp uv_stream in
      (* This receives a uv_buf, we need a buf *)
      let ok = (getf (!@buf) C._uv_buf_base) in
      let len = Unsigned.Size_t.to_int (getf (!@buf) C._uv_buf_len) in
      let buf' = bigarray_of_ptr array1 len Bigarray.char ok in
      (* This receives a ssize_t, we need an int *)
      let size' = coerce PosixTypes.ssize_t int64_t size in
      let size' = Signed.Int64.to_int size' in (* TODO coerce is it ok? *)
      try cb stream size' buf'
      with exn -> (* we got an exception. Clear gc ref and re-raise *)
        (finally ();
         raise exn)
          finally ()
    in
    read_cb_ref_incr cb;
    callback cb

  let make_read_callback_opt = function
      None -> None
    | Some cb -> Some (make_read_callback cb)

  let make_write_callback (cb : Request.write -> int -> unit) =
    let rec callback (cb : Request.write -> int -> unit) (req : C.uv_write_t structure ptr) (status : int) =
      let finally () = write_cb_ref_decr callback in
      (* from specific to void  *)
      let req' : Request.write = to_voidp req in
      let v = cb req' in
      try v status
      with exn -> (* we got an exception. Clear gc ref and re-raise *)
        (finally ();
         raise exn)
          finally ()
    in
    write_cb_ref_incr callback;
    callback cb

  let make_write_callback_opt = function
      None -> None
    | Some cb -> Some (make_write_callback cb)

  let listen ?cb stream backlog =
    let stream_ptr = from_voidp C.uv_stream stream in
    let cb' = make_callback_opt cb in
    let _ = C.uv_listen stream_ptr backlog cb' in (* TODO exn. TODO callback *)
    ()

  let accept (server : 'a t) (client : 'a t) =
    let server_ptr = from_voidp C.uv_stream server in
    let client_ptr = from_voidp C.uv_stream client in
    let _ = C.uv_accept server_ptr client_ptr in (* TODO exn *)
    ()

  let alloc_cb handle (suggested_size : PosixTypes.size_t) bufptr =
    (* Allocate suggested_size *)
    let size = Unsigned.Size_t.to_int suggested_size in
    let memory = Bigarray.(Array1.create char c_layout size) in
    let buf = !@bufptr in
    let _ = setf buf C._uv_buf_base (bigarray_start array1 memory) in
    let _ = setf buf C._uv_buf_len suggested_size in
    (* TODO deal with buffers *)
    ()

  let read_start ?cb stream =
    let stream_ptr = from_voidp C.uv_stream stream in
    let cb' = make_read_callback_opt cb in
    let _ = C.uv_read_start stream_ptr alloc_cb cb' in (* TODO exn *)
    ()

  let make_buf_t buf =
    let buf_data = make C.uv_buf in
    let buf_ptr = bigarray_start array1 buf in
    let buf_len = Bigarray.Array1.dim buf in
    let _ = setf buf_data C._uv_buf_base buf_ptr in
    let _ = setf buf_data C._uv_buf_len (Unsigned.Size_t.of_int buf_len) in
    addr buf_data

  let write ?cb stream buf =
    let uv_buf_ptr = make_buf_t buf in
    let nbufs = Unsigned.UInt.one in
    let req = addr (make C.uv_write_t) in
    (* convert from void *)
    let stream_ptr = from_voidp C.uv_stream stream in
    let cb' = make_write_callback_opt cb in
    let _ = C.uv_write req stream_ptr uv_buf_ptr nbufs cb' in
    to_voidp req

end

module Shutdown =
struct
  type shutdown
  type t = shutdown Request.t
end

module FS =
struct
  type fs
  type t = fs Request.t
  type iobuf = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

  let refs = Refcount.create ()
  let ref_incr f = Refcount.incr refs f
  let ref_decr f = Refcount.decr refs f

  let c_to_ocaml data =
    (* Convert from the value we pass to uv_* methods to the FS.t method *)
    to_voidp data

  let ocaml_to_c data =
    (* From FS.t to struct *)
    from_voidp C.uv_fs data

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
      let finally () = ref_decr callback in
      let fs = c_to_ocaml _uv_fs in
      (* If we get an exception clear gc ref and re-raise *)
      let _ =  try cb fs with exn -> finally (); raise exn in
      finally ()
    in
    ref_incr callback;
    callback cb

  let make_callback_opt = function
      None -> None
    | Some cb -> Some (make_callback cb)

  let openfile ?(loop=default_loop) ?cb ?(perm=0o644) (filename : string) flags  =
    let data = addr (make C.uv_fs) in
    let cb' = make_callback_opt cb in
    let _ = C.uv_fs_open loop data filename flags perm cb' in
    c_to_ocaml data

  let close ?(loop=default_loop) ?cb file =
    let data = addr (make C.uv_fs) in
    let cb' = make_callback_opt cb in
    let _ = C.uv_fs_close loop data file cb' in
    c_to_ocaml data

  let read ?(loop=default_loop) ?cb ?(offset=(-1)) file = (* TODO what should offset be? *)
    let data = addr (make C.uv_fs) in
    let cb' = make_callback_opt cb in
    (* Allocate read buffer *)
    let buf_len = 1024 in
    let buf = Bigarray.(Array1.create char c_layout buf_len) in
    let buf_ptr = bigarray_start array1 buf in
    let buf_data = make C.uv_buf in
    let _ = setf buf_data C._uv_buf_base buf_ptr in
    let _ = setf buf_data C._uv_buf_len (Unsigned.Size_t.of_int buf_len) in
    let arr = CArray.make C.uv_buf 1 in
    let _ = CArray.set arr 0 buf_data in  (* TODO may be able to make this simpler *)
    let _ = C.uv_fs_read loop data file (CArray.start arr) 1 (Signed.Long.of_int offset) cb' in
    c_to_ocaml data

  let write ?(loop=default_loop) ?cb ?(offset=(-1)) file buf = (* TODO offset, bufs *)
    let data = addr (make C.uv_fs) in
    let cb' = make_callback_opt cb in
    (* Allocate buf_t structure *)
    let buf_ptr = bigarray_start array1 buf in
    let buf_data = make C.uv_buf in
    let _ = setf buf_data C._uv_buf_base buf_ptr in
    let buf_len = Bigarray.Array1.dim buf in
    let _ = setf buf_data C._uv_buf_len (Unsigned.Size_t.of_int buf_len) in
    (* TODO just passing a single guy here... *)
    let _ = C.uv_fs_write loop data file (addr buf_data) 1 (Signed.Long.of_int offset) cb' in
    c_to_ocaml data

  let stat ?(loop=default_loop) ?cb (filename : string) =
    let data = addr (make C.uv_fs) in
    let cb' = make_callback_opt cb in
    let _ = C.uv_fs_stat loop data filename cb' in (* TODO raise exception *)
    c_to_ocaml data

  (* Accessors *)

  let result fs =
    let fs = ocaml_to_c fs in
    let f = getf !@fs C._result in
    try
      let i = coerce PosixTypes.ssize_t int64_t f in
      Signed.Int64.to_int64 i
    with exn -> Printf.printf "Oh no!\n"; raise exn (* TODO remove this *)

  let path fs =
    let fs = ocaml_to_c fs in
    getf !@fs C._path

  let buf fs =
    let fs = ocaml_to_c fs in
    let b = getf !@fs C._bufs in (* TODO make this type work with win *)
    let data = getf !@b C._uv_buf_base in (* TODO this assumes there is one buf *)
    let len = getf !@b C._uv_buf_len in
    bigarray_of_ptr array1 (Unsigned.Size_t.to_int len) Bigarray.Char data

  let statbuf fs =
    let fs = ocaml_to_c fs in
    let sb = getf !@fs C._statbuf in
    let f conv field = conv (getf sb field) in
    let i = f Unsigned.UInt64.to_int64 in
    let t = f from_uv_timespec in
    let st_dev = i C._st_dev in
    let st_mode = i C._st_mode in
    let st_nlink = i C._st_nlink in
    let st_uid = i C._st_uid in
    let st_gid = i C._st_gid in
    let st_rdev = i C._st_rdev in
    let st_ino = i C._st_ino in
    let st_size = i C._st_size in
    let st_blksize = i C._st_blksize in
    let st_blocks = i C._st_blocks in
    let st_flags = i C._st_flags in
    let st_gen = i C._st_gen in
    let st_atim = t C._st_atim in
    let st_mtim = t C._st_mtim in
    let st_ctim = t C._st_ctim in
    let st_birthtim = t C._st_birthtim in
    {st_dev; st_mode; st_nlink; st_uid; st_gid; st_rdev; st_ino; st_size;
     st_blksize; st_blocks; st_flags; st_gen; st_atim; st_mtim; st_ctim;
     st_birthtim}

end

(* XXX *)
type mysock = C.uv_sockaddr structure ptr
let ip4_addr str_addr port =
  let data = addr (make C.uv_sockaddr_in) in
  let _ = C.uv_ip4_addr str_addr port data in (* TODO exn *)
  coerce (ptr C.uv_sockaddr_in) (ptr C.uv_sockaddr) data

(* END XXX *)

module TCP =
struct
  type tcp
  type t = tcp Stream.t

  let init ?(loop=default_loop) () : t =
    let data = addr (make C.uv_tcp) in
    let _ = C.uv_tcp_init loop data in (* TODO exn *)
    to_voidp data

  let bind tcp (sockaddr : mysock) flags =
    (* tcp is a void ptr *)
    let tcp_ptr = from_voidp C.uv_tcp tcp in
    let _ = C.uv_tcp_bind tcp_ptr sockaddr (Unsigned.UInt.of_int flags) in (* TODO exn *)
    () (* TODO return type? *)
end
