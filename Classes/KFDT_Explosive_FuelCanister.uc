class KFDT_Explosive_FuelCanister extends KFDT_Explosive
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

	bCanEnrage=false
	
	KnockdownPower=225
	StumblePower=400

	ModifierPerkList(0)=class'KFPerk_Firebug'
	WeaponDef=class'KFWeapDef_Grenade_FuelCanister'
}