class KFWeap_Zap extends KFWeap_ScopedBase;

// var float LastFireInterval;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// How much momentum to apply when "rocket jumping"
// var(Recoil) float RocketJumpKickMomentum;

var class<KFGFxWorld_MedicOptics> OpticsUIClass;
var KFGFxWorld_MedicOptics OpticsUI;

// The last updated value for our ammo - Used to know when to update our optics ammo
var byte StoredPrimaryAmmo;
var byte StoredSecondaryAmmo;

simulated event Tick( FLOAT DeltaTime )
{
	if (Instigator != none && Instigator.weapon == self)
	{
		UpdateOpticsUI();
	}

	Super.Tick(DeltaTime);
}

// Get our optics movie from the inventory once our InvManager is created
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local KFInventoryManager KFIM;

	super.ClientWeaponSet(bOptionalSet, bDoNotActivate);

	if (OpticsUI == none && OpticsUIClass != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			//Create the screen's UI piece
			OpticsUI = KFGFxWorld_MedicOptics(KFIM.GetOpticsUIMovie(OpticsUIClass));
		}
	}
}

// Update our displayed ammo count if it's changed
simulated function UpdateOpticsUI(optional bool bForceUpdate)
{
	if (OpticsUI != none && OpticsUI.OpticsContainer != none)
	{
		if (AmmoCount[DEFAULT_FIREMODE] != StoredPrimaryAmmo || bForceUpdate)
		{
			StoredPrimaryAmmo = AmmoCount[DEFAULT_FIREMODE];
			OpticsUI.SetPrimaryAmmo(StoredPrimaryAmmo);
		}

		if (AmmoCount[ALTFIRE_FIREMODE] != StoredSecondaryAmmo || bForceUpdate)
		{
			StoredSecondaryAmmo = AmmoCount[ALTFIRE_FIREMODE];
			OpticsUI.SetHealerCharge(StoredSecondaryAmmo);
		}

		if(OpticsUI.MinPercentPerShot != AmmoCost[ALTFIRE_FIREMODE])
		{
			OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE] );
		}
	}
}

function ItemRemovedFromInvManager()
{
	local KFInventoryManager KFIM;
	local KFWeap_MedicBase KFW;

	Super.ItemRemovedFromInvManager();

	if (OpticsUI != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			// @todo future implementation will have optics in base weapon class
			foreach KFIM.InventoryActors(class'KFWeap_MedicBase', KFW)
			{
				if( KFW.OpticsUI.Class == OpticsUI.class)
				{
					// A different weapon is still using this optics class
					return;
				}
			}

			//Create the screen's UI piece
			KFIM.RemoveOpticsUIMovie(OpticsUI.class);

			OpticsUI.Close();
			OpticsUI = none;
		}
	}
}

// Unpause our optics movie and reinitialize our ammo when we equip the weapon
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	super.AttachWeaponTo(MeshCpnt, SocketName);

	if (OpticsUI != none)
	{
		OpticsUI.SetPause(false);
		OpticsUI.ClearLockOn();
		UpdateOpticsUI(true);
		OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE]);
	}
}

// Pause the optics movie once we unequip the weapon so it's not playing in the background
simulated function DetachWeapon()
{
	local Pawn OwnerPawn;
	super.DetachWeapon();

	OwnerPawn = Pawn(Owner);
	if( OwnerPawn != none && OwnerPawn.Weapon == self )
	{
		if (OpticsUI != none)
		{
			OpticsUI.SetPause();
		}
	}
}

// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

simulated function StartFire(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE && bUseAltFireMode)
	{
		if (AmmoCount[FireModeNum] < AmmoCost[ALTFIRE_FIREMODE] && SpareAmmoCount[FireModeNum] > 0)
		{
			BeginFire(RELOAD_FIREMODE);
			return;
		}
	}

	super.StartFire(FireModeNum);
}

