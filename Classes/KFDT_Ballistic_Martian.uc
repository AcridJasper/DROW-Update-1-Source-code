class KFDT_Ballistic_Martian extends KFDT_Ballistic_Handgun
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
    KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	DamageModifierAP=0.2f
	ArmorDamageModifier=4.0f

	StumblePower=18
	GunHitPower=15

	WeaponDef=class'KFWeapDef_Martian'

	ModifierPerkList(0)=class'KFPerk_Gunslinger'

	ForceImpactEffect=ParticleSystem'DROW_EMIT.FX_Martian_Impact_ZED'
	// ForceImpactSound=AkEvent'WW_WEP_SA_DragonsBreath.Play_Bullet_DragonsBreath_Impact_Dirt'
}