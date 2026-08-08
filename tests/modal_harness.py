"""Shared Modal VM + nested Ubuntu systemd test substrate."""

from __future__ import annotations

import modal

APP_NAME = "dotfiles-bootstrap-tests"
CONTAINER_NAME = "dotfiles-ubuntu"

SYSTEMD_DOCKERFILE = """\
FROM ubuntu:26.04
ENV container=docker
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl git sudo systemd systemd-sysv xz-utils \
    && rm -rf /var/lib/apt/lists/*
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
"""


def checked_exec(
    sandbox: modal.Sandbox, *command: str, timeout: int = 300
) -> str:
    process = sandbox.exec(*command, timeout=timeout)
    process.wait()
    stdout = process.stdout.read()
    stderr = process.stderr.read()
    if process.returncode != 0:
        rendered = " ".join(command)
        raise RuntimeError(
            f"command failed ({process.returncode}): {rendered}\n"
            f"stdout:\n{stdout}\nstderr:\n{stderr}"
        )
    return stdout


def start_ubuntu_guest() -> modal.Sandbox:
    app = modal.App.lookup(APP_NAME, create_if_missing=True)
    outer_image = (
        modal.Image.from_registry("ubuntu:24.04")
        .env({"DEBIAN_FRONTEND": "noninteractive"})
        .apt_install("docker.io")
    )

    with modal.enable_output():
        sandbox = modal.Sandbox.create(
            "/usr/bin/dockerd",
            "--host=unix:///var/run/docker.sock",
            "--storage-driver=vfs",
            app=app,
            image=outer_image,
            cpu=2,
            memory=8192,
            timeout=60 * 60,
            experimental_options={"vm_runtime": True},
        )

    checked_exec(
        sandbox,
        "sh",
        "-c",
        "for i in $(seq 1 120); do "
        "docker info >/dev/null 2>&1 && exit 0; "
        "sleep 1; "
        "done; exit 1",
        timeout=130,
    )
    sandbox.filesystem.write_text(SYSTEMD_DOCKERFILE, "/tmp/Dockerfile")
    checked_exec(
        sandbox,
        "docker",
        "build",
        "--tag",
        "dotfiles-ubuntu-systemd",
        "--file",
        "/tmp/Dockerfile",
        "/tmp",
        timeout=900,
    )
    checked_exec(
        sandbox,
        "docker",
        "run",
        "--privileged",
        "--detach",
        "--name",
        CONTAINER_NAME,
        "--cgroupns=host",
        "--tmpfs",
        "/run",
        "--tmpfs",
        "/run/lock",
        "--volume",
        "/sys/fs/cgroup:/sys/fs/cgroup:rw",
        "dotfiles-ubuntu-systemd",
    )
    checked_exec(
        sandbox,
        "sh",
        "-c",
        "for i in $(seq 1 60); do "
        f"docker exec {CONTAINER_NAME} systemctl is-system-running "
        "| grep -qx running && exit 0; "
        "sleep 1; "
        "done; exit 1",
        timeout=70,
    )
    return sandbox


def stop_ubuntu_guest(sandbox: modal.Sandbox) -> None:
    try:
        sandbox.exec(
            "docker", "rm", "--force", CONTAINER_NAME, timeout=30
        ).wait()
    finally:
        sandbox.terminate()
