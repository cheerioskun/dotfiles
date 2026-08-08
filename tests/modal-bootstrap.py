# /// script
# requires-python = ">=3.13"
# dependencies = ["modal>=1.5.3"]
# ///
"""Run the destructive Ubuntu bootstrap twice in a disposable systemd guest."""

from __future__ import annotations

import argparse
import base64
import hashlib
from pathlib import Path
import tarfile
import tempfile

import modal

from modal_harness import (
    CONTAINER_NAME,
    checked_exec,
    start_ubuntu_guest,
    stop_ubuntu_guest,
)

REPO_ROOT = Path(__file__).resolve().parent.parent


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--pristine",
        action="store_true",
        help="start from an empty home instead of seeding legacy dotfiles",
    )
    return parser.parse_args()


def make_source_archive() -> Path:
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as handle:
        archive = Path(handle.name)

    def include(info: tarfile.TarInfo) -> tarfile.TarInfo | None:
        parts = Path(info.name).parts
        if any(part in {".git", ".direnv", "__pycache__"} for part in parts):
            return None
        if any(
            part == ".env" or part.startswith(".env.") or part == ".DS_Store"
            for part in parts
        ):
            return None
        if info.name.startswith("dotfiles/result"):
            return None
        return info

    with tarfile.open(archive, "w:gz") as output:
        output.add(REPO_ROOT, arcname="dotfiles", filter=include)
    return archive


def run_bootstrap(sandbox: modal.Sandbox, label: str) -> None:
    process = sandbox.exec(
        "docker",
        "exec",
        "--user",
        "hx",
        "--env",
        "HOME=/home/hx",
        "--env",
        "USER=hx",
        "--workdir",
        "/home/hx/dotfiles",
        CONTAINER_NAME,
        "bash",
        "-lc",
        "./bootstrap.sh --fresh --host ubuntu --yes "
        f">/tmp/bootstrap-{label}.log 2>&1",
        timeout=45 * 60,
    )
    process.wait()
    if process.returncode == 0:
        return

    encoded = checked_exec(
        sandbox,
        "docker",
        "exec",
        CONTAINER_NAME,
        "bash",
        "-lc",
        f"tail -n 300 /tmp/bootstrap-{label}.log | base64 -w0",
    )
    log = base64.b64decode(encoded).decode("utf-8", errors="replace")
    raise RuntimeError(f"{label} bootstrap failed:\n{log}")


def copy_archive_to_guest(
    sandbox: modal.Sandbox, archive: Path
) -> None:
    payload = archive.read_bytes()
    process = sandbox.exec(
        "docker",
        "exec",
        "--interactive",
        CONTAINER_NAME,
        "sh",
        "-c",
        "cat >/tmp/dotfiles.tar.gz",
        text=False,
        timeout=120,
    )
    process.stdin.write(payload)
    process.stdin.write_eof()
    process.stdin.drain()
    process.wait()
    if process.returncode != 0:
        error = process.stderr.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"could not stream source archive to guest: {error}")

    expected = hashlib.sha256(payload).hexdigest()
    actual = checked_exec(
        sandbox,
        "docker",
        "exec",
        CONTAINER_NAME,
        "sha256sum",
        "/tmp/dotfiles.tar.gz",
    ).split()[0]
    if actual != expected:
        raise RuntimeError("source archive checksum changed while copying")


def main() -> None:
    args = parse_args()
    legacy_setup = ""
    preservation_checks = ""
    if not args.pristine:
        legacy_setup = (
            "mkdir -p /home/hx/.nvm /home/hx/.pi/agent/sessions "
            "/home/hx/.ssh /home/hx/.config/unrelated; "
            "touch /home/hx/.zshrc /home/hx/.nvm/nvm.sh "
            "/home/hx/.zshrc.local /home/hx/.pi/auth.json "
            "/home/hx/.pi/agent/sessions/keep /home/hx/.ssh/keep "
            "/home/hx/.config/unrelated/keep; "
        )
        preservation_checks = (
            "test -e /home/hx/.zshrc.local; "
            "test -e /home/hx/.pi/auth.json; "
            "test -e /home/hx/.pi/agent/sessions/keep; "
            "test -e /home/hx/.ssh/keep; "
            "test -e /home/hx/.config/unrelated/keep; "
        )

    guest_setup = "".join(
        [
            "set -e; ",
            "useradd --create-home --shell /bin/bash --groups sudo hx; ",
            "printf 'hx ALL=(ALL) NOPASSWD: ALL\\n' >/etc/sudoers.d/hx; ",
            "chmod 0440 /etc/sudoers.d/hx; ",
            "tar -xzf /tmp/dotfiles.tar.gz -C /home/hx; ",
            legacy_setup,
            "chown -R hx:hx /home/hx; ",
            "sudo -u hx sudo -n true",
        ]
    )
    guest_verify = "".join(
        [
            "set -eux; ",
            "test ! -e /home/hx/.nvm; ",
            preservation_checks,
            "test -s /home/hx/.zshenv; ",
            "test -s /home/hx/.config/zsh/.zshrc; ",
            "test -s /home/hx/.config/mise/config.toml; ",
            "login_shell=$(getent passwd hx | cut -d: -f7); ",
            "test -x \"$login_shell\"; ",
            "sudo -u hx env HOME=/home/hx TERM=xterm-256color ",
            "\"$login_shell\" -lic ",
            "'command -v mise; command -v uv; command -v modal; ",
            "command -v pi; command -v node; command -v go; ",
            "command -v rustc; zsh -n ~/.config/zsh/.zshrc; ",
            "bash ~/dotfiles/tests/mise-smoke.sh'",
        ]
    )

    archive = make_source_archive()
    sandbox: modal.Sandbox | None = None
    try:
        sandbox = start_ubuntu_guest()
        copy_archive_to_guest(sandbox, archive)
        checked_exec(
            sandbox,
            "docker",
            "exec",
            CONTAINER_NAME,
            "bash",
            "-lc",
            guest_setup,
        )

        run_bootstrap(sandbox, "first")
        checked_exec(
            sandbox,
            "docker",
            "exec",
            CONTAINER_NAME,
            "bash",
            "-lc",
            guest_verify,
            timeout=15 * 60,
        )

        run_bootstrap(sandbox, "second")
        state = "pristine" if args.pristine else "brownfield"
        print(f"Ubuntu {state} bootstrap and clean reinstall passed")
    finally:
        archive.unlink(missing_ok=True)
        if sandbox is not None:
            stop_ubuntu_guest(sandbox)


if __name__ == "__main__":
    main()
