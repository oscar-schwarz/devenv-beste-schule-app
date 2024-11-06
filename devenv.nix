{ pkgs, lib, config, ... }:

let 
 dotenvDefaults = {
  NUXT_PUBLIC_API_BASE = "https://beste.schule/api";
  NUXT_PUBLIC_OAUTH_AUTHORIZATION_URL = "https://beste.schule/oauth/authorize";
  NUXT_PUBLIC_OAUTH_REGISTRATION_URL = "https://beste.schule/oauth/join";
  NUXT_PUBLIC_OAUTH_TOKEN_URL = "https://beste.schule/oauth/token";
  NUXT_PUBLIC_BASE_URL = "http://localhost:3000";
  NUXT_PUBLIC_OAUTH_CLIENT_ID= throw "NUXT_PUBLIC_OAUTH_CLIENT_ID must be set in the .env";
  NUXT_PUBLIC_OAUTH_CLIENT_ID_MOBILE= throw "NUXT_PUBLIC_OAUTH_CLIENT_ID_MOBILE must be set in the .env";
  NUXT_PUBLIC_OAUTH_CALLBACK_URL = "http://localhost:3000/";
  NUXT_PUBLIC_OAUTH_CALLBACK_URL_MOBILE = "schule.beste:/";
};
in {
  # --- DOTENV ---
  # Make the values from the dotenv available in `config.env`
  # But this also makes values from `config.env` available as env variables from the shell
  dotenv.enable = true;

  # Declare the defaults of the env
  env = lib.attrsets.mapAttrs (key: value: lib.mkOptionDefault value) dotenvDefaults;

  # --- LANGUAGLES SETUP ---
  # Configure Node
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_18;
    npm.enable = true;
  };


  # --- ALL PROCESSES STARTED WITH `devenv up`
  process.manager.implementation = "overmind"; # for some reason, npm wont shut down with process-compose

  # custom processes
  processes = {
    nuxt.exec = "npm run dev";
  };


  # --- SCRIPTS ---
  scripts = {
    devshell-fetch = {
      description = ''
        Download the latest version of the beste.schule devenv environment from GitHub.
      '';
      exec = ''
        # Fetch all three files
        curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule-app/refs/heads/main/devenv.lock \
          > devenv.lock
        curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule-app/refs/heads/main/devenv.nix \
          > devenv.nix
        curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule-app/refs/heads/main/devenv.yaml \
          > devenv.yaml
      '';
    };
  };


  # --- SCRIPT ON ENTERING THE DEV SHELL ---
  # Greeting on entering the shell
  enterShell = let
    descriptionsOf = lib.lists.foldl (acc: name: acc + ''
      - `${name}` - ${config.scripts.${name}.description}
    '') "";
  in ''
    # --- Making sure that devenv files are excluded from git history
    excludeGit=".git/info/exclude"
    files=".devenv devenv.nix devenv.yaml devenv.lock .devenv.flake.nix"
    for file in $files; do
      if ! grep -q "$file" "$excludeGit"; then
        echo Adding "$file" to "$excludeGit"
        echo "$file" >> "$excludeGit"
      fi
    done

    # --- Add a declaration to the .env file if a variable is missing using the defaults from above
    ${lib.attrsets.foldlAttrs (acc: name: value: acc + ''
    if ! grep -q ${name} .env; then
      echo '${name}=${config.env.${name}}' >> .env
      echo ${name} not found in .env file. Adding it with a default value.
    fi
    '') "" dotenvDefaults}

    # --- Show a welcome message
    echo -e '
    # Welcome to the android beste.schule app developer shell

    **Available commands:**
    - `devenv up` - starts all necessary services
    - `npm install` - install dependencies
    ${descriptionsOf ["devshell-fetch"]}
    '\
    | glow
  '';


  # --- ADDITIONAL PACKAGES ---
  packages = with pkgs; [
    glow # Terminal markdown
    curl # Fetch stuff
  ];

  # --- MISC ---
  # Disable cachix (disable the warning that the user might not be a trusted user of the nix store)
  cachix.enable = false;
}
