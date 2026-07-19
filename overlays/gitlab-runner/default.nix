{
  gitlab-runner,
  fetchFromGitLab,
  ...
}:
gitlab-runner.overrideAttrs (
  finalAttrs: previousAttrs: {
    version = "19.2.0";

    src = fetchFromGitLab {
      owner = "gitlab-org";
      repo = "gitlab-runner";
      tag = "v${finalAttrs.version}";
      hash = "sha256-aWX506nR7yPHWIXBQq/Mwu+EFoa4DYKCjKNT74A85xs=";
    };

    vendorHash = "sha256-kznAIKiJUZUkoNQSsnl6pj4SZspErccc6rmGwuc7iKo=";

    patches = (previousAttrs.patches or [ ]) ++ [
      ./services_cap_add.patch
    ];
    doCheck = false;
  }
)
