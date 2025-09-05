class KFDT_Explosive_BuzzardALT extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=3000 //5000 //20000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=10
	StumblePower=20 //25

	ModifierPerkList(0)=class'KFPerk_Berserker'
	ModifierPerkList(1)=class'KFPerk_Survivalist'
	WeaponDef=class'KFWeapDef_Buzzard'
}