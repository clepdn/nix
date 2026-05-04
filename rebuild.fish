#!/usr/bin/env fish

set NIXOS_CONFIG_DIR (test -n "$NIXOS_CONFIG_DIR" && echo $NIXOS_CONFIG_DIR || echo "/etc/nixos")

set SUDO_ARGS --sudo --ask-sudo-password

# Hostname shorthand: ./rebuild.fish <hostname> [extra args]
set NIXOS_SUBCOMMANDS switch boot test build dry-build dry-activate edit repl build-vm build-vm-with-bootloader list-generations
if test (count $argv) -gt 0 && not contains -- $argv[1] $NIXOS_SUBCOMMANDS
    set target $argv[1]
    set rest $argv[2..]
    if test "$target" = (hostname)
        set argv switch --flake .#$target $SUDO_ARGS $rest
    else
        set argv switch --flake .#$target --target-host $target $SUDO_ARGS $rest
    end
end

# Parse flake flag and hostname from args
set FLAKE_PATH ""
set FLAKE_HOST ""

for i in (seq 1 (count $argv))
    if test "$argv[$i]" = "--flake" -o "$argv[$i]" = "-f"
        set next (math $i + 1)
        if test $next -le (count $argv)
            set flake_arg $argv[$next]
            # Split on # to get path and hostname
            set parts (string split "#" $flake_arg)
            set FLAKE_PATH $parts[1]
            if test (count $parts) -gt 1
                set FLAKE_HOST $parts[2]
            end
        end
    # Also handle --flake=value form
    else if string match -q -- "--flake=*" $argv[$i]
        set flake_arg (string replace "--flake=" "" $argv[$i])
        set parts (string split "#" $flake_arg)
        set FLAKE_PATH $parts[1]
        if test (count $parts) -gt 1
            set FLAKE_HOST $parts[2]
        end
    end
end

# Resolve config dir: prefer flake path, then env var, then default
if test -n "$FLAKE_PATH"
    set NIXOS_CONFIG_DIR $FLAKE_PATH
end

# Resolve hostname: prefer flake fragment, then system hostname
if test -n "$FLAKE_HOST"
    set HOSTNAME $FLAKE_HOST
else
    set HOSTNAME (hostname)
end

# Pass all arguments through to nixos-rebuild
echo "nixos-rebuild $argv"
nixos-rebuild $argv
set REBUILD_EXIT $status

if test $REBUILD_EXIT -ne 0
    exit $REBUILD_EXIT
end

# Only act on switch/boot/test
set SUBCOMMAND (test (count $argv) -gt 0 && echo $argv[1] || echo "")
switch $SUBCOMMAND
    case switch boot test
    case '*'
        exit 0
end

if test -z "$FLAKE_PATH" -o -z "$FLAKE_HOST"
    echo "[hook] error: could not parse flake argument (expected --flake path#hostname)" >&2
    exit 0
end

set BRANCH "current-system-$HOSTNAME"
set COMMIT_MSG "WIP: $HOSTNAME system snapshot"

cd $NIXOS_CONFIG_DIR

# Parent the snapshot on main so the branch retains main's real history
# instead of forming an isolated parentless chain. main itself is never
# moved by this script — we only update refs/heads/current-system-<host>.
set MAIN_REF (git rev-parse --verify main 2>/dev/null)
if test -z "$MAIN_REF"
    set MAIN_REF (git rev-parse --verify origin/main 2>/dev/null)
end
if test -z "$MAIN_REF"
    echo "[hook] error: could not resolve 'main' or 'origin/main'" >&2
    exit 1
end

git add -u

set TREE (git write-tree)

# Always parent on main HEAD. The branch is always exactly
# "main + 1 snapshot commit". A force-push is required because each
# rebuild replaces the previous snapshot commit, but main's history
# (and main itself) is never rewritten.
set COMMIT (git commit-tree $TREE -p $MAIN_REF -m $COMMIT_MSG)

git update-ref "refs/heads/$BRANCH" $COMMIT

echo "[hook] Pushing to origin/$BRANCH"

git push -u origin $BRANCH --force-with-lease; or echo "[hook] Push to origin failed!" >&2

git restore --staged . 2>/dev/null; or git reset HEAD . 2>/dev/null

echo "[hook] Committed snapshot to branch '$BRANCH' (parent: main @ "(string sub -l 8 $MAIN_REF)")"
