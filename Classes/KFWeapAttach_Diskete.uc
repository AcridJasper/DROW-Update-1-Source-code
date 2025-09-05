class KFWeapAttach_Diskete extends KFWeaponAttachment;

// Effect that happens while charging up the beam
var transient ParticleSystemComponent LensPSC;
var const ParticleSystem LensEffect;

// Eviscerator

var AnimTree CustomAnimTree;
const WeaponShoot = 'Shoot';

event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	// Override the animtree.  Doing this here (before AttachTo) instead of in defaultprops 
	// avoids an undesired call to our owning Pawn's PostInitAnimTree
	if ( CustomAnimTree != None )
	{
		WeapMesh.SetAnimTreeTemplate(CustomAnimTree);
		WeapAnimNode = AnimNodeSequence(AnimTree(WeapMesh.Animations).Children[0].Anim);
	}
}

// Custom firing animations
simulated function bool ThirdPersonFireEffects(vector HitLocation, KFPawn P, byte ThirdPersonAnimRateByte )
{
	local float Duration;

	if( Super.ThirdPersonFireEffects(HitLocation, P, ThirdPersonAnimRateByte) )
	{
		Duration = WeapMesh.GetAnimLength( WeaponShoot );
		WeapMesh.PlayAnim( WeaponShoot, Duration / ThirdPersonAnimRate );
		return true;
	}

	return false;
}

// Particle system

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
		P.Mesh.AttachComponent(WeapMesh, P.WeaponAttachmentSocket);
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

	// ----------------------------------------------------------
	// setup and play the beam charge particle system
	if (LensPSC == none)
	{
		LensPSC = new(self) class'ParticleSystemComponent';

		if (WeapMesh != none)
		{
			WeapMesh.AttachComponentToSocket(LensPSC, 'MuzzleFlash');
		}
		else
		{
			AttachComponent(LensPSC);
		}
	}
	else
	{
		LensPSC.ActivateSystem();
	}
	if (LensPSC != none)
	{
		LensPSC.SetTemplate(LensEffect);
	}
}

simulated function DetachFrom(KFPawn P)
{
	// detach effects
	if (MuzzleFlash != None)
	{
		MuzzleFlash.DetachMuzzleFlash(WeapMesh);
	}

	// Finally, detach weapon mesh
	if ( bWeapMeshIsPawnMesh )
	{
		WeapMesh = None;
	}
	else if ( WeapMesh != None )
	{
		WeapMesh.SetShadowParent(None);
		P.Mesh.DetachComponent( WeapMesh );
	}

	if (LensPSC != none)
	{
		LensPSC.DeactivateSystem();
	}

    Super.DetachFrom(P);
}

simulated function Destroyed()
{
	if (LensPSC != none)
	{
		LensPSC.DeactivateSystem();
	}

	super.Destroyed();
}

defaultproperties
{
	// Weapon SkeletalMesh
	Begin Object Name=SkeletalMeshComponent0
		bForceRefPose=0
	End Object

	CustomAnimTree=AnimTree'WEP_SawBlade_ARCH.3P_Sawblade_Animtree'
	
	bHasLaserSight=TRUE

	LensEffect=ParticleSystem'DROW_EMIT.FX_Heat_Lens'
}