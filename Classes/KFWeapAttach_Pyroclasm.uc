class KFWeapAttach_Pyroclasm extends KFWeaponAttachment;

// Effect that happens while charging up the beam
var transient ParticleSystemComponent OutPSC;
var const ParticleSystem LensEffect;

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

	// setup and play the beam charge particle system
	if (OutPSC == none)
	{
		OutPSC = new(self) class'ParticleSystemComponent';

		if (WeapMesh != none)
		{
			WeapMesh.AttachComponentToSocket(OutPSC, 'FireFX');
		}
		else
		{
			AttachComponent(OutPSC);
		}
	}
	else
	{
		OutPSC.ActivateSystem();
	}

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(LensEffect);
		OutPSC.SetAbsolute(false, false, false);
		OutPSC.SetTemplate(LensEffect);
	}
}

// Dettach fx
simulated function DetachFrom(KFPawn P)
{
	if (OutPSC != none)
	{
		OutPSC.DeactivateSystem();
	}

    Super.DetachFrom(P);
}

defaultproperties
{
	LensEffect=ParticleSystem'DROW_EMIT.FX_Pyroclasm_FireFX'
}