// Allow reloads for primary weapon to be interupted by firing secondary weapon
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return true;
	}

	return Super.CanOverrideMagReload(FireModeNum);
}

/*
simulated state RocketJump extends WeaponSingleFiring
{
	simulated function BeginState(name PreviousStateName)
    {
		//local KFMapInfo KFMI; 
       	Super.BeginState(PreviousStateName);


		// KFMI = KFMapInfo(WorldInfo.GetMapInfo());
		// if(KFMI != none && !KFMI.bAllowShootgunJump)
		// {
		// 	return;
		// }

		// Push the player back when they rocket jump
		ApplyRocketJumpKickMomentum(RocketJumpKickMomentum); //, FallingRocketJumpMomentumReduction);
	}

	// simulated event Tick(float DeltaTime)
	// {
	// 	Super.Tick(DeltaTime);

	// 	// Push the player back when they rocket jump
	// 	ApplyRocketJumpKickMomentum(RocketJumpKickMomentum); //, FallingRocketJumpMomentumReduction);
	// }
}
*/

/*
simulated function ApplyRocketJumpKickMomentum(float Momentum)
{
	local vector UsedKickMomentum;

	if (Instigator != none )
	{
		UsedKickMomentum.X = -Momentum;

		if( Instigator.Physics == PHYS_Falling )
		{
			UsedKickMomentum = UsedKickMomentum >> Instigator.GetViewRotation();

			RocketJumpKickMomentum=1200;
		}
		else
		{
			UsedKickMomentum = UsedKickMomentum >> Instigator.Rotation;
			UsedKickMomentum.Z = 0;
		}

		Instigator.AddVelocity(UsedKickMomentum,Instigator.Location,none);
	}
}
*/

// simulated function float GetFireInterval(byte FireModeNum)
// {
// 	if (FireModeNum == ALTFIRE_FIREMODE && AmmoCount[FireModeNum] == 0)
// 	{
// 		return LastFireInterval;
// 	}

// 	return super.GetFireInterval(FireModeNum);
// }

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;

		//ApplyRocketJumpKickMomentum(RocketJumpKickMomentum);
	}
}

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Projectile;
}

