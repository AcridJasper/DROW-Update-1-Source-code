class KFWeap_GoldenAK47 extends KFWeap_RifleBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

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

simulated state WeaponSingleFiring
{
	simulated event EndState( Name NextStateName )
	{
		Super.EndState(NextStateName);

		if (WorldInfo.NetMode == NM_Client && bAllowClientAmmoTracking && FireInterval[CurrentFireMode] <= MinFireIntervalToTriggerSync)
		{
			SyncCurrentAmmoCount(CurrentFireMode, AmmoCount[GetAmmoType(CurrentFireMode)]);
		}
	}
}

defaultproperties
{
	// Inventory / Grouping
	InventorySize=6 //7
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_GoldenAK47_MAT.UI_WeaponSelect_GoldenAK47_1'
	AssociatedPerkClasses(0)=class'KFPerk_Commando'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=73 //80
	MeshIronSightFOV=37 //27
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=15,Y=12.5,Z=-1) //Z=-4
	IronSightPosition=(X=0,Y=-0.13,Z=3.2)

	// Content
	PackageKey="GoldenAK47"
	FirstPersonMeshName="WEP_GoldenAK47_MESH.WEP_1stP_GoldenAK47_Rig"
	FirstPersonAnimSetNames(0)="WEP_GoldenAK47_ARCH.Wep_1stP_GoldenAK47_Anim"
	PickupMeshName="WEP_GoldenAK47_MESH.Wep_GoldenAK47_Pickup"
	AttachmentArchetypeName="WEP_GoldenAK47_ARCH.Wep_GoldenAK47_3P" // WEP_GoldenAK47_ARCH.Wep_GoldenAK47_Trail_3P
	MuzzleFlashTemplateName="WEP_GoldenAK47_ARCH.Wep_GoldenAK47_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=30
	SpareAmmoCapacity[0]=360
	InitialSpareMags[0]=3
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=115
	minRecoilPitch=100
	maxRecoilYaw=95
	minRecoilYaw=-95
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
	HippedRecoilModifier=1.5 //1.25

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_AssaultRifle'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_GoldenAK47'
	InstantHitDamage(DEFAULT_FIREMODE)=55
	FireInterval(DEFAULT_FIREMODE)=+0.1 // 600 RPM
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	Spread(DEFAULT_FIREMODE)=0.006
	FireOffset=(X=30,Y=3.0,Z=-2.5)

	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_AssaultRifle'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_GoldenAK47'
	InstantHitDamage(ALTFIRE_FIREMODE)=55
	FireInterval(ALTFIRE_FIREMODE)=0.15 // 400 RPM
	PenetrationPower(ALTFIRE_FIREMODE)=2.0
	Spread(ALTFIRE_FIREMODE)=0.006

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_M14EBR'
	InstantHitDamage(BASH_FIREMODE)=27

	// Fire Effects
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_GoldenAK47_SND.ak47_shoot_3p_Cue', FirstPersonCue=SoundCue'WEP_GoldenAK47_SND.ak47_shoot_1p_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_GoldenAK47_SND.ak47_shoot_3p_Cue', FirstPersonCue=SoundCue'WEP_GoldenAK47_SND.ak47_shoot_1p_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_AK12.Play_WEP_SA_AK12_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_AK12.Play_WEP_SA_AK12_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

	FireAnim=Shoot//_OG

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Damage1, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Damage1, Scale=1.3f), (Stat=EWUS_Weight, Add=2)))
}