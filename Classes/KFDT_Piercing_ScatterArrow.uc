class KFDT_Piercing_ScatterArrow extends KFDT_Piercing
	abstract
	hidedropdown;

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

defaultproperties
{
	KDamageImpulse=1500
	KDeathUpKick=250
	KDeathVel=150

    KnockdownPower=20
	StunPower=101
	StumblePower=250
	GunHitPower=150
	MeleeHitPower=40

	ForceImpactEffect=ParticleSystem'WEP_HVStormCannon_EMIT.FX_HVStormCannon_Impact_Zed'
	// ForceImpactSound=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Impact'

	ModifierPerkList(0)=class'KFPerk_Sharpshooter'
	WeaponDef=class'KFWeapDef_ScatterArrow'
}