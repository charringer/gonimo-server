{
  gonimo-front =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualMemorySize = 1024;
    };
}
