class KFDT_GroundFire_SuperHeat extends KFDT_Fire_Ground
	abstract;

defaultproperties
{
	WeaponDef=class'KFWeapDef_SuperHeat'

	DoT_Type=DOT_Fire
	DoT_Duration=3.0
	DoT_Interval=0.5
	DoT_DamageScale=0.4

	// Don't do damage to teammates
	bNoFriendlyFire=true
	bIgnoreSelfInflictedScale=true

	BurnPower=7 //10.5
}