class KFExplosion_EntryPortal_ZED extends KFExplosionActorLingering;

// Overriden to SetAbsolute
simulated function StartLoopingParticleEffect()
{
	LoopingPSC = new(self) class'ParticleSystemComponent';
	LoopingPSC.SetTemplate( LoopingParticleEffect );
	AttachComponent(LoopingPSC);
	LoopingPSC.SetAbsolute(false, true, false);
}

DefaultProperties
{
	MaxTime=25.0 //13.0
	Interval=0.5

	LoopingParticleEffect=ParticleSystem'DROW_EMIT.FX_EntryPortal_ZED_Portal'

	LoopStartEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
	LoopStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'
}