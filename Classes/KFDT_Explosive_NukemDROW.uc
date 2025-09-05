class KFDT_Explosive_NukemDROW extends KFDT_Explosive
	abstract
	hidedropdown;

// Damage type to use for the burning damage over time
var class<KFDamageType> BurnDamageType;

// Play damage type specific impact effects when taking damage
static function PlayImpactHitEffects(KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator)
{
	// Play burn effect when dead
	if (P.bPlayedDeath && P.WorldInfo.TimeSeconds > P.TimeOfDeath)
	{
		default.BurnDamageType.static.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
		return;
	}

	super.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
}

// Called when damage is dealt to apply additional damage type (e.g. Damage Over Time)
static function ApplySecondaryDamage(KFPawn Victim, int DamageTaken, optional Controller InstigatedBy)
{
	// Overriden to specific a different damage type to do the burn damage over
	// time. We do this so we don't get shotgun pellet impact sounds/fx during
	// the DOT burning.
	if (default.BurnDamageType.default.DoT_Type != DOT_None)
	{
		Victim.ApplyDamageOverTime(DamageTaken, InstigatedBy, default.BurnDamageType);
	}
}

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

	BurnPower=8 //12
	BurnDamageType=class'KFDT_Fire_DoT_NukemDROW'

	KnockdownPower=10 //225
	StumblePower=200

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_NukemDROW'
}