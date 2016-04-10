{
  network.description = "gonimo servers";
  "baby.gonimo.com" =
    { config, pkgs, ...}:
    let
      stdenv = pkgs.stdenv;
      fetchurl = pkgs.fetchurl;
      gonimo-front-compiled =
        let version = "0.1";
        in
        stdenv.mkDerivation {
            name = "gonimo-front-${version}";
            src = fetchurl {
              url = "https://github.com/gonimo/gonimo-front-compiled/archive/v${version}.tar.gz";
              sha256 = "8271cde58da08b7a8aebe5fa59a6624297c8af0e0d51de96f7682ce0b20f42a2";
            };
            installPhase = ''
              mkdir $out
              cp -a * $out
            '';
            
         };
    in
    {
        environment.systemPackages = with pkgs; [htop emacs24-nox];

	networking.firewall.allowedTCPPorts = [ 22 80 443 ];
	networking.firewall.allowPing = true;
		
        services.nginx.enable = true;
        services.nginx.httpConfig = ''
	    server {
	      listen 443 ssl;
	      server_name www.gonimo.com;
	      ssl_certificate /var/lib/acme/www.gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/www.gonimo.com/key.pem;
	      # To avoid downgrade attacks; eventually we should change it to:
	      #add_header Strict-Transport-Security "max-age=31536000";
	      # (1 year); for now just one week (testing)
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-front-compiled};
	    }

   	    server {
	      listen 443 ssl;
	      server_name gonimo.com;
	      ssl_certificate /var/lib/acme/gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/gonimo.com/key.pem;
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-front-compiled};
	    }
	      
   	    server {
	      listen 443 ssl;
	      server_name baby.gonimo.com;
	      ssl_certificate /var/lib/acme/baby.gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/baby.gonimo.com/key.pem;
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-front-compiled};
	    }
	      
            server {
              listen 80;
              server_name www.gonimo.com;

	      location / {
	        return 301 https://$server_name$request_uri;
	      }

	      location /.well-known/acme-challenge {
      	        root /var/www/challenges;
    	      }
            }
        '';

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

	services.postfix = {
	  enable = true;
	  origin = "$mydomain";
	  domain = "gonimo.com";
	  rootAlias = "georg.pichler@gmail.com";
	  hostname = "baby.gonimo.com";
	};
    };
}
