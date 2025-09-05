class KFPowerUp_DROW extends KFPowerUp;

static function PlayEffects( KFPawn_Human P )
{
	local ParticleSystemComponent ParticleEffect;

	if( default.PowerUpEffect != none )
	{
		ParticleEffect = P.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(default.PowerUpEffect, P.Mesh, 'Hips', false);
		ParticleEffect.SetAbsolute(false, true, true);
		P.CurrentPowerUpEffect.PowerUpType = default.class;
		P.CurrentPowerUpEffect.ParticleEffect = ParticleEffect;
	}
}

DefaultProperties
{

}