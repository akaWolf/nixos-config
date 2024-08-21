# load usefull aliases
test -s ~/.fish_aliases && source ~/.fish_aliases || true

# add ~/bin to PATH
test -d ~/bin && set PATH ~/bin $PATH

# set editor
set -xg EDITOR emacs-client

# set pager
set -xg PAGER most

# set GPG TTY
set -xg GPG_TTY $tty

# set HOSTNAME env var for backward compatibility with bash
set -xg HOSTNAME (hostname)

# set bc config path
set -xg BC_ENV_ARGS ~/.bc

# refresh gpg-agent tty in case user switches into an X session
gpg-connect-agent updatestartuptty /bye > /dev/null

# set ssh-agent vars in case when using gpg as ssh-agent
#set -xg SSH_AGENT_PID
set -xg SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"

# nnn: edit all files in EDITOR
set -xg NNN_OPTS 'edE'

# mcfly: C-r interactive
mcfly init fish | source

# pyenv: init $PATH
pyenv init - | source

# emacs-specific
if set -q INSIDE_EMACS
  # dir tracking
  switch $INSIDE_EMACS
  case vterm
  # see https://github.com/akermu/emacs-libvterm#directory-tracking
    function prompt_vterm -e fish_prompt
      printf '\e]51;A%s\e\\' (whoami)'@'(hostname)':'(pwd)
    end
  case '*,term:*'
    # see https://emacs.stackexchange.com/a/31446
    function prompt_AnSiT -e fish_prompt
      printf "\eAnSiTc %s\n" "$PWD"
    end
    # set title to nothing to prevent sending OSC escape sequences
    # see https://github.com/fish-shell/fish-shell/issues/107
    function fish_title
      true
    end
    # usefull for TRAMP
    # see https://github.com/emacs-mirror/emacs/blob/220f16cab6c40a1b0df1a5d2101c6602abbc6aae/lisp/term.el#L241
    printf "\eAnSiTu %s\n" "$USER"
    printf '\033AnSiTh %s\n' "$HOSTNAME"
  end
end

# load nixos home manager using babelfish
cat /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh | babelfish | source
