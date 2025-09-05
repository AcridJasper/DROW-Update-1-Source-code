class KFExplosion_Redshell extends KFExplosionActorLingering;

/*
var KFTrigger_HellishShield ShieldTrigger;
var() float ShieldLifetime;

simulated function PostBeginPlay()
{
	if (ShieldTrigger == none)
	{
		ShieldTrigger = Spawn(class'KFTrigger_HellishShield', self);
	}

	if( Role == ROLE_Authority )
	{
		// SetTimer(ShieldLifetime, false, 'Timer_DestroyShield');
		SetTimer(ShieldLifetime, false, nameof(Timer_DestroyShield), self);
	}

	super.PostBeginPlay();
}

// Destroy the shield
function Timer_DestroyShield()
{
	DestroyShield();
}

function DestroyShield()
{
	if (ShieldTrigger != none)
	{
		ShieldTrigger.Destroy();
		ShieldTrigger = none;
	}
}

simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_DestroyShield));
	}
}
*/

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
	MaxTime=6.0 //13.0
	Interval=0.5

	// ShieldLifetime=5.0 //10

	LoopingParticleEffect=ParticleSystem'DROW_EMIT.FX_Heat_Orb'

	LoopStartEvent=AkEvent'WW_ZED_Matriarch.Play_Matriarch_SFX_Cloak'
	LoopStopEvent=AkEvent'WW_ZED_Matriarch.Stop_Matriarch_SFX_Cloak' 
}