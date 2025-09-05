class KFWeapAttach_Wildcat extends KFWeaponAttachment;

var protected transient float ReloadAnimRateMod;

// Caching reload anim name
simulated event PreBeginPlay()
{
	Super.PreBeginPlay();

	ReloadAnimRateMod = class'KFWeap_Wildcat'.default.ReloadAnimRateModifier;
	ReloadAnimRateMod = class'KFWeap_Wildcat'.default.ReloadAnimRateModifierElite;
}

defaultproperties
{

}