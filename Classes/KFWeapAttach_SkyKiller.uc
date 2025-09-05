class KFWeapAttach_SkyKiller extends KFWeaponAttachment;

// Effect that happens while charging up the beam
var transient ParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleEffect;

const SecondaryFireAnim                   = 'Shoot_Secondary';
const SecondaryFireAnimCrouch             = 'Shoot_Secondary_CH';
const SecondaryFireIronAnim               = 'Shoot_Secondary_Iron';
const SecondaryFireBodyAnim               = 'ADD_Shoot_Secondary';
const SecondaryFireBodyAnimCH             = 'ADD_Shoot_Secondary_CH';
const SecondaryFireBodyAnimIron           = 'ADD_Shoot_Secondary_Iron';

// Plays fire animation on weapon mesh
simulated function PlayWeaponFireAnim()
{
	local float Duration;
	local name Anim;

	if ( Instigator.bIsWalking )
	{
        if (Instigator.FiringMode == 0) // DEFAULT FIRE MODE
        {
            Anim = WeaponIronFireAnim;
        }
        else if (Instigator.FiringMode == 1)
        {
            Anim = SecondaryFireIronAnim;
        }
	}
	else
	{
        if (Instigator.FiringMode == 0) // ALT FIRE MODE
        {
            Anim = WeaponFireAnim;
        }
        else if (Instigator.FiringMode == 1)
        {
            Anim = Instigator.bIsCrouched ? SecondaryFireAnimCrouch : SecondaryFireAnim;
        }
	}

    Duration = WeapMesh.GetAnimLength( Anim );
    WeapMesh.PlayAnim( Anim, Duration / ThirdPersonAnimRate,, true );
}

/** Plays fire animation on pawn */
simulated function PlayPawnFireAnim( KFPawn P, EAnimSlotStance AnimType )
{
	if (P.FiringMode == 0)
	{
		super.PlayPawnFireAnim(P, AnimType);
	}
	else if (P.FiringMode == 1)
	{
		if ( P.bIsCrouched )
		{
			P.PlayBodyAnim(SecondaryFireBodyAnimCH, AnimType, ThirdPersonAnimRate, ShootBlendInTime, ShootBlendOutTime);
		}
		else if ( P.bIsWalking )
		{
			P.PlayBodyAnim(SecondaryFireBodyAnimIron, AnimType, ThirdPersonAnimRate, ShootBlendInTime, ShootBlendOutTime);
		}
		else
		{
			P.PlayBodyAnim(SecondaryFireBodyAnim, AnimType, ThirdPersonAnimRate, ShootBlendInTime, ShootBlendOutTime);
		}
	}
}

simulated function SetWeaponAltFireMode(bool bUsingAltFireMode)
{
	ToggleParticleFX(bUsingAltFireMode);
}

simulated function ToggleParticleFX(bool bEnable)
{
	if (bEnable)
	{
		// setup and play the beam charge particle system
		if (ParticlePSC == none)
		{
			ParticlePSC = new(self) class'ParticleSystemComponent';
	
			if (WeapMesh != none)
			{
				WeapMesh.AttachComponentToSocket(ParticlePSC, 'ParticleFX');
			}
			else
			{
				AttachComponent(ParticlePSC);
			}
		}
		else
		{
			ParticlePSC.ActivateSystem();
		}
	
		if (ParticlePSC != none)
		{
			ParticlePSC.SetTemplate(ParticleEffect);
			// ParticlePSC.SetAbsolute(false, false, false);
		}
	}
	else
	{
		ParticlePSC.DeactivateSystem();
	}
}

// Attach weapon to owner's skeletal mesh
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
	}

	// Additional attachments
	if( bHasLaserSight && !P.IsFirstPerson() )
	{
		AttachLaserSight();
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

	if (P.MyKFWeapon != none && P.MyKFWeapon.bUseAltFireMode)
	{
		ToggleParticleFX(true);
	}
}

simulated function DetachFrom(KFPawn P)
{
	if (ParticlePSC != none)
	{
		ParticlePSC.DeactivateSystem();
		ParticlePSC.DetachFromAny();
	}

    Super.DetachFrom(P);
}

// Spawn tracer effects for this weapon
simulated function SpawnTracer(vector EffectLocation, vector HitLocation)
{
	local ParticleSystemComponent E;
	local vector Dir;
	local float DistSQ;
	local float TracerDuration;
	local KFTracerInfo TracerInfo;

	if ( Instigator == None || Instigator.FiringMode >= TracerInfos.Length )
	{
		return;
	}

	TracerInfo = TracerInfos[Instigator.FiringMode];
    if( ((`NotInZedTime(self) && TracerInfo.bDoTracerDuringNormalTime)
        || (`IsInZedTime(self) && TracerInfo.bDoTracerDuringZedTime))
        && TracerInfo.TracerTemplate != none )
    {
        Dir = HitLocation - EffectLocation;
		DistSQ = VSizeSq(Dir);
    	if ( DistSQ > TracerInfo.MinTracerEffectDistanceSquared )
    	{
    		// Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
			TracerDuration = fMin( (Sqrt(DistSQ) - 100.f) / TracerInfo.TracerVelocity, 1.f );
			if( TracerDuration > 0.f )
			{
	    		E = WorldInfo.MyEmitterPool.SpawnEmitter( TracerInfo.TracerTemplate, EffectLocation, rotator(Dir) );
				E.SetVectorParameter('Shotend', HitLocation);
	 			E.SetFloatParameter( 'Tracer_Lifetime', TracerDuration );
	 		}
    	}
	}
}

defaultproperties
{
	ParticleEffect=ParticleSystem'DROW_EMIT.FX_SkyKiller_ALT_Particle'
}