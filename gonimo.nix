{
  network.description = "gonimo servers";
  "baby.gonimo.com" =
    { config, pkgs, ...}:
    let
      stdenv = pkgs.stdenv;
      fetchurl = pkgs.fetchurl;
      gonimo-front-compiled =
        let version = "0.1.001";
        in
        stdenv.mkDerivation {
            name = "gonimo-front-${version}";
            src = fetchurl {
              url = "https://github.com/gonimo/gonimo-front-compiled/archive/v${version}.tar.gz";
              sha256 = "10izi5q54l2xn032vs95pc9k6m3pd14rf0l1galklgvlppk1qd0x";
            };
            installPhase = ''
              mkdir $out
              cp -a * $out
            '';
            
         };
      gonimo-website-compiled =
        let version = "0.3";
        in
        stdenv.mkDerivation {
            name = "gonimo-website-${version}";
            src = fetchurl {
              url = "https://github.com/gonimo/gonimo-website-compiled/archive/v${version}.tar.gz";
              sha256 = "f546218bef2b6818320dbc4205dc70b4f4fbb432fd758f11444c4f265fd1f6c8";
            };
            installPhase = ''
              mkdir $out
              cp -a * $out
            '';
            
         };

    in
    {
        imports = [ ./gonimo-cfg-nagios.nix ./gonimo-cfg-letsencrypt.nix ./gonimo-cfg-postfix.nix ];

	environment.systemPackages = with pkgs; [htop emacs24-nox wget];

	networking.firewall.allowedTCPPorts = [ 22 80 443 ];
	networking.firewall.allowPing = true;

        # Nginx
        services.nginx.enable = true;

	
        services.nginx.httpConfig = ''
	    server {
	      listen 0.0.0.0:443 ssl;
      	      listen [2a03:4000:6:1b3::3000]:443 ssl;
	      server_name www.gonimo.com;
	      ssl_certificate /var/lib/acme/www.gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/www.gonimo.com/key.pem;
	      # To avoid downgrade attacks; eventually we should change it to:
	      #add_header Strict-Transport-Security "max-age=31536000";
	      # (1 year); for now just one week (testing)
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-website-compiled};
	    }

   	    server {
	      listen 0.0.0.0:443 ssl;
       	      listen [2a03:4000:6:1b3::2000]:443 ssl;
	      server_name gonimo.com;
	      ssl_certificate /var/lib/acme/gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/gonimo.com/key.pem;
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-website-compiled};
	    }
	      
   	    server {
	      listen 0.0.0.0:443 ssl;
      	      listen [2a03:4000:6:1b3::1000]:443 ssl;
      	      server_name baby.gonimo.com;
	      ssl_certificate /var/lib/acme/baby.gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/baby.gonimo.com/key.pem;
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-front-compiled};
	    }

	    server {
              listen [::]:80 ipv6only=off;
              server_name www.gonimo.com;

	      location / {
	        return 301 https://$server_name$request_uri;
	      }

	      location /.well-known/acme-challenge {
      	        root /var/www/challenges;
    	      }
            }

	    server {
	      listen 0.0.0.0:443 ssl;
      	      listen [2a03:4000:6:1b3::4000]:443 ssl;
	      server_name nagios.gonimo.com;
	      ssl_certificate /var/lib/acme/nagios.gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/nagios.gonimo.com/key.pem;
	      # To avoid downgrade attacks; eventually we should change it to:
	      #add_header Strict-Transport-Security "max-age=31536000";
	      # (1 year); for now just one week (testing)
	      add_header Strict-Transport-Security "max-age=604800";
	      
	      auth_basic "Restricted";
              auth_basic_user_file /opt/etc/nagios/htpasswd.users;

              # php related sripts go to php-fpm
              location ~ ^${config.services.nagios.urlPath}/(.+\.php)(.*)$ {
                include        ${pkgs.nginx}/conf/fastcgi_params;
              	fastcgi_split_path_info       ^${config.services.nagios.urlPath}/(.+\.php)(.*)$;
              	fastcgi_pass   127.0.0.1:9000;
              	fastcgi_param  SCRIPT_FILENAME  ${pkgs.nagios}/share/$fastcgi_script_name;
              	fastcgi_param  REMOTE_USER        $remote_user;
              }
  
              location ${config.services.nagios.urlPath}/ {
                alias          ${pkgs.nagios}/share/;
          	index          index.php;
          	autoindex on;
              }
  
              # cgi scripts, basically c-programs, go to the fcgi
              location ~ ^${config.services.nagios.urlPath}/cgi-bin/.*\.cgi$ {
                fastcgi_pass   127.0.0.1:9001;
          	fastcgi_split_path_info       ^${config.services.nagios.urlPath}/cgi-bin/(.+\.cgi)(.*)$;
          	fastcgi_param  SCRIPT_FILENAME  ${pkgs.nagios}/sbin/$fastcgi_script_name;
          	fastcgi_param  NAGIOS_CGI_CONFIG ${config.services.nagios.cgiConfigFile};
          	fastcgi_param  REMOTE_USER        $remote_user;
          	include        ${pkgs.nginx}/conf/fastcgi_params;
              }
      	    }
         '';
    };
}
