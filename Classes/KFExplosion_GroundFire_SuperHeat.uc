class KFExplosion_GroundFire_SuperHeat extends KFExplosionActorLingering;

/** Replacement particles to play when hitting surfaces at different angles */
//var() ParticleSystem LoopingParticleEffectCeiling;
//var() ParticleSystem LoopingParticleEffectWall;

/*
struct CachedExplosionInfo
{
	var GameExplosion ExplosionTemplate;
	var vector Direction;
};

// Cached information about the explosion in case we need to delay it
var CachedExplosionInfo CachedExplosion;

// How long should the explosion be delayed after initial impact
var float ExplosionDelay;

simulated function Explode(GameExplosion NewExplosionTemplate, optional vector Direction)
{
	if (ExplosionDelay > 0)
	{
		CachedExplosion.ExplosionTemplate = NewExplosionTemplate;
		CachedExplosion.Direction = Direction;
		SetTimer(ExplosionDelay, false, 'Timer_DelayExplosion');
	}
	else
	{
		super.Explode(NewExplosionTemplate, Direction);
	}
}

simulated function Timer_DelayExplosion()
{
	super.Explode(CachedExplosion.ExplosionTemplate, CachedExplosion.Direction);
}
*/

defaultproperties
{
	// ExplosionDelay=0.1f // 0.3
	// bDoFullDamage=true

	LoopingParticleEffect=ParticleSystem'DROW_EMIT.FX_SuperHeat_groundfire'
	//LoopingParticleEffectCeiling=ParticleSystem'WEP_3P_Molotov_EMIT.FX_Molotov_Grenade_Spread_Ceiling_01'
	//LoopingParticleEffectWall=ParticleSystem'WEP_3P_Molotov_EMIT.FX_Molotov_Grenade_Spread_Wall_01'

	LoopStartEvent=AkEvent'WW_WEP_SA_Flamethrower.Play_WEP_SA_Flamethrower_Residual_Fire_Loop'
    LoopStopEvent=AkEvent'WW_WEP_SA_Flamethrower.Stop_WEP_SA_Flamethrower_Residual_Fire_Loop'
}