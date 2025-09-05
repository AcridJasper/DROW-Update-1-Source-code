class KFDT_Fire_DoT_NukemDROW extends KFDT_Fire
	abstract
	hidedropdown;

defaultproperties
{
	WeaponDef=class'KFWeapDef_NukemDROW'

	DoT_Type=DOT_Fire
	DoT_Duration=2.0 //5.0
	DoT_Interval=0.5
	DoT_DamageScale=0.4 //0.3 0.7 1.0

	bIgnoreSelfInflictedScale=true
	bNoInstigatorDamage=true

	BurnPower=6 //8.5 18.5
}