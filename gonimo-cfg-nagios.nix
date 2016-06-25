{ config, pkgs, ...}:

{
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

  # Add htpassword file /opt/etc/nagios/htpasswd.users
  imports = [ ./secure/gonimo-cfg-nagios-secure.nix ];

}
