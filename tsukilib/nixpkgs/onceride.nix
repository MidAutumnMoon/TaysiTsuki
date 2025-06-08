lib:

{

  # onceride ::
  #  what override accepts -> what overrideAttrs accepts -> new derivation
  #
  # Mess around another mess.
  #
  onceride =
    drv: overrideEssence: overrideAttrsEssence:
      ( drv.override overrideEssence ).overrideAttrs overrideAttrsEssence;

  # onceride' ::
  #  what override accepts -> what overrideDerivation accepts -> new derivation
  #
  # Sometimes overrideAttrs is simply not enough.
  #
  oncerideDrv =
    drv: overrideEssence: overrideDrvEssence:
      ( drv.override overrideEssence ).overrideDerivation overrideDrvEssence;

}
