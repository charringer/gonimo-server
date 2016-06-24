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
    in
    {
        environment.systemPackages = with pkgs; [htop emacs24-nox wget];

	networking.firewall.allowedTCPPorts = [ 22 80 443 ];
	networking.firewall.allowPing = true;
		
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
	      root ${gonimo-front-compiled};
	    }

   	    server {
	      listen 0.0.0.0:443 ssl;
       	      listen [2a03:4000:6:1b3::2000]:443 ssl;
	      server_name gonimo.com;
	      ssl_certificate /var/lib/acme/gonimo.com/fullchain.pem;
	      ssl_certificate_key /var/lib/acme/gonimo.com/key.pem;
	      add_header Strict-Transport-Security "max-age=604800";
	      root ${gonimo-front-compiled};
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
	
	security.acme.certs."nagios.gonimo.com" = {
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

	# Nagios

	security.sudo.enable = true;
    	security.sudo.configFile = ''
      	  nagios ALL = NOPASSWD: /opt/bin/check_disk
    	'';

  	system.activationScripts.nagios-sudo = ''
	  mkdir -p /opt/bin
    	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_disk" /opt/bin/check_disk
    	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_http" /opt/bin/check_http
    	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_ssh"  /opt/bin/check_ssh
    	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_ping"  /opt/bin/check_ping
    	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_smtp"  /opt/bin/check_smtp
	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_ntp_time"  /opt/bin/check_ntp_time
	  ln -sf "${pkgs.nagiosPluginsOfficial}/libexec/check_ntp_peer"  /opt/bin/check_ntp_peer
  	'';

	system.activationScripts.nagios = ''
	  mkdir -p /opt/etc/nagios
	  echo "admin:\$apr1\$dx66KN8A\$OO3YoSDaDvW4FegkC2W9/1" >/opt/etc/nagios/htpasswd.users
  	'';
	
  	services.nagios = {
    	  enable = true;
	  urlPath = "/nagios";
    	  objectDefs = [
      	    ./nagios/conf.d/contacts.cfg
      	    ./nagios/conf.d/generic-host.cfg
      	    ./nagios/conf.d/generic-service.cfg
      	    ./nagios/conf.d/hostgroups.cfg
      	    ./nagios/conf.d/localhost.cfg
      	    ./nagios/conf.d/services.cfg
      	    ./nagios/conf.d/timeperiods.cfg
      	    ./nagios/conf.d/commands.cfg
    	  ];
	
    	  plugins = [ pkgs.nagiosPluginsOfficial pkgs.opensmtpd pkgs.procps pkgs.gawk pkgs.lm_sensors ];
  	
    	  cgiConfigFile = pkgs.writeText "nagios.cgi.conf" ''
      	    main_config_file=${config.services.nagios.mainConfigFile}
      	    use_authentication=1let
      	    url_html_path=${config.services.nagios.urlPath}
      	    authorized_for_system_information=admin
      	    authorized_for_system_commands=admin
      	    authorized_for_configuration_information=admin
      	    authorized_for_all_hosts=admin
      	    authorized_for_all_host_commands=admin
      	    authorized_for_all_services=admin
      	    authorized_for_all_service_commands=admin
      	    default_statusmap_layout=5
    	  '';
	};

	# phpfpm for Nagios
 	services.phpfpm.poolConfigs = {
    	  nagios = ''
      	    listen = 127.0.0.1:9000
      	    user = nagios
      	    pm = dynamic
      	    pm.max_children = 4
      	    pm.start_servers = 4
      	    pm.min_spare_servers = 2
      	    pm.max_spare_servers = 4
      	    pm.max_requests = 500
  	    
      	    php_flag[display_errors] = on
      	    php_value[date.timezone] = "Europe/Vienna"
      	    php_admin_value[error_log] = /var/log/nagios/phpfpm.log
      	    php_admin_flag[log_errors] = on
      	    php_admin_value[open_basedir] = ${pkgs.nagios}/share
    	  '';
  	};

	# fcgi wrapper
	services.fcgiwrap = {
    	  enable = true;
    	  preforkProcesses = 4;
    	  socketType = "tcp";
    	  socketAddress = "127.0.0.1:9001";
 	};	
    };
}