defaultproperties
{
    // Inventory / Grouping
    InventorySize=6 //7
    GroupPriority=21 // funny number
    WeaponSelectTexture=Texture2D'WEP_Zap_MAT.UI_WeaponSelect_Zap'
    AssociatedPerkClasses(0)=class'KFPerk_Survivalist'

    // FOV
    MeshFOV=60
    MeshIronSightFOV=27
    PlayerIronSightFOV=70

    // Zooming/Position
    //PlayerViewOffset=(X=15.0,Y=11.5,Z=-4)
    PlayerViewOffset=(X=20.0,Y=11.0,Z=-2)
    IronSightPosition=(X=-7.0,Y=0.07,Z=0.05) //(X=30.0,Y=0,Z=0)

	// Content
	PackageKey="Zap"
	FirstPersonMeshName="WEP_Zap_MESH.WEP_1stP_Zap_Rig"
	FirstPersonAnimSetNames(0)="wep_1p_hrg_cranialpopper_anim.Wep_1stP_HRG_CranialPopper_Anim"
	PickupMeshName="WEP_Zap_MESH.Wep_Zap_Pickup"
    AttachmentArchetypeName="WEP_Zap_ARCH.Wep_Zap_3P"
	MuzzleFlashTemplateName="WEP_Zap_ARCH.Wep_Zap_MuzzleFlash"

    // Ammo
    MagazineCapacity[0]=8
    SpareAmmoCapacity[0]=64 //96 //98
    InitialSpareMags[0]=5
	AmmoPickupScale[0]=2.0
    bCanBeReloaded=true
    bReloadFromMagazine=true
	bCanRefillSecondaryAmmo=false

    // AI warning system
    bWarnAIWhenAiming=true
    AimWarningDelay=(X=0.4f, Y=0.8f)
    AimWarningCooldown=0.0f

    // Recoil
    maxRecoilPitch=225
    minRecoilPitch=200
    maxRecoilYaw=200
    minRecoilYaw=-200
    RecoilRate=0.08
    RecoilMaxYawLimit=500
    RecoilMinYawLimit=65035
    RecoilMaxPitchLimit=900
    RecoilMinPitchLimit=65035
    RecoilISMaxYawLimit=150
    RecoilISMinYawLimit=65385
    RecoilISMaxPitchLimit=375
    RecoilISMinPitchLimit=65460
    RecoilViewRotationScale=0.6

	// Scope Render
  	// 2D scene capture
	Begin Object Name=SceneCapture2DComponent0
	   //TextureTarget=TextureRenderTarget2D'WEP_1P_HRG_CranialPopper_MAT.WEP_1P_Cranial_zoomed_Scope_MAT'
	   FieldOfView=12.5 //23.0 // "1.5X" = 35.0(our real world FOV determinant)/1.5
	End Object

    ScopedSensitivityMod=8.0 //16.0
	ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_1P_HRG_CranialPopper_MAT.WEP_1P_Cranial_zoomed_Scope_MAT'
	ScopeMICIndex=2

    OpticsUIClass=class'KFGFxWorld_MedicOptics'

	// DEFAULT_FIREMODE (Fires a tazer that sticks to surfaces or ZEDs, then blows up on fuze)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Grenade'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring //WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Rocket_Zap'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Zap'
	InstantHitDamage(DEFAULT_FIREMODE)=80 //60
	FireInterval(DEFAULT_FIREMODE)=0.3 // 200 RPM ?
	Spread(DEFAULT_FIREMODE)=0.025
	PenetrationPower(DEFAULT_FIREMODE)=0
    FireOffset=(X=30,Y=3.0,Z=-2.5) //x=15

	// ALTFIRE_FIREMODE (Fires explosive projectile that leaves electric ground fire)
	FireModeIconPaths(ALTFIRE_FIREMODE)="ui_firemodes_tex.UI_FireModeSelect_Grenade"
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponBurstFiring //WeaponSingleFiring //RocketJump
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Rocket_ZapField'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Zap'
	InstantHitDamage(ALTFIRE_FIREMODE)=70 //50
	FireInterval(ALTFIRE_FIREMODE)=0.2 // 300 RPM
	Spread(ALTFIRE_FIREMODE)=0.025
	PenetrationPower(ALTFIRE_FIREMODE)=0
	AmmoCost(ALTFIRE_FIREMODE)=2
	// RocketJumpKickMomentum=2000
	BurstAmount=4
	// LastFireInterval=0.4

	SelfDamageReductionValue=0.18f; //0.16

    // BASH_FIREMODE
    InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HRG_CranialPopper'
    InstantHitDamage(BASH_FIREMODE)=26

    // Fire Effects
    //WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_CranialPopper.Play_WEP_HRG_CranialPopper_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_CranialPopper.Play_WEP_HRG_CranialPopper_Fire_1P') 
    //WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_CranialPopper.Play_WEP_HRG_CranialPopper_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_CranialPopper.Play_WEP_HRG_CranialPopper_Fire_1P') 
    WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SealSqueal.Play_WEP_SealSqueal_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_SealSqueal.Play_WEP_SealSqueal_Shoot_1P') //@TODO: Replace me
    WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_CranialPopper.Play_WEP_HRG_CranialPopper_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_CranialPopper.Play_WEP_HRG_CranialPopper_Fire_1P') 
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Handling_DryFire'
    WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Handling_DryFire'

    // Custom animations
    FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

    // Attachments
    bHasIronSights=true
    bHasFlashlight=false
    bHasLaserSight=true
    LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.Default_LaserSight_1P'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'

    // From original KFWeap_RifleBase base class
	AimCorrectionSize=40.f

    NumBloodMapMaterials=3

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Damage1, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Damage1, Scale=1.4f), (Stat=EWUS_Weight, Add=2)))
}