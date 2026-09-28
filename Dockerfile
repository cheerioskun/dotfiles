# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG USERNAME=hx
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git sudo \
    && rm -rf /var/lib/apt/lists/*
RUN userdel --remove ubuntu 2>/dev/null || true
RUN groupdel ubuntu 2>/dev/null || true
RUN groupadd --gid "${GID}" "${USERNAME}" \
    && useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

USER ${USERNAME}
WORKDIR ${HOME}/dotfiles

# Only installer changes invalidate the expensive toolchain layer.
COPY --chown=${UID}:${GID} bootstrap.sh ./bootstrap.sh
COPY --chown=${UID}:${GID} scripts/linux ./scripts/linux
RUN DOTFILES_SKIP_CONFIGS=1 ./bootstrap.sh

# Use Bob's current Neovim even outside interactive zsh (e.g. docker exec).
ENV PATH="${HOME}/.local/share/bob/nvim-bin:${HOME}/.local/bin:${PATH}"

RUN sudo mkdir -p /workspace && sudo chown "${USERNAME}:${USERNAME}" /workspace

# Config-only edits reuse the installed system packages and language toolchains.
COPY --chown=${UID}:${GID} home/ ./home/
RUN chezmoi apply --source "${HOME}/dotfiles/home"

# Neovim installs its plugins on first launch; only preinstall tmux plugins.
RUN tmux new-session -d -s plugin-install \
    && "${HOME}/.tmux/plugins/tpm/bin/install_plugins" \
    && tmux kill-server

ENV USER=${USERNAME} SHELL=/usr/bin/zsh
WORKDIR /workspace
CMD ["zsh", "-l"]
