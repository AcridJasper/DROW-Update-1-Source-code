class KFDT_Fire_DoT_SuperHeat extends KFDT_Fire
	abstract
	hidedropdown;

defaultproperties
{
	WeaponDef=class'KFWeapDef_SuperHeat'

	DoT_Type=DOT_Fire
	DoT_Duration=5.0 //3
	DoT_Interval=0.5
	DoT_DamageScale=0.4

	// Don't do damage to teammates
	bNoFriendlyFire=true
	bIgnoreSelfInflictedScale=true
	
	BurnPower=12 //9
}