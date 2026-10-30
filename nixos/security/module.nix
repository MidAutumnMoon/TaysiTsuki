{ lib, ... }:

{
    security.pam.services.su.forwardXAuth = lib.mkForce false;
}
