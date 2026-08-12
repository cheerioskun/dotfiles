import os

import sublime_plugin


class SetupCsesLayoutCommand(sublime_plugin.WindowCommand):
    def run(self):
        code = self.window.active_view()
        filename = code.file_name() if code else None
        base = os.path.dirname(filename) if filename else os.path.expanduser("~")

        self.window.run_command("set_layout", {
            "cols": [0.0, 0.58, 1.0],
            "rows": [0.0, 0.5, 1.0],
            "cells": [[0, 0, 1, 2], [1, 0, 2, 1], [1, 1, 2, 2]],
        })

        if code:
            self.window.set_view_index(code, 0, 0)
        self.window.open_file(os.path.join(base, "input.txt"), group=1)
        self.window.open_file(os.path.join(base, "output.txt"), group=2)
        self.window.focus_group(0)
