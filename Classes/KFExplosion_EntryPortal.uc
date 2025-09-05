class KFExplosion_EntryPortal extends KFExplosionActorLingering;

var PointLightComponent RayLight;
var LightPoolPriority RayLightPriority;

var KFTrigger_HellishShield ShieldTrigger;
var() float ShieldLifetime;

// var() float ZEDSpawntime;
// var() float ZEDSpawntime1;
// var() float ZEDSpawntime2;

// var() float ZEDSpawntimeFP;
// var() float ZEDSpawntimeSC;

// var float RandomZEDChance;

simulated function PostBeginPlay()
{
	if (ShieldTrigger == none)
	{
		ShieldTrigger = Spawn(class'KFTrigger_HellishShield', self);
	}

	if( Role == ROLE_Authority ) //&& FRand() < RandomZEDChance )
	{
		// SetTimer(ShieldLifetime, false, 'Timer_DestroyShield');
		SetTimer(ShieldLifetime, false, nameof(Timer_DestroyShield), self);
		// SetTimer(ZEDSpawntimeFP, false, nameof(Timer_SpawnFriendlyFP));
		// SetTimer(ZEDSpawntimeSC, false, nameof(Timer_SpawnFriendlySC));

		// SetTimer(ZEDSpawntime, false, nameof(Timer_SpawnFriendly));
		// SetTimer(ZEDSpawntime1, false, nameof(Timer_SpawnFriendly1));
		// SetTimer(ZEDSpawntime2, false, nameof(Timer_SpawnFriendly2));
	}

    // Set its light if it has one
    if ( RayLight != None )
    {
        AttachComponent(RayLight);
        `LightPool.RegisterPointLight(RayLight, RayLightPriority);
    }

	super.PostBeginPlay();
}

// Destroy the shield
function Timer_DestroyShield()
{
	DestroyShield();
}

// Destroys the shield
function DestroyShield()
{
	if (ShieldTrigger != none)
	{
		ShieldTrigger.Destroy();
		ShieldTrigger = none;
	}
}

// Also destroys the shield
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_DestroyShield));
	}
}

/** Fades explosion actor out over a couple seconds */
simulated function FadeOut( optional bool bDestroyImmediately )
{
	if( bWasFadedOut )
	{
		return;
	}

	bWasFadedOut = true;

	if( WorldInfo.NetMode != NM_DedicatedServer && LoopStopEvent != none )
	{
		PlaySoundBase( LoopStopEvent, true );
	}

	StopLoopingParticleEffect();

	if( !bDeleteMe && !bPendingDelete )
	{
		SetTimer(FadeOutTime, false, nameOf(Destroy));
	}

	// Disable flight light if it has one
    if ( RayLight != None && RayLight.bAttached )
    {
        DetachComponent(RayLight);
    }
}

// function Timer_SpawnFriendlyFP()
// {
// 	SpawnFriendlyFleshpound();
// }

// function Timer_SpawnFriendlySC()
// {
// 	SpawnFriendlyScrake();
// }

// simulated function SpawnFriendlyFleshpound(optional float Distance = 0.f)
// {
//     local class<KFPawn_Monster> MonsterClass;
// 	local KFPawn ZED;
//     local vector SpawnLoc;
//     local rotator SpawnRot;

//     MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("DROW.Hell", class'Class'));

//     SpawnLoc = Location;

//    	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
//    	SpawnRot.Yaw = Rotation.Yaw + 32768;

//     ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
// 	if ( ZED != None )
// 	{
// 		ZED.SpawnDefaultController();
// 		if( KFAIController(ZED.Controller) != none )
// 		{
// 			// Set team to human team
// 			KFAIController( ZED.Controller ).SetTeam(0);
// 		}

// 		ZED.SetPhysics(PHYS_Falling);
// 	}
// }

/*
simulated function SpawnFriendlyScrake(optional float Distance = 0.f)
{
    local class<KFPawn_Monster> MonsterClass;
	local KFPawn ZED;
    local vector SpawnLoc;
    local rotator SpawnRot;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("KFGameContent.KFPawn_ZedScrake_Versus", class'Class'));

    SpawnLoc = Location;

   	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
   	SpawnRot.Yaw = Rotation.Yaw + 32768;

    ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
	if ( ZED != None )
	{
		ZED.SpawnDefaultController();
		if( KFAIController(ZED.Controller) != none )
		{
			// Set team to human team
			KFAIController( ZED.Controller ).SetTeam(0);
		}

		ZED.SetPhysics(PHYS_Falling);
	}
}
*/

/*
function Timer_SpawnFriendly()
{
	SpawnFriendlyClot();
}

function Timer_SpawnFriendly1()
{
	SpawnFriendlyGorefast();
}

function Timer_SpawnFriendly2()
{
	SpawnFriendlyCrawler();
}

simulated function SpawnFriendlyClot(optional float Distance = 0.f)
{
    local class<KFPawn_Monster> MonsterClass;
	local KFPawn ZED;
    local vector SpawnLoc;
    local rotator SpawnRot;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("DROW.KFPawn_Infernal_Clot_Alpha", class'Class'));

    SpawnLoc = Location;

   	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
   	SpawnRot.Yaw = Rotation.Yaw + 32768;

    ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
	if ( ZED != None )
	{
		ZED.SetPhysics(PHYS_Falling);
		ZED.SpawnDefaultController();
		if( KFAIController(ZED.Controller) != none )
		{
			// Set team to human team
			KFAIController( ZED.Controller ).SetTeam(0);
		}
	}
}

simulated function SpawnFriendlyGorefast(optional float Distance = 0.f)
{
    local class<KFPawn_Monster> MonsterClass;
	local KFPawn ZED;
    local vector SpawnLoc;
    local rotator SpawnRot;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("DROW.KFPawn_Infernal_Gorefast_DualBlade", class'Class'));

    SpawnLoc = Location;

   	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
   	SpawnRot.Yaw = Rotation.Yaw + 32768;

    ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
	if ( ZED != None )
	{
		ZED.SetPhysics(PHYS_Falling);
		ZED.SpawnDefaultController();
		if( KFAIController(ZED.Controller) != none )
		{
			// Set team to human team
			KFAIController( ZED.Controller ).SetTeam(0);
		}
	}
}

simulated function SpawnFriendlyCrawler(optional float Distance = 0.f)
{
    local class<KFPawn_Monster> MonsterClass;
	local KFPawn ZED;
    local vector SpawnLoc;
    local rotator SpawnRot;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("DROW.KFPawn_Infernal_Crawler", class'Class'));

    SpawnLoc = Location;

   	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
   	SpawnRot.Yaw = Rotation.Yaw + 32768;

    ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
	if ( ZED != None )
	{
		ZED.SetPhysics(PHYS_Falling);
		ZED.SpawnDefaultController();
		if( KFAIController(ZED.Controller) != none )
		{
			// Set team to human team
			KFAIController( ZED.Controller ).SetTeam(0);
		}
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
	MaxTime=25.0 //13.0
	Interval=0.5

	ShieldLifetime=20.0 //10
	
	// ZEDSpawntime=3.0
	// ZEDSpawntime1=6.0
	// ZEDSpawntime2=10.0

	// ZEDSpawntimeFP=7.0
	// ZEDSpawntimeSC=8.0

	// RandomZEDChance=0.3

	Begin Object Class=PointLightComponent Name=PointLight0
	    LightColor=(R=250,G=160,B=100,A=255)
		Brightness=1.5f
		Radius=1500.f
		FalloffExponent=3.0f
		CastShadows=FALSE
		CastStaticShadows=false
		CastDynamicShadows=false
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	RayLight=PointLight0
	RayLightPriority=LPP_High

	LoopingParticleEffect=ParticleSystem'DROW_EMIT.FX_FriendlyZED_Portal'

	LoopStartEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
	LoopStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'
}