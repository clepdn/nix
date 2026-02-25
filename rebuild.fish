#!/usr/bin/env fish

set NIXOS_CONFIG_DIR (test -n "$NIXOS_CONFIG_DIR" && echo $NIXOS_CONFIG_DIR || echo "/etc/nixos")

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

set PROFILE "/nix/var/nix/profiles/system"

set GEN_NUMBER (readlink $PROFILE | grep -oP 'system-\K[0-9]+(?=-link)')

set GEN_NAME (nix eval "$FLAKE_PATH#nixosConfigurations.$FLAKE_HOST.config.system.nixos.codeName" --raw 2>/dev/null)

if test -z "$GEN_NAME"
    set GEN_NAME (nix-env --list-generations -p $PROFILE 2>/dev/null \
        | awk -v gen="$GEN_NUMBER" '$1 == gen {print $NF}')
end

if test -z "$GEN_NAME"
    set GEN_NAME "unknown"
end

set BRANCH "current-system-$HOSTNAME"
set COMMIT_MSG "NixOS ($GEN_NAME) generation $GEN_NUMBER"

cd $NIXOS_CONFIG_DIR

git add -u

set TREE (git write-tree)

if git show-ref --verify --quiet "refs/heads/$BRANCH"
    set PARENT (git rev-parse $BRANCH)
    set COMMIT (git commit-tree $TREE -p $PARENT -m $COMMIT_MSG)
else
    set COMMIT (git commit-tree $TREE -m $COMMIT_MSG)
end

git update-ref "refs/heads/$BRANCH" $COMMIT

echo "[hook] Pushing to origin/$BRANCH"

git push -u origin $BRANCH --force; or echo "[hook] Push to origin failed!" >&2

git restore --staged . 2>/dev/null; or git reset HEAD . 2>/dev/null

echo "[hook] Committed generation to branch '$BRANCH': $COMMIT_MSG"
