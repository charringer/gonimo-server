{
  gonimo-front =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024; # megabytes
    };
}
