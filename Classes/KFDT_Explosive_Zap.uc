class KFDT_Explosive_Zap extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=10000
	KDeathUpKick=2000
	KDeathVel=500

	GoreDamageGroup=DGT_EMP

	KnockdownPower=40
	StumblePower=120
	EMPPower=20 //55

	ModifierPerkList(0)=class'KFPerk_Survivalist'
	WeaponDef=class'KFWeapDef_Zap'
}