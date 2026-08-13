{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        go = "latest";
        node = "lts";
        rust = "stable";
      };

      settings = {
        idiomatic_version_file_enable_tools = [
          "go"
          "node"
          "rust"
        ];
      };
    };
  };
}
