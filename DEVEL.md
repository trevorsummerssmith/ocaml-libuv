* This is built to work against the current development version of
  libuv -- 0.11.29.

* As few dependencies as possible (no Core)

Notes:
  - A loop is a handle. Most things are handles.
  - There are also requests
  - and random stuff.
  * I think we should have everything be separate modules. This works
    very well, except for the things that are modeled as 'subclasses', eg
    handles and requests. There's only a few functions that take any of these
    toplevel struct types. Because it seems these would be less often used, I
    propose that for these toplevel types (of which there are two) we use an
    algebraic datatype. Now, this is kind of annoying, because it will require
    casting to this type (with a constructor) whenever one wants to use these methods.
    However, I think these are not frequently used methods (I am basing that on nothing
    other than my intuition, so feel free to do some research and googling through github
    to see if that assumption is wrong) so it should be fine. Tradeoff: make the commonly
    used case simple and elegant, less frequently used use case is slightly less elegant.

* I like this thing here: let ( -: ) ty label = field ftsent label ty

* Thoughts on modules:
  - UV
    - version
    - version_string
    - char *uv_strerror(int err)
    - char *uv_err_name(int err)
    - (maybe dunno where these should go):
      uv_setup_args, uv_get_process_title, uv_set_process_title,
      uv_resident_set_memory, uv_uptime, uv_loadavg (see comment doesnt work on windows)
  Handle (all below are handles):
    - uv_is_active
    - uv_is_closing
    - uv_ref, uv_unref, uv_has_ref
    - uv_recv_buffer_size, uv_fileno, uv_send_buffer_size
    - type: uv_os_fd_t only used by uv_fileno
    - type: uv_handle_type
      - uv_handle_size (uv_handle_type)?? do we even need this?
      - uv_handle_type uv_guess_handle(uf_file)
  - Loop:
    - uv_loop, uv_default_loop, uv_loop_init, uv_loop_close, uv_loop_new,
      uv_loop_delete, uv_loop_size,
      uv_run, uv_loop_alive, uv_stop, uv_update_time, uv_now, uv_walk(??or should this be handle?)
      uv_backend_fd, uv_backend_timeout
    - type: uv_run_mode (only used by uv_run)
  - Stream:
    - uv_shutdown, uv_listen, uv_accept, uv_read_start, uv_read_stop
      uv_is_readable, uv_is_writable, uv_stream_set_blocking,
      (could be uv_write_t?): uv_write , uv_write2, uv_try_write
   => (children are uv_tcp_t, uv_pipe_t, uv_tty_t)
   uv_tcp_t: uv_tcp_init, uv_tcp_open, uv_tcp_nodelay, uv_tcp_keepalive,
     uv_tcp_simultaneious_accepts, uv_tcp_bind, uv_tcp_getsockname, uv_tcp_getpeername,
     uv_tcp_connect (also takes a uv_connect_t req),
  - Pipe (uv_pipe_t is a subclass of uv_stream)
    - uv_pipe_init, uv_pipe_open, uv_pipe_bind, uv_pipe_connect, uv_pipe_getsockname,
      uv_pipe_pending_instances, uv_pipe_pending_count, uv_pipe_pending_type,
  - Tty (uv_tty_t is a subclass of uv_stream)
    - uv_tty_init, uv_tty_set_mode, uv_tty_reset_mode, uv_tty_get_winsize
  - UDP (uv_udp_t is a subclass of handle)
    - uv_udp_init, uv_udp_open, uv_udp_bind, uv_udp_getsockname, uv_udp_set_membership,
      uv_udp_set_multicast_loop, uv_udp_set_multicast_ttl, uv_udp_set_Multicast_interface,
      uv_udp_set_broadcast, uv_udp_set_ttl, uv_udp_send, uv_udp_try_send, uv_udp_recv_start,
      uv_udp_rev_stop
  - Poll (uv_poll_t is a subclass of uv_handle)
    - uv_poll_init, uv_poll_init_socket(uv_os_sock_t), uv_poll_start, uv_poll_stop
  - Timer (subclass of handle)
    - uv_timer_init, uv_timer_start, uv_timer_stop, uv_timer_again, uv_timer_set_repeat,
      uv_timer_get_repeat
  - Prepare (subclass of handle)
    - uv_prepare_init, uv_prepare_start, uv_prepare_stop
  - Check (subclass of handle)
    - uv_check_init, uv_check_start, uv_check_stop
  - Idle (subclass of handle)
    - uv_idle_init, uv_idle_start, uv_idle_stop
  - Async (subclass of handle)
    - uv_async_init, uv_async_send
  - Process (subclass of handle)
    - uv_spawn, uv_process_kill, uv_kill (doesnt take the type but probably should go here?)
    - type: uv_stdio_container_t
  - FS_event (subclass of handle)
    - uv_fs_event_init, uv_fs_event_start, uv_fs_event_stop, uv_fs_event_getpath,
    - type: uv_fs_event_flags
  - FS_poll_t (subclass of handle)
    - uv_fs_poll_init, uv_fs_poll_start, uv_fs_poll_stop, uv_fs_poll_getpath
  - Signal (subclass of handle)
    - uv_signal_init, uv_signal_start, uv_signal_stop
  ==============
  Request types:
  - Request (uv_req_t)
    - uv_cancel
    - type: uv_req_type (may not need this, can just use the datatype)
  - uv_getaddrinfo_t
    - uv_getaddrinfo
  - uv_getnameinfo_t
    - uv_getnameinfo
  - uv_shutdown_t
    - uv_shutdown (takes a stream??): probably should live with stream.
  - uv_write_t: only used in uv_write and uv_write2 which should live with stream
  - uv_connect_t:
    - uv_tcp_connect, uv_pipe_connect
    - I think probably both methods just live with pipe and tcp
  - uv_udp_send_t
    - uv_udp_send: only method. should live with udp
  - uv_fs_t
    - uv_fs_req_cleanup, uv_fs_close, uv_fs_open, uv_fs_read, uv_fs_unlink, uv_fs_write,
      uv_fs_mkdir, uv_fs_mkdtemp, uv_fs_rmdir, uv_fs_readdir, uv_fs_readdir_next,
      uv_fs_stat, uv_fs_fstat, uv_fs_rename, uv_fs_fsync, uv_fs_fdatasync, uv_fs_truncate,
      uv_fs_sendfile, uv_fs_chmod, uv_fs_utime, uv_fs_futime, uv_fs_lstat, uv_fs_link,
      uv_fs_symlink, uv_fs_readlink, uv_fs_fchmod, uv_fs_chown, uv_fs_fchown
    - type: uv_dirent_t: only used by uv_fs_readdir_next
    - type: uv_fs_type
  - uv_work_t
    - uv_queue_work
  =======
  other types (no subtypes):
  - uv_cpu_info_t
    - uv_cpu_info, uv_free_cpu_info
  - uv_interface_address_t
    - uv_interface_addresses, uv_free_interface_addresses
  - uv_buf_t
    - uv_buf_init
  - uv_rusage_t
    - uv_get_rusage
  =======
  Utilities (these are all under a comment that says "Utilities")
  - "network ones"
    - uv_ip4_addr, uv_ip6_addr, uv_ip4_name, uv_ip6_name, uv_inet_ntop, uv_inet_pton
  - "file system"
    - uv_execpath, uv_cwd, uv_chdir
  - "memory"
    - uv_get_free_memory, uv_get_total_memory
  - "time"
    - uv_hrtime
  - global state?
    - uv_disable_stdio_inheritance
  - libraries
    - uv_dlopen, uv_dlclose, uv_dlsym, uv_dlerror
  ========
  Concurrency (no subtypes but these are concurrent stuff)
  - mutex
    - uv_mutex_init, uv_mutex_destroy, uv_mutex_lock,
      uv_mutex_trylock, uv_mutex_unlock
  - rwlock
    - uv_rwlock_init, uv_rwlock_destroy, uv_rwlock_rdlock,
      uv_rwlock_tryrdlock, uv_rwlock_rdunlock, uv_rwlock_wrlock,
      uv_rwlock_trywrlock, uv_rwlock_wrunlock
  - semaphores
    - uv_sem_init, uv_sem_destroy, uv_sem_post, uv_sem_wait, uv_sem_trywait
  - condvariables
    - uv_cond_init, uv_cond_destroy, uv_cond_signal, uv_cond_broadcast
  - barries
    - uv_barrier_init, uv_barrier_destroy, uv_barrier_wait
  - other
    - uv_condi_wait (mutx and cond), uv_cond_timedwait
  - uv_once_t
    - uv_once
  - thread local storage
    - uv_key_create, uv_key_delete, uv_key_get, uv_key_set
  - threads
    - uv_thread_create, uv_thread_self, uv_thread_join

Decisions
---------
* Not going to expose the uv_fs_type or uv_req_type fields.
  Rationale: These appear to be to help share callbacks for the C
  programmer (so that a single method could type cast multiple request/fs types)
  We have already made it impossible to share callbacks between different
  request types (because our OCaml callbacks take the concrete module type).
  I don't see any downside here.
* Not going to use the data pointer.
  Rationale: this is there for the c programmer to pass data to the callback.
  We're in OCaml and can easily pass any data to the callback.


Design thoughts:
----------------
* On dealing with errors:
  - Stdlib's Unix uses exceptions.
  - Stdlib's in_channel and out_channel use exceptions.
    So do the Core's wrapper modules.

Questions
---------
* IMPORTANT: struct lifecycle --
  Are the structs modifable once created? For example, uv_fs_t
  has a cb field. If this is changed post-creation does it do
  anything? I would assume not. Are there any fields that have
  any meaningful write mode?
* uv_fs_t -> callback: if NULL will be done async. How to represent that
  to the OCaml user?
* How do we keep this in sync with upstream library? Maybe a few
  scripts to help search for new keywords?
* Naming of enums -- do we want to keep to big constants? Or not?
* buf -- should this be a special io memory