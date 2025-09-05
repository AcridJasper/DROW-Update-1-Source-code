class KFDT_Explosive_Tesla extends KFDT_Explosive
	abstract
	hidedropdown; //KFDT_EMP

defaultproperties
{
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=2500//10000
	GibImpulseScale=0.15
	KDeathUpKick=1500//2000
	KDeathVel=500

	// EMP
	EMPPower=25 //200
	GoreDamageGroup=DGT_EMP
	// EffectGroup=FXG_Electricity

	KnockdownPower=10 //225
	StumblePower=200

	ModifierPerkList(0)=class'KFPerk_Survivalist'
	// ModifierPerkList(1)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_Grenade_Tesla'
}