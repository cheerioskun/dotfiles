# /// script
# requires-python = ">=3.13"
# dependencies = ["modal>=1.4"]
# ///
"""Prove the Ubuntu test substrate; this does not run bootstrap yet.

Run with:
    uv run tests/modal-systemd.py

Modal's outer VM Sandbox has a real kernel but not systemd as PID 1. This
starts Docker in that VM, then boots a privileged Ubuntu 26.04 systemd
container—the layer where the destructive bootstrap tests will run.
"""

from __future__ import annotations

import modal

from modal_harness import (
    CONTAINER_NAME,
    checked_exec,
    start_ubuntu_guest,
    stop_ubuntu_guest,
)


def main() -> None:
    sandbox: modal.Sandbox | None = None
    try:
        sandbox = start_ubuntu_guest()
        pid1 = checked_exec(
            sandbox,
            "docker",
            "exec",
            CONTAINER_NAME,
            "cat",
            "/proc/1/comm",
        ).strip()
        if pid1 != "systemd":
            raise RuntimeError(f"expected nested PID 1 to be systemd, got {pid1!r}")
        print("Modal VM + nested Ubuntu 26.04 systemd substrate passed")
    finally:
        if sandbox is not None:
            stop_ubuntu_guest(sandbox)


if __name__ == "__main__":
    main()
