#!/usr/bin/env fish

set -l nmux_dir "$XDG_RUNTIME_DIR/nmux"
mkdir -p $nmux_dir

function _nmux_next_number
    set -l dir $argv[1]
    set -l n 1
    while test -e "$dir/$n"
        set n (math $n + 1)
    end
    echo $n
end

function _nmux_latest_session
    set -l dir $argv[1]
    set -l sessions (ls -1 $dir 2>/dev/null)
    if test (count $sessions) -eq 0
        echo ""
        return 1
    end
    # alphabetically greatest = last when sorted
    set -l sorted (printf '%s\n' $sessions | sort)
    echo $sorted[-1]
end

function _nmux_new -a dir name
    if test -z "$name"
        set name (_nmux_next_number $dir)
    end
    set -l sock "$dir/$name"
    if test -e "$sock"
        echo "nmux: session '$name' already exists" >&2
        return 1
    end
    echo "nmux: creating session '$name'"
    exec nvim --listen "$sock"
end

function _nmux_attach -a dir name
    if test -z "$name"
        set name (_nmux_latest_session $dir)
        if test -z "$name"
            echo "nmux: no sessions found" >&2
            return 1
        end
    end
    set -l sock "$dir/$name"
    if not test -e "$sock"
        echo "nmux: session '$name' not found" >&2
        return 1
    end
    echo "nmux: attaching to session '$name'"
    set -gx COLORTERM truecolor
    exec nvim --server "$sock" --remote-ui -u NONE
end

function _nmux_list -a dir
    set -l sessions (ls -1 $dir 2>/dev/null)
    if test (count $sessions) -eq 0
        echo "no sessions"
        return 0
    end
    echo "sessions:"
    for s in $sessions
        set -l sock "$dir/$s"
        # check if socket is alive
        if socat -u OPEN:/dev/null "UNIX-CONNECT:$sock" 2>/dev/null
            set_color green
            echo "  $s"
        else
            set_color yellow
            echo "  $s (dead)"
        end
    end
    set_color normal
end

# --- main ---

set -l cmd $argv[1]
set -l rest $argv[2..-1]

switch "$cmd"
    case "" new-session n
        if test "$cmd" = ""
            _nmux_new $nmux_dir
        else
            _nmux_new $nmux_dir $rest[1]
        end
    case attach-session attach a
        _nmux_attach $nmux_dir $rest[1]
    case list-sessions ls
        _nmux_list $nmux_dir
    case kill-session kill k
        if test -z "$rest[1]"
            echo "nmux: specify a session name to kill" >&2
            exit 1
        end
        set -l sock "$nmux_dir/$rest[1]"
        if not test -e "$sock"
            echo "nmux: session '$rest[1]' not found" >&2
            exit 1
        end

        # start watching for socket deletion before sending quit
        inotifywait -t 5 -e delete_self "$sock" >/dev/null 2>&1 &
        set -l watch_pid $last_pid

        # ask nvim to quit gracefully
        nvim --server "$sock" --remote-send ":qa!<CR>" 2>/dev/null

        # wait for inotifywait — returns 0 if deleted, non-zero on timeout
        wait $watch_pid 2>/dev/null

        if test -e "$sock"
            # socket still around — find the owner and kill it
            set -l pid (fuser "$sock" 2>/dev/null | string trim)
            if test -n "$pid"
                kill -9 $pid 2>/dev/null
            end
            rm -f "$sock"
            echo "nmux: force-killed session '$rest[1]'"
        else
            echo "nmux: killed session '$rest[1]'"
        end
    case '*'
        echo "usage: nmux [command] [name]"
        echo ""
        echo "commands:"
        echo "  new-session, n [name]   create a new session (default: next number)"
        echo "  attach-session, a [name] attach to a session (default: latest)"
        echo "  list-sessions, ls        list sessions"
        echo "  kill-session, k <name>   kill a session"
        exit 1
end
