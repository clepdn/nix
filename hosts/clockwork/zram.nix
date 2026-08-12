{ ... }:
{
  # Compressed swap in RAM. With only 3.5GB physical, this roughly doubles
  # usable memory before the (nonexistent) disk swap is ever touched. Only
  # cold/inactive pages get compressed; the hot working set stays uncompressed.
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # good ratio for low CPU/battery cost
    memoryPercent = 100; # disksize cap; real RAM use is ~1/2-1/3 due to compression
  };

  # zram is cheap compared to real disk swap, so let the kernel lean on it.
  boot.kernel.sysctl."vm.swappiness" = 180;
}
