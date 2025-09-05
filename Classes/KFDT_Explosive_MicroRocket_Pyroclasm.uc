class KFDT_Explosive_MicroRocket_Pyroclasm extends KFDT_Explosive
	abstract
	hidedropdown;

// Damage type to use for the burning damage over time
var class<KFDamageType> BurnDamageType;

/** Called when damage is dealt to apply additional damage type (e.g. Damage Over Time) */
static function ApplySecondaryDamage( KFPawn Victim, int DamageTaken, optional Controller InstigatedBy )
{	
	// Overriden to specific a different damage type to do the burn damage over
	// time. We do this so we don't get shotgun pellet impact sounds/fx during
	// the DOT burning.
    if ( default.BurnDamageType.default.DoT_Type != DOT_None )
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
	RadialDamageImpulse=10000
	KDeathUpKick=2000
	KDeathVel=500

	KnockdownPower=80
	StumblePower=150

	// BurnPower=10
	BurnDamageType=class'KFDT_Fire_DoT_Pyroclasm'

	ModifierPerkList(0)=class'KFPerk_Firebug'
	ModifierPerkList(1)=class'KFPerk_Support'

	WeaponDef=class'KFWeapDef_Pyroclasm'
}