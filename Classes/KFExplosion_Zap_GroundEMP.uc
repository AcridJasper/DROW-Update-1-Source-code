class KFExplosion_Zap_GroundEMP extends KFExplosionActorLingering;

// Replacement particles to play when hitting surfaces at different angles
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
	bDoFullDamage=true

	LoopingParticleEffect=ParticleSystem'DROW_EMIT.FX_Zap_GroundElectricity'
	//LoopingParticleEffectCeiling=ParticleSystem'WEP_SaberCat_EMIT.FX_SaberCat_LingeringIce_Ceiling'
	//LoopingParticleEffectWall=ParticleSystem'WEP_SaberCat_EMIT.FX_SaberCat_LingeringIce_Wall'

	// LoopStartEvent=AkEvent'WW_ENV_EndlessArena.Play_SFX_KFArena_ElectricBarrier_LP'
    // LoopStopEvent=AkEvent'WW_WEP_EXP_Grenade_Medic.Stop_WEP_EXP_Grenade_Medic_Smoke_Loop'
}