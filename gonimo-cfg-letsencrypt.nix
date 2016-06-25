{ config, pkgs, ...}:

{
        # Let's Encrypt!
	security.acme.certs."baby.gonimo.com" = {
	  webroot = "/var/www/challenges";
	  email = "georg.pichler@gmail.com";
	  postRun = "systemctl reload nginx.service";
	};

	security.acme.certs."www.gonimo.com" = {
	  webroot = "/var/www/challenges";
	  email = "georg.pichler@gmail.com";
 	  postRun = "systemctl reload nginx.service";
	};

	security.acme.certs."gonimo.com" = {
	  webroot = "/var/www/challenges";
	  email = "georg.pichler@gmail.com";
  	  postRun = "systemctl reload nginx.service";
	};
	
	security.acme.certs."nagios.gonimo.com" = {
	  webroot = "/var/www/challenges";
	  email = "georg.pichler@gmail.com";
  	  postRun = "systemctl reload nginx.service";
	};

}
