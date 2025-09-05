class KFWeapAttach_GalvanizedCypressThree extends KFWeaponAttachment;

const SecondaryFireAnim                   = 'Throw';
const SecondaryFireAnimCrouch             = 'Throw_CH';
const SecondaryFireIronAnim               = 'Throw_Iron';

const SecondaryFireBodyAnim               = 'ADD_Throw';
const SecondaryFireBodyAnimCH             = 'ADD_Throw_CH';
const SecondaryFireBodyAnimIron           = 'ADD_Throw_Iron';

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

// Plays fire animation on pawn
simulated function PlayPawnFireAnim( KFPawn P, EAnimSlotStance AnimType )
{
	if (P.FiringMode == 0) // DEFAULT FIRE MODE
	{
		super.PlayPawnFireAnim(P, AnimType);
	}
	else if (P.FiringMode == 1) // ALT FIRE MODE
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

defaultproperties
{

}