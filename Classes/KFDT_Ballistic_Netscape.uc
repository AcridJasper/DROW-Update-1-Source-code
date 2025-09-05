class KFDT_Ballistic_Netscape extends KFDT_Ballistic_AssaultRifle
	abstract
	hidedropdown;

// Damage type to use for the damage over time effect
var class<KFDamageType> DoTDamageType;

var ParticleSystem ForceImpactEffect;
// var AkEvent ForceImpactSound;

static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local KFSkinTypeEffects SkinType;

	if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
	{
		SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

		if (SkinType != none)
		{
			SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
			// SkinType.PlayTakeHitSound(P, HitLocation, HitInstigator, default.EffectGroup, default.ForceImpactSound);
		}
	}
}

/** Called when damage is dealt to apply additional damage type (e.g. Damage Over Time) */
static function ApplySecondaryDamage(KFPawn Victim, int DamageTaken, optional Controller InstigatedBy)
{
    if (Victim.Controller == InstigatedBy)
	{
        return;
	}

	if (default.DoTDamageType.default.DoT_Type != DOT_None)
	{
		Victim.ApplyDamageOverTime(DamageTaken, InstigatedBy, default.DoTDamageType);
	}
}

defaultproperties
{
    KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	DamageModifierAP=0.2f
	ArmorDamageModifier=4.0f

	StumblePower=15
	GunHitPower=25

	PoisonPower=100
    DoTDamageType=class'KFDT_Toxic_DoT_Netscape'

	WeaponDef=class'KFWeapDef_Netscape'

	ModifierPerkList(0)=class'KFPerk_Commando'
	ModifierPerkList(1)=class'KFPerk_Swat'

	//OverrideImpactEffect=ParticleSystem'Glitched_EMIT.FX_Laser_Impact_01'
	ForceImpactEffect=ParticleSystem'DROW_EMIT.FX_Netscape_Impact_ZED'
	// ForceImpactSound=AkEvent'WW_WEP_SA_DragonsBreath.Play_Bullet_DragonsBreath_Impact_Dirt'
}