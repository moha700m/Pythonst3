"""Bootstrap code for the embedded Pythonst3 interpreter.

This module is executed once after Py_InitializeFromConfig. It installs
stream bridges, the interactive input bridge and the stop/timeout hook.
"""

import builtins
import sys

import _pythonst3_bridge as _bridge


class _Pythonst3Stream:
    def __init__(self, channel):
        self.channel = channel

    def write(self, text):
        if text:
            _bridge.write(self.channel, str(text))
        return len(text)

    def flush(self):
        return None

    def isatty(self):
        return False

    @property
    def encoding(self):
        return "utf-8"


sys.stdout = _Pythonst3Stream(1)
sys.stderr = _Pythonst3Stream(2)


def _pythonst3_input(prompt=""):
    if prompt:
        sys.stdout.write(str(prompt))
        sys.stdout.flush()
    line = _bridge.readline(str(prompt))
    if line is None:
        raise EOFError("Input was cancelled")
    return line


builtins.input = _pythonst3_input


def _pythonst3_trace(frame, event, arg):
    if event == "line":
        _bridge.check_stop()
    return _pythonst3_trace


sys.settrace(_pythonst3_trace)
