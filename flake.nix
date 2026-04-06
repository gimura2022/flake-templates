{
  description = "flake templates";

  outputs = {
    templates = {
      rust-app = {
        path = ./templates/rust-app;
        description = "simple rust app";
      };

      rust-lib = {
        path = ./templates/rust-lib;
        description = "only dev shell for rust";
      };

      rust-bevy = {
        path = ./templates/rust-bevy;
        description = "rust bevy app";
      };
    };
  };
}
