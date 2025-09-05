class KFExplosion_Grenade_GalvanizedCypressThree extends KFExplosionActorLingering;

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
	// ExplosionDelay=0.2f // 0.3
	bDoFullDamage=true

	LoopingParticleEffect=ParticleSystem'DROW_EMIT.FX_GalvanizedCypressThree_Grenade_LingeringIce'

	LoopStartEvent=AkEvent'WW_WEP_EXP_Grenade_Medic.Play_WEP_EXP_Grenade_Medic_Smoke_Loop'
    LoopStopEvent=AkEvent'WW_WEP_EXP_Grenade_Medic.Stop_WEP_EXP_Grenade_Medic_Smoke_Loop'
}