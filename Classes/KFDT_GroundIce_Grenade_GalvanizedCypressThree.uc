class KFDT_GroundIce_Grenade_GalvanizedCypressThree extends KFDT_Freeze
	abstract;

/** Play damage type specific impact effects when taking damage */
static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local float ParamValue;
    local int MICIndex;

    MICIndex = 0;
    if (P.GetCharacterInfo() != none)
    {
        MICIndex = P.GetCharacterInfo().GoreFXMICIdx;
    }

	// If we're dead and not already frozen (prevents re-shattering)
	if ( P.bPlayedDeath 
		&& P.CharacterMICs.Length > MICIndex 
		&& P.CharacterMICs[MICIndex].GetScalarParameterValue('Scalar_Ice', ParamValue))
	{
		if (ParamValue == 0)
		{
			PlayShatter(P, false, `TimeSinceEx(P, P.TimeOfDeath) > 0.5f, HitDirection * default.KDeathVel);
			return;
		}
	}

	Super.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);
}

defaultproperties
{
	//return `DAMZ_Freeze;
	//return `KILL_Freeze;

    // DoT
	DoT_Type=DOT_None // don't disturb the zed
	DoT_Duration=2.0
	DoT_Interval=0.5
	DoT_DamageScale=0.4

	bIgnoreSelfInflictedScale=true

	FreezePower=50 // 5

	WeaponDef=class'KFWeapDef_GalvanizedCypressThree'
}