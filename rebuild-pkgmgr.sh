if [ -z $1 ]; then
	HOST=megatron
else
	HOST=$1
fi
echo installing packages for $HOST
sudo nix-env -if hosts/$HOST/pkgs.nix
