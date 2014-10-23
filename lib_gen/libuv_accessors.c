/*
 * Accessors to public methods go here.
 * See the DEVE readme for more information
 *
 * Every function has the name:
 *   get_{type}_{fieldname}
 */

#include <uv.h>

/*
 * Makes a getter. Assumes entity is the non-ptr type.
 * eg G(uv_handle_t, uv_loop_t*, loop) ->
 *   uv_loop_t* get_uv_handle_t_loop (const uv_handle_t* v) { return v->loop; }
 */
#define G(ENTITY, TYPE, FIELD) \
    TYPE get_ ## ENTITY ## _ ## FIELD (const ENTITY* v) { return v->FIELD; }

G(uv_handle_t, uv_loop_t*, loop)
G(uv_stream_t, size_t, write_queue_size)
G(uv_fs_t, uv_loop_t*, loop)
G(uv_fs_t, ssize_t, result)
