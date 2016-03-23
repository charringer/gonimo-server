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
        services.nginx.enable = true;
        services.nginx.httpConfig = ''
            server {
            listen 80;
            server_name baby.gonimo.com;
            root ${gonimo-front-compiled};
            index index.html;
            }
        '';
        networking.firewall.allowedTCPPorts = [ 22 80 443 ];

	services.postfix = {
	  enable = true;
	  origin = "$mydomain";
	  domain = "gonimo.com";
	  rootAlias = "georg.pichler@gmail.com";
	  hostname = "baby.gonimo.com";
	};
    };
}
