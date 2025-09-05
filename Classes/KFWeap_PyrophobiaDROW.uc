class KFWeap_PyrophobiaDROW extends KFWeapon;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// Ironsights Audio
var AkComponent       IronsightsComponent;
var AkEvent           IronsightsZoomInSound;
var AkEvent           IronsightsZoomOutSound;

simulated function ZoomIn(bool bAnimateTransition, float ZoomTimeToGo)
{
    super.ZoomIn(bAnimateTransition, ZoomTimeToGo);

    if (IronsightsZoomInSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomInSound, false);
    }
}

simulated function ZoomOut( bool bAnimateTransition, float ZoomTimeToGo )
{
	super.ZoomOut( bAnimateTransition, ZoomTimeToGo );

    if (IronsightsZoomOutSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomOutSound, false);
    }
}

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
    super.AdjustDamage(InDamage, DamageType, DamageCauser);

    if (Instigator != none && DamageCauser.Instigator == Instigator)
    {
        InDamage *= SelfDamageReductionValue;
    }
}

simulated function PlayFiringSound( byte FireModeNum )
{
    local byte UsedFireModeNum;

	MakeNoise(1.0,'PlayerFiring'); // AI

	if (MedicComp != none && FireModeNum == ALTFIRE_FIREMODE)
	{
		MedicComp.PlayFiringSound();
	}
	else
	if ( !bPlayingLoopingFireSnd )
	{
		UsedFireModeNum = FireModeNum;

		// Use the single fire sound if we're in zed time and want to play single fire sounds
		if( FireModeNum < bLoopingFireSnd.Length && bLoopingFireSnd[FireModeNum] && ShouldForceSingleFireSound() )
        {
            UsedFireModeNum = SingleFireSoundIndex;
        }

        if ( UsedFireModeNum < WeaponFireSound.Length )
		{
			WeaponPlayFireSound(WeaponFireSound[UsedFireModeNum].DefaultCue, WeaponFireSound[UsedFireModeNum].FirstPersonCue);
		}
	}
}

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
	// Inventory
	InventoryGroup=IG_Primary
	GroupPriority=21 // funny number
	InventorySize=7
	WeaponSelectTexture=Texture2D'WEP_PyrophobiaDROW_MAT.UI_WeaponSelect_PyrophobiaDROW_CS'
	AssociatedPerkClasses(0)=class'KFPerk_Firebug'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
	MeshFOV=86
	MeshIronSightFOV=65
	PlayerIronSightFOV=70
	PlayerSprintFOV=95

	// Zooming/Position
	PlayerViewOffset=(X=20.0,Y=5,Z=-5)
	IronSightPosition=(X=0,Y=-0.065,Z=0)
	FastZoomOutTime=0.2

	// Content
	PackageKey="PyrophobiaDROW"
	FirstPersonMeshName="WEP_PyrophobiaDROW_MESH.Wep_1stP_PyrophobiaDROW_CS_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_SeekerSix_ANIM.Wep_1stP_SeekerSix_Anim"
	PickupMeshName="WEP_PyrophobiaDROW_MESH.Wep_PyrophobiaDROW_CS_Pickup"
	AttachmentArchetypeName="WEP_PyrophobiaDROW_ARCH.Wep_PyrophobiaDROW_CS_3P"
	MuzzleFlashTemplateName="WEP_SeekerSix_ARCH.Wep_SeekerSix_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=6
	SpareAmmoCapacity[0]=30
	InitialSpareMags[0]=1
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=700
	minRecoilPitch=675
	maxRecoilYaw=200
	minRecoilYaw=-200
	RecoilRate=0.085
	RecoilBlendOutRatio=0.35
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1500
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485
	RecoilViewRotationScale=0.8
	FallingRecoilModifier=1.5
	HippedRecoilModifier=1.25

	// DEFAULT_FIREMODE (Rocket that explodes into nova explosion on set interval)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Rocket_PyrophobiaDROW'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_PyrophobiaDROW'
	FireInterval(DEFAULT_FIREMODE)=+0.75 //+0.65
	InstantHitDamage(DEFAULT_FIREMODE)=90 //100
    PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.025
	FireOffset=(X=20,Y=4.0,Z=-3)

    SelfDamageReductionValue=0.14f; //0.18

	// ALT_FIREMODE
    FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
    WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Seeker6'
	InstantHitDamage(BASH_FIREMODE)=29

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_1P')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_NorthFleetDROW_SND.supernova_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_NorthFleetDROW_SND.supernova_fire_1P_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_DryFire'

	// Animation
	bHasFireLastAnims=true
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Audio
    Begin Object Class=AkComponent name=IronsightsComponent0
        bForceOcclusionUpdateInterval=true
		OcclusionUpdateInterval=0.f // never update occlusion for footsteps
		bStopWhenOwnerDestroyed=true
    End Object
    IronsightsComponent=IronsightsComponent0
    Components.Add(IronsightsComponent0)
    IronsightsZoomInSound=AkEvent'WW_WEP_Seeker_6.Play_Seeker_6_Iron_In'
    IronsightsZoomOutSound=AkEvent'WW_WEP_Seeker_6.Play_Seeker_6_Iron_In_Out'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.125f), (Stat=EWUS_Weight, Add=1)))
}