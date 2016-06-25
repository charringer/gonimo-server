{ config, pkgs, ...}:

{
        # Postfix
	services.postfix = {
	  enable = true;
	  origin = "$mydomain";
	  domain = "gonimo.com";
	  rootAlias = "georg.pichler@gmail.com";
	  hostname = "baby.gonimo.com";
	};
}

