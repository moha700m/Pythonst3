#include "pythonst3_bridge.h"

#include <Python/Python.h>

#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static pythonst3_write_cb g_write_cb = NULL;
static pythonst3_readline_cb g_readline_cb = NULL;
static atomic_int g_initialized = 0;
static atomic_int g_stop = 0;
static int g_timeout_seconds = 30;
static time_t g_deadline = 0;
static PyObject *g_bootstrap_globals = NULL;

void pythonst3_set_callbacks(pythonst3_write_cb write_cb, pythonst3_readline_cb readline_cb) {
    g_write_cb = write_cb;
    g_readline_cb = readline_cb;
}

static void report_error(const char *message) {
    if (!message) {
        message = "Unknown Python error";
    }
    if (g_write_cb) {
        g_write_cb(2, message);
        g_write_cb(2, "\n");
    } else {
        fprintf(stderr, "%s\n", message);
    }
}

static PyObject *bridge_write(PyObject *self, PyObject *args) {
    int channel = 1;
    const char *text = NULL;
    if (!PyArg_ParseTuple(args, "is", &channel, &text)) {
        return NULL;
    }
    if (g_write_cb && text) {
        g_write_cb(channel, text);
    }
    Py_RETURN_NONE;
}

static PyObject *bridge_readline(PyObject *self, PyObject *args) {
    const char *prompt = "";
    if (!PyArg_ParseTuple(args, "s", &prompt)) {
        return NULL;
    }
    if (!g_readline_cb) {
        Py_RETURN_NONE;
    }
    char *line = g_readline_cb(prompt);
    if (!line) {
        Py_RETURN_NONE;
    }
    PyObject *result = PyUnicode_FromString(line);
    free(line);
    return result;
}

static PyObject *bridge_check_stop(PyObject *self, PyObject *noargs) {
    if (atomic_load(&g_stop)) {
        PyErr_SetString(PyExc_KeyboardInterrupt, "Execution stopped by user");
        return NULL;
    }
    if (g_deadline > 0 && time(NULL) >= g_deadline) {
        PyErr_SetString(PyExc_TimeoutError, "Execution timed out");
        return NULL;
    }
    Py_RETURN_NONE;
}

static PyMethodDef bridge_methods[] = {
    {"write", bridge_write, METH_VARARGS, "Send captured output to the host application."},
    {"readline", bridge_readline, METH_VARARGS, "Request one line of input from the host application."},
    {"check_stop", bridge_check_stop, METH_NOARGS, "Raise when execution was stopped or timed out."},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef bridge_module = {
    PyModuleDef_HEAD_INIT,
    "_pythonst3_bridge",
    "Pythonst3 host bridge",
    -1,
    bridge_methods,
    NULL,
    NULL,
    NULL,
    NULL
};

PyMODINIT_FUNC PyInit__pythonst3_bridge(void) {
    return PyModule_Create(&bridge_module);
}

static int run_bootstrap(const char *source) {
    PyObject *globals = PyDict_New();
    if (!globals) {
        PyErr_Print();
        return -1;
    }
    PyObject *builtins = PyEval_GetBuiltins();
    if (builtins) {
        PyDict_SetItemString(globals, "__builtins__", builtins);
    }
    PyObject *name = PyUnicode_FromString("pythonst3_bootstrap");
    if (name) {
        PyDict_SetItemString(globals, "__name__", name);
        Py_DECREF(name);
    }
    PyObject *result = PyRun_StringFlags(source, Py_file_input, globals, globals, NULL);
    if (!result) {
        PyErr_Print();
        Py_DECREF(globals);
        return -1;
    }
    Py_DECREF(result);
    g_bootstrap_globals = globals;
    return 0;
}

static void install_trace_hook(void) {
    if (!g_bootstrap_globals) {
        return;
    }
    PyObject *trace = PyDict_GetItemString(g_bootstrap_globals, "_pythonst3_trace");
    if (!trace) {
        return;
    }
    PyObject *sys = PyImport_ImportModule("sys");
    if (!sys) {
        PyErr_Clear();
        return;
    }
    PyObject *result = PyObject_CallMethod(sys, "settrace", "O", trace);
    Py_XDECREF(result);
    Py_DECREF(sys);
}

int pythonst3_initialize(const char *home, const char *executable, const char *bootstrap) {
    if (atomic_load(&g_initialized)) {
        return 0;
    }
    if (!home || !executable || !bootstrap) {
        report_error("Pythonst3: missing runtime paths.");
        return -1;
    }

    PyPreConfig preconfig;
    PyPreConfig_InitIsolatedConfig(&preconfig);
    preconfig.utf8_mode = 1;

    PyStatus status = Py_PreInitialize(&preconfig);
    if (PyStatus_Exception(status)) {
        report_error(status.err_msg);
        return -1;
    }

    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);
    config.buffered_stdio = 0;
    config.write_bytecode = 0;
    config.install_signal_handlers = 0;
    config.parse_argv = 0;
    config.site_import = 1;

    wchar_t *home_wide = Py_DecodeLocale(home, NULL);
    if (!home_wide) {
        report_error("Pythonst3: unable to decode PYTHONHOME.");
        PyConfig_Clear(&config);
        return -1;
    }
    status = PyConfig_SetString(&config, &config.home, home_wide);
    PyMem_RawFree(home_wide);
    if (PyStatus_Exception(status)) {
        report_error(status.err_msg);
        PyConfig_Clear(&config);
        return -1;
    }

    status = PyConfig_Read(&config);
    if (PyStatus_Exception(status)) {
        report_error(status.err_msg);
        PyConfig_Clear(&config);
        return -1;
    }

    char *argv[2];
    argv[0] = (char *)executable;
    argv[1] = NULL;
    status = PyConfig_SetBytesArgv(&config, 1, argv);
    if (PyStatus_Exception(status)) {
        report_error(status.err_msg);
        PyConfig_Clear(&config);
        return -1;
    }

    if (PyImport_AppendInittab("_pythonst3_bridge", PyInit__pythonst3_bridge) < 0) {
        report_error("Pythonst3: unable to register the native bridge module.");
        PyConfig_Clear(&config);
        return -1;
    }

    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        report_error(status.err_msg);
        return -1;
    }

    PyEval_SaveThread();
    atomic_store(&g_initialized, 1);

    PyGILState_STATE gil = PyGILState_Ensure();
    int bootstrap_status = run_bootstrap(bootstrap);
    PyGILState_Release(gil);

    if (bootstrap_status != 0) {
        atomic_store(&g_initialized, 0);
        return -2;
    }
    return 0;
}

int pythonst3_execute(const char *source, const char *filename, const char *project_dir) {
    if (!atomic_load(&g_initialized)) {
        report_error("Pythonst3: interpreter is not initialized.");
        return -1;
    }
    if (!source) {
        return -1;
    }

    atomic_store(&g_stop, 0);
    g_deadline = g_timeout_seconds > 0 ? time(NULL) + g_timeout_seconds : 0;

    PyGILState_STATE gil = PyGILState_Ensure();
    int result = 1;

    if (project_dir) {
        if (chdir(project_dir) != 0) {
            report_error("Pythonst3: unable to open the project directory.");
            PyGILState_Release(gil);
            return -1;
        }
        PyObject *path = PySys_GetObject("path");
        PyObject *directory = PyUnicode_FromString(project_dir);
        if (path && directory) {
            if (PyList_Size(path) > 0) {
                PyList_SetItem(path, 0, directory);
            } else {
                PyList_Append(path, directory);
                Py_DECREF(directory);
            }
        } else {
            Py_XDECREF(directory);
        }
    }

    install_trace_hook();

    PyObject *globals = PyDict_New();
    if (!globals) {
        PyErr_Print();
        PyGILState_Release(gil);
        return 1;
    }
    PyObject *builtins = PyEval_GetBuiltins();
    if (builtins) {
        PyDict_SetItemString(globals, "__builtins__", builtins);
    }
    PyObject *name = PyUnicode_FromString("__main__");
    if (name) {
        PyDict_SetItemString(globals, "__name__", name);
        Py_DECREF(name);
    }
    const char *display_name = filename ? filename : "<pythonst3>";
    PyObject *file = PyUnicode_FromString(display_name);
    if (file) {
        PyDict_SetItemString(globals, "__file__", file);
        Py_DECREF(file);
    }

    PyObject *code = Py_CompileString(source, display_name, Py_file_input);
    if (!code) {
        if (atomic_load(&g_stop) || PyErr_ExceptionMatches(PyExc_TimeoutError)) {
            PyErr_Clear();
            result = 2;
        } else {
            PyErr_Print();
            result = 1;
        }
    } else {
        PyObject *evaluated = PyEval_EvalCode(code, globals, globals);
        Py_DECREF(code);
        if (!evaluated) {
            if (atomic_load(&g_stop) || PyErr_ExceptionMatches(PyExc_TimeoutError)) {
                PyErr_Clear();
                result = 2;
            } else if (PyErr_ExceptionMatches(PyExc_SystemExit)) {
                PyErr_Clear();
                result = 3;
            } else {
                PyErr_Print();
                result = 1;
            }
        } else {
            Py_DECREF(evaluated);
            result = 0;
        }
    }

    PyObject *sys = PyImport_ImportModule("sys");
    if (sys) {
        const char *stream_names[] = {"stdout", "stderr"};
        for (int i = 0; i < 2; i++) {
            PyObject *stream = PyObject_GetAttrString(sys, stream_names[i]);
            if (stream) {
                PyObject *flushed = PyObject_CallMethod(stream, "flush", NULL);
                Py_XDECREF(flushed);
                Py_DECREF(stream);
            }
        }
        Py_DECREF(sys);
    } else {
        PyErr_Clear();
    }

    Py_DECREF(globals);
    PyGILState_Release(gil);
    return result;
}

void pythonst3_request_stop(void) {
    atomic_store(&g_stop, 1);
}

void pythonst3_set_timeout(int seconds) {
    if (seconds < 1) {
        seconds = 1;
    }
    if (seconds > 300) {
        seconds = 300;
    }
    g_timeout_seconds = seconds;
}

const char *pythonst3_version(void) {
    if (!atomic_load(&g_initialized)) {
        return "not initialized";
    }
    return Py_GetVersion();
}

int pythonst3_is_ready(void) {
    return atomic_load(&g_initialized);
}
