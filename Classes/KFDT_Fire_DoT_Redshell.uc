class KFDT_Fire_DoT_Redshell extends KFDT_Fire
	abstract
	hidedropdown;

defaultproperties
{
	WeaponDef=class'KFWeapDef_Redshell'

	DoT_Type=DOT_Fire
	DoT_Duration=5.0
	DoT_Interval=0.4
	DoT_DamageScale=0.4

	bIgnoreSelfInflictedScale=true
	SelfDamageReductionValue=0f

	BurnPower=50 //45
}