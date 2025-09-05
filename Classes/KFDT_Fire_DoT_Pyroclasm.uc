class KFDT_Fire_DoT_Pyroclasm extends KFDT_Fire
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
	WeaponDef=class'KFWeapDef_Pyroclasm'

	bStackDoT=true
	DoT_Type=DOT_Fire
	DoT_Duration=8.0
	DoT_Interval=0.4
	DoT_DamageScale=0.2

	SelfDamageReductionValue=0.05f //0.25f

	BurnPower=40 //150
	
	ForceImpactEffect=ParticleSystem'DROW_EMIT.FX_Pyroclasm_Impact_DoT'
	// ForceImpactSound=AkEvent'WW_WEP_SA_DragonsBreath.Play_Bullet_DragonsBreath_Impact_Dirt'

	// OverrideImpactEffect=ParticleSystem'WEP_DragonsBreath_EMIT.FX_DragonsBreath_Impact_E'
	// OverrideImpactSound=AkEvent'WW_WEP_SA_DragonsBreath.Play_Bullet_DragonsBreath_Impact_Dirt'
}