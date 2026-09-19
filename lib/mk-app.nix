{ lib, ... }:
{ package, description }:
{
  type = "app";
  program = lib.getExe package;
  meta = {
    inherit description;
  };
}
