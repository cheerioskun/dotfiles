import sublime
import sublime_plugin


class SetupCsesLayoutCommand(sublime_plugin.WindowCommand):
    def run(self):
        base = "/Users/hemant/repos/practice/cses"
        self.window.run_command("set_layout", {
            "cols": [0.0, 0.58, 1.0],
            "rows": [0.0, 0.5, 1.0],
            "cells": [[0, 0, 1, 2], [1, 0, 2, 1], [1, 1, 2, 2]],
        })
        self.window.focus_group(0)
        self.window.open_file(base + "/tasks-deadlines.rs")
        self.window.focus_group(1)
        self.window.open_file(base + "/input.txt")
        self.window.focus_group(2)
        self.window.open_file(base + "/output.txt")
        self.window.focus_group(0)
