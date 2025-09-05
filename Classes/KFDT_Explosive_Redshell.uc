class KFDT_Explosive_Redshell extends KFDT_Explosive
	abstract
	hidedropdown;

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

	KnockdownPower=250
	StumblePower=450

	ModifierPerkList(0)=class'KFPerk_Demolitionist'

	WeaponDef=class'KFWeapDef_Redshell'
}