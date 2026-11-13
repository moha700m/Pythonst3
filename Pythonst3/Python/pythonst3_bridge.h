#ifndef PYTHONST3_BRIDGE_H
#define PYTHONST3_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*pythonst3_write_cb)(int channel, const char *text);
typedef char *(*pythonst3_readline_cb)(const char *prompt);

void pythonst3_set_callbacks(pythonst3_write_cb write_cb, pythonst3_readline_cb readline_cb);
int  pythonst3_initialize(const char *home, const char *executable, const char *bootstrap);
int  pythonst3_execute(const char *source, const char *filename, const char *project_dir);
int  pythonst3_repl(const char *source, const char *project_dir);
void pythonst3_request_stop(void);
void pythonst3_set_timeout(int seconds);
const char *pythonst3_version(void);
int  pythonst3_is_ready(void);

#ifdef __cplusplus
}
#endif

#endif
