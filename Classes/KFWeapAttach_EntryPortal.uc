class KFWeapAttach_EntryPortal extends KFWeapAttach_SprayBase; //KFWeaponAttachment;

// Effect that happens while charging up the beam
var transient ParticleSystemComponent FirePSC;
var const ParticleSystem FireEffect;

var AkEvent AmbientSoundPlayEvent;
var AkEvent	AmbientSoundStopEvent;

// Starts playing looping ambient sound
simulated function StartAmbientSound()
{
	if( Instigator != none && !Instigator.IsFirstPerson() )
	{
		if ( AmbientSoundPlayEvent != None )
		{
        	Instigator.PlaySoundBase(AmbientSoundPlayEvent, true, true, true,, true);
		}
    }
}

// Stops playing looping ambient sound
simulated function StopAmbientSound()
{
	if ( AmbientSoundStopEvent != None )
	{
    	Instigator.PlaySoundBase(AmbientSoundStopEvent, true, true, true,, true);
    }
}

/** Attach weapon to owner's skeletal mesh */
simulated function AttachTo(KFPawn P)
{
	local byte WeaponAnimSetIdx;

    if ( bWeapMeshIsPawnMesh )
	{
		WeapMesh = P.Mesh;
	}
	else if ( WeapMesh != None )
	{
		// Attach Weapon mesh to player skel mesh
		WeapMesh.SetShadowParent(P.Mesh);
		P.Mesh.AttachComponent(WeapMesh, 'RW_Weapon');

		// Keep the arrow from the weapon mesh unvisible
		//WeapMesh.HideBoneByName (ArrowSocketName, PBO_None);
	}

	// Animation
	if ( CharacterAnimSet != None )
	{
		WeaponAnimSetIdx = P.CharacterArch.GetWeaponAnimSetIdx();
		P.Mesh.AnimSets[WeaponAnimSetIdx] = CharacterAnimSet;
		// update animations will reload all AnimSeqs with the new AnimSet
		P.Mesh.UpdateAnimations();
	}

	// update aim offset nodes with new profile for this weapon
	P.SetAimOffsetNodesProfile(AimOffsetProfileName);

    StartAmbientSound();

	// setup and play the beam charge particle system
	if (FirePSC == none)
	{
		FirePSC = new(self) class'ParticleSystemComponent';

		if (WeapMesh != none)
		{
			WeapMesh.AttachComponentToSocket(FirePSC, 'FireFX');
		}
		else
		{
			AttachComponent(FirePSC);
		}
	}
	else
	{
		FirePSC.ActivateSystem();
	}

	if (FirePSC != none)
	{
		FirePSC.SetTemplate(FireEffect);
		// FirePSC.SetAbsolute(false, false, false);
		// FirePSC.SetTemplate(FireEffect);
	}
}

simulated function DetachFrom(KFPawn P)
{
    StopAmbientSound();

	if (FirePSC != none)
	{
		FirePSC.DeactivateSystem();
	}

    Super.DetachFrom(P);
}

simulated function Destroyed()
{
	StopAmbientSound();

	super.Destroyed();
}

// Spawn tracer effects for this weapon
simulated function SpawnTracer(vector EffectLocation, vector HitLocation)
{
	local ParticleSystemComponent PSC;
	local vector Dir;
	local float DistSQ;
	local float TracerDuration;
	local KFTracerInfo TracerInfo;

	if (Instigator == None || Instigator.FiringMode >= TracerInfos.Length)
	{
		return;
	}

	TracerInfo = TracerInfos[Instigator.FiringMode];
	if (((`NotInZedTime(self) && TracerInfo.bDoTracerDuringNormalTime)
		|| (`IsInZedTime(self) && TracerInfo.bDoTracerDuringZedTime))
		&& TracerInfo.TracerTemplate != none )
	{
		Dir = HitLocation - EffectLocation;
		DistSQ = VSizeSq(Dir);
		if (DistSQ > TracerInfo.MinTracerEffectDistanceSquared)
		{
			// Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
			TracerDuration = fMin((Sqrt(DistSQ) - 100.f) / TracerInfo.TracerVelocity, 1.f);
			if (TracerDuration > 0.f)
			{
				PSC = WorldInfo.MyEmitterPool.SpawnEmitter(TracerInfo.TracerTemplate, EffectLocation, rotator(Dir));
				PSC.SetFloatParameter('Tracer_Lifetime', TracerDuration);
				PSC.SetVectorParameter('Shotend', HitLocation);
			}
		}
	}
}

defaultproperties
{
	FireEffect=ParticleSystem'DROW_EMIT.FX_EntryPortal_FireFX'

	AmbientSoundPlayEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
	AmbientSoundStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'

	Begin Object Class=PointLightComponent Name=PilotPointLight0
		LightColor=(R=250,G=150,B=85,A=255)
		Brightness=0.125f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	PilotLights(0)=(Light=PilotPointLight0,LightAttachBone=FireFX)
}