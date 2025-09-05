class KFDT_Explosive_Bouncer_Bomblets extends KFDT_Explosive
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

	KnockdownPower=70 //150
	StumblePower=100 //350

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_Bouncer'
}