{ gitlab-runner, ... }:
gitlab-runner.overrideAttrs (
  _: previousAttrs: {
    patches = (previousAttrs.patches or [ ]) ++ [ ./services_cap_add.patch ];
    doCheck = false;
  }
)
