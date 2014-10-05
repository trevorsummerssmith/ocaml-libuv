open OUnit
open Ctypes

let assert_not_equal = assert_equal ~cmp:( <> )

let mk_tmpfile contents : string =
  let (tmpfile_name, chan) = Filename.open_temp_file "foo" "txt" in
  output_string chan contents;
  close_out chan;
  tmpfile_name

let mkdtemp () : string =
  let tmpdir = Filename.temp_file "foo" ".tmp" in
  Unix.unlink tmpdir;
  Unix.mkdir tmpdir 0o755;
  tmpdir

let test_fs_stat _ =
  let cb fs =
    let stats : Uv.stat = Uv.FS.statbuf fs in
    assert_equal stats.st_size (Int64.of_int 5);
    (* Hard to say what the create time of the file is but it shouldn't be 0. *)
    assert_not_equal stats.st_birthtim.tv_sec Int64.zero
  in
  let filename = mk_tmpfile "hello" in
  let fs = Uv.FS.stat filename ~cb:cb in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  assert_equal (Uv.FS.path fs) filename;
  Unix.unlink filename

let test_blocking_fs_stat _ =
  (* Same as above, but make sure that sync call works *)
  let filename = mk_tmpfile "boo" in
  let fs = Uv.FS.stat filename in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  let stats = Uv.FS.statbuf fs in
  assert_equal stats.st_size (Int64.of_int 3);
  assert_equal (Uv.FS.path fs) filename;
  Unix.unlink filename

let test_fs_fstat _ =
  let filename = mk_tmpfile "boo" in
  let fd = ref 0 in
  let rec open_callback request =
    fd := Int64.to_int (Uv.FS.result request);
    let _ = Uv.FS.fstat !fd ~cb:fstat_callback in ()
  and fstat_callback request =
    let stats = Uv.FS.statbuf request in
    assert_equal stats.st_size (Int64.of_int 3);
    let _ = Uv.FS.close !fd ~cb:close_callback in ()
  and close_callback _ =
    Unix.unlink filename
  in
  let _ = Uv.FS.openfile filename 0 ~cb:open_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_fstat _ =
  let filename = mk_tmpfile "boo" in
  let open_request = Uv.FS.openfile filename 0 in
  let fd = Int64.to_int (Uv.FS.result open_request) in
  let fstat_request = Uv.FS.fstat fd in
  let stats = Uv.FS.statbuf fstat_request in
  assert_equal stats.st_size (Int64.of_int 3);
  Unix.unlink filename

let test_fs_lstat _ =
  let filename = mk_tmpfile "boo" in
  let tmpdir = mkdtemp () in
  let linkpath = (Filename.concat tmpdir "link") in
  Unix.symlink filename linkpath;
  let lstat_callback request =
    let stats = Uv.FS.statbuf request in
    assert_not_equal stats.st_size (Int64.of_int 3);
    assert_equal (Uv.FS.path request) linkpath;
    Unix.unlink linkpath;
    Unix.rmdir tmpdir;
    Unix.unlink filename
  in
  let _ = Uv.FS.lstat linkpath ~cb:lstat_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_lstat _ =
  let filename = mk_tmpfile "boo" in
  let tmpdir = mkdtemp () in
  let linkpath = (Filename.concat tmpdir "link") in
  Unix.symlink filename linkpath;
  let fs = Uv.FS.lstat linkpath in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  let stats = Uv.FS.statbuf fs in
  assert_not_equal stats.st_size (Int64.of_int 3);
  assert_equal (Uv.FS.path fs) linkpath;
  Unix.unlink linkpath;
  Unix.rmdir tmpdir;
  Unix.unlink filename

let test_fs_read _ =
  let test_string = "test" in
  let fd = ref 0 in
  let rec open_callback request =
    fd := Int64.to_int (Uv.FS.result request);
    let _ =
      Uv.FS.read !fd ~cb:read_callback in ()
  and read_callback request =
    let buf = Uv.FS.buf request in
    let _ = Uv.FS.close !fd in
    assert_equal (Uv.FS.string_of_iobuf buf) "test"
  in
  let filename = mk_tmpfile test_string in
  let _ = Uv.FS.openfile filename 0 ~cb:open_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  Unix.unlink filename

let test_blocking_fs_read _ =
  let test_string = "test" in
  let filename = mk_tmpfile test_string in
  let open_request = Uv.FS.openfile filename 0 in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  let fd = Int64.to_int (Uv.FS.result open_request) in
  let read_request = Uv.FS.read fd in
  let buf = Uv.FS.buf read_request in
  assert_equal (Uv.FS.string_of_iobuf buf) "test";
  Unix.unlink filename

(* TODO: put these somewhere more appropriate *)
let o_creat = 0o100
let o_wronly = 0o1
let o_trunc = 0o1000

let test_fs_write _ =
  let filename = mk_tmpfile "" in
  let fd = ref 0 in
  let rec open_callback request =
    fd := Int64.to_int (Uv.FS.result request);
    let buf = (Uv.FS.iobuf_of_string "test") in
    let _ = Uv.FS.write !fd buf ~cb:write_callback in ()
  and write_callback _ =
    let _ = Uv.FS.close !fd ~cb:close_callback in ()
  and close_callback _ =
    let input_channel = open_in filename in
    let data = input_line input_channel in
    assert_equal "test" data;
    Unix.unlink filename
  in
  let flags = (o_creat lor o_wronly lor o_trunc) in
  let _ = Uv.FS.openfile filename flags ~cb:open_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_write _ =
  let filename = mk_tmpfile "" in
  let flags = (o_creat lor o_wronly lor o_trunc) in
  let open_request = Uv.FS.openfile filename flags in
  let fd = Int64.to_int (Uv.FS.result open_request) in
  let _ = Uv.FS.write fd (Uv.FS.iobuf_of_string "test") in
  let _ = Uv.FS.close fd in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  let input_channel = open_in filename in
  let data = input_line input_channel in
  assert_equal "test" data;
  Unix.unlink filename

let test_fs_unlink _ =
  let filename = mk_tmpfile "" in
  let unlink_callback _ =
    assert_bool "File exists after unlink" (not (Sys.file_exists filename));
  in
  let _ = Uv.FS.unlink filename ~cb:unlink_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_unlink _ =
  let filename = mk_tmpfile "" in
  let _ = Uv.FS.unlink filename in
  assert_bool "File exists after unlink" (not (Sys.file_exists filename))

let test_fs_mkdir _ =
  let temp_dir = mkdtemp () in
  let target_dir_path = (Filename.concat temp_dir "test_dir") in
  let mkdir_callback _ =
    assert_bool "Dir" (Sys.file_exists target_dir_path &&
                       Sys.is_directory target_dir_path);
    Unix.rmdir target_dir_path;
    Unix.rmdir temp_dir
  in
  let _ = Uv.FS.mkdir target_dir_path ~cb:mkdir_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_mkdir _ =
  let temp_dir = mkdtemp () in
  let target_dir_path = (Filename.concat temp_dir "test_dir") in
  let _ = Uv.FS.mkdir target_dir_path in
  assert_bool "Dir" (Sys.file_exists target_dir_path &&
                     Sys.is_directory target_dir_path);
  Unix.rmdir target_dir_path;
  Unix.rmdir temp_dir

let test_fs_mkdtemp _ =
  let temp_dir = mkdtemp () in
  let template = (Filename.concat temp_dir "lalaXXXXXX") in
  let mkdtemp_callback request =
    let dir_path = Uv.FS.path request in
    assert_bool "is dir" (Sys.file_exists dir_path &&
                          Sys.is_directory dir_path);
    let prefix_len = (String.length template) - 6 in
    let prefix str = Str.first_chars str prefix_len in
    assert_bool "dir name" (prefix dir_path = prefix template);
    Unix.rmdir dir_path;
    Unix.rmdir temp_dir
  in
  let _ = Uv.FS.mkdtemp template ~cb:mkdtemp_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_mkdtemp _ =
  let temp_dir = mkdtemp () in
  let template = (Filename.concat temp_dir "lalaXXXXXX") in
  let mkdtemp_request = Uv.FS.mkdtemp template in
  let dir_path = Uv.FS.path mkdtemp_request in
  assert_bool "is dir" (Sys.file_exists dir_path && Sys.is_directory dir_path);
  let prefix_len = (String.length template) - 6 in
  let prefix str = Str.first_chars str prefix_len in
  assert_bool "dir name" (prefix dir_path = prefix template);
  Unix.rmdir dir_path;
  Unix.rmdir temp_dir

let test_fs_rmdir _ =
  let temp_dir = mkdtemp () in
  let rmdir_callback _ =
    assert_bool "dir gone" (not (Sys.file_exists temp_dir))
  in
  let _ = Uv.FS.rmdir temp_dir ~cb:rmdir_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_rmdir _ =
  let temp_dir = mkdtemp () in
  let _ = Uv.FS.rmdir temp_dir in
  assert_bool "dir gone" (not (Sys.file_exists temp_dir))

let test_fs_rename _ =
  let temp_dir = mkdtemp () in
  let sourcepath = mk_tmpfile "test" in
  let destpath = Filename.concat temp_dir "target" in
  let rename_callback _ =
    assert_bool "original file gone" (not (Sys.file_exists sourcepath));
    assert_bool "new file present" (Sys.file_exists destpath);
    let input_channel = open_in destpath in
    let data = input_line input_channel in
    assert_equal "test" data;
    Unix.unlink destpath;
    Unix.rmdir temp_dir
  in
  let _ = Uv.FS.rename sourcepath destpath ~cb:rename_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in ()

let test_blocking_fs_rename _ =
  let temp_dir = mkdtemp () in
  let sourcepath = mk_tmpfile "test" in
  let destpath = Filename.concat temp_dir "target" in
  let _ = Uv.FS.rename sourcepath destpath in
  assert_bool "original file gone" (not (Sys.file_exists sourcepath));
  assert_bool "new file present" (Sys.file_exists destpath);
  let input_channel = open_in destpath in
  let data = input_line input_channel in
  assert_equal "test" data;
  Unix.unlink destpath;
  Unix.rmdir temp_dir

let suite =
  "fs_suite">:::
    [
      "fs_stat">::test_fs_stat;
      "blocking_fs_stat">::test_blocking_fs_stat;
      "fs_fstat">::test_fs_fstat;
      "blocking_fs_fstat">::test_blocking_fs_fstat;
      "fs_lstat">::test_fs_lstat;
      "blocking_fs_lstat">::test_blocking_fs_lstat;
      "fs_read">::test_fs_read;
      "blocking_fs_read">::test_blocking_fs_read;
      "fs_write">::test_fs_write;
      "blocking_fs_write">::test_blocking_fs_write;
      "fs_unlink">::test_fs_unlink;
      "blocking_fs_unlink">::test_blocking_fs_unlink;
      "fs_mkdir">::test_fs_mkdir;
      "blocking_fs_mkdir">::test_blocking_fs_mkdir;
      "fs_mkdtemp">::test_fs_mkdtemp;
      "blocking_fs_mkdtemp">::test_blocking_fs_mkdtemp;
      "fs_rmdir">::test_fs_rmdir;
      "blocking_fs_rmdir">::test_blocking_fs_rmdir;
      "fs_rename">::test_fs_rename;
      "blocking_fs_rename">::test_blocking_fs_rename;
    ]
