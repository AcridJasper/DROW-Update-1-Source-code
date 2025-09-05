class KFDT_Explosive_Beacon extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=10000
	GibImpulseScale=0.15
	KDeathUpKick=1500//2000
	KDeathVel=1500

	KnockdownPower=1225
	StumblePower=1200

	ModifierPerkList(0)=class'KFPerk_Demolitionist'

	WeaponDef=class'KFWeapDef_Grenade_Beacon'
}