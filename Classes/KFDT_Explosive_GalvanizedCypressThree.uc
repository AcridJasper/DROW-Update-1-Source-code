class KFDT_Explosive_GalvanizedCypressThree extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	// physics impact
	RadialDamageImpulse=10000
	KDeathUpKick=2000
	KDeathVel=500

	KnockdownPower=20
	StumblePower=50 //100

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_GalvanizedCypressThree'
}