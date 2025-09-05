class KFWeap_Wildcat extends KFWeap_RifleBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

var float ReloadAnimRateModifier;
var float ReloadAnimRateModifierElite;

const ThirdBurstFireAnim     	 = 'Shoot';
const ThirdBurstFireIronAnim 	 = 'Shoot_Iron';
const ThirdBurstFireAnimLast     = 'Shoot_Last';
const ThirdBurstFireIronAnimLast = 'Shoot_Iron_Last';

// Keeps track of number of shots fired for the alternate fire animations
var transient protected int NumShotsFired;
// Fire interval used for num shots
var const protected float BurstFireInterval;

// Overridden to use a custom fire interval for num shots
simulated function float GetFireInterval( byte FireModeNum )
{
	if( IsBurstFire() )
	{
		return BurstFireInterval;
	}

	return super.GetFireInterval( FireModeNum );
}

simulated protected function bool IsBurstFire()
{
	return NumShotsFired % 3 == 0;
}

simulated state FiringInBurst extends WeaponBurstFiring
{
	// Overriden to not call FireAmmunition right at the start of the state
	simulated event BeginState( Name PreviousStateName )
	{
		Super.BeginState(PreviousStateName);
		NotifyBeginState();
	}

	simulated function EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);
		NotifyEndState();
	}

	// Handle fire interval changes
	simulated function FireAmmunition()
    {
    	super.FireAmmunition();

		// Gotta restart the timer every shot :(
		if( IsTimerActive(nameOf(RefireCheckTimer)) )
		{
			ClearTimer( nameOf(RefireCheckTimer) );
			TimeWeaponFiring( CurrentFireMode );
		}
    }

	simulated function name GetWeaponFireAnim(byte FireModeNum)
	{
		if (AmmoCount[FireModeNum] > 0 && NumShotsFired % 3 == 0)
		{
			return bUsingSights ? ThirdBurstFireIronAnim : ThirdBurstFireAnim;
		}
		return bUsingSights ? ThirdBurstFireIronAnimLast : ThirdBurstFireAnimLast;
	}
}

// Overridden to add to the number of shots fired
simulated function ConsumeAmmo( byte FireModeNum )
{
	++NumShotsFired;

	super.ConsumeAmmo( FireModeNum );
}

// Overridden to reset shot count
simulated function PerformReload(optional byte FireModeNum)
{
	NumShotsFired = 0;

	super.PerformReload( FireModeNum );
}

// Overridden to reset shot count
simulated state WeaponPuttingDown
{
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		NumShotsFired = 0;
	}
}

// Overridden to reset shot count
simulated state WeaponAbortEquip
{
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		NumShotsFired = 0;
	}
}

// Returns an anim rate scale for reloading
simulated function float GetReloadRateScale()
{
	local float Modifier;

	Modifier = UseTacticalReload() ? ReloadAnimRateModifierElite : ReloadAnimRateModifier;

	return super.GetReloadRateScale() * Modifier;
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

defaultproperties
{
	// Inventory / Grouping
	InventorySize=4
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Wildcat_MAT.UI_WeaponSelect_Wildcat'
   	AssociatedPerkClasses(0)=class'KFPerk_Sharpshooter'

    // FOV
    MeshFOV=60 //55
	MeshIronSightFOV=30 // 30
    PlayerIronSightFOV=65

	// Zooming/Position
	PlayerViewOffset=(X=14.0,Y=7,Z=-3.5) //x=8
	IronSightPosition=(X=0,Y=-0.05,Z=-2.9) //-3.1

	// Content
	PackageKey="Wildcat"
	FirstPersonMeshName="WEP_Wildcat_MESH.Wep_1stP_Wildcat_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_Winchester_ANIM.Wep_1stP_Winchester_Anim" // WEP_Wildcat_ARCH.Wep_1stP_Wildcat_Anim
	PickupMeshName="WEP_Wildcat_MESH.Wep_Wildcat_Pickup"
	AttachmentArchetypeName="WEP_Wildcat_ARCH.WEP_Wildcat_RR"
	MuzzleFlashTemplateName="wep_winchester_arch.Wep_Winchester_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=12
	SpareAmmoCapacity[0]=108 //84
	InitialSpareMags[0]=4 //3
	bCanBeReloaded=true
	bReloadFromMagazine=false

	// AI warning system
	bWarnAIWhenAiming=true
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Recoil
	maxRecoilPitch=200 //500
	minRecoilPitch=150 //400
	maxRecoilYaw=50 //150
	minRecoilYaw=-50 //150
	RecoilRate=0.08
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1250
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485
	RecoilViewRotationScale=0.6
	IronSightMeshFOVCompensationScale=1.5

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletBurst'
	FiringStatesArray(DEFAULT_FIREMODE)=FiringInBurst
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Winchester1894'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Wildcat'
	InstantHitDamage(DEFAULT_FIREMODE)=115 //105
	FireInterval(DEFAULT_FIREMODE)=0.1 //0.4 // 70 RPM
	Spread(DEFAULT_FIREMODE)=0.007
	PenetrationPower(DEFAULT_FIREMODE)=1.0
	FireOffset=(X=25,Y=3.0,Z=-2.5)
	BurstAmount=3
	BurstFireInterval=0.3

	ReloadAnimRateModifier=0.7f
	ReloadAnimRateModifierElite=0.6f;
	
	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Winchester'
	InstantHitDamage(BASH_FIREMODE)=27

	// Fire Effects
	//WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_Winchester.Play_WEP_SA_Winchester_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_SA_Winchester.Play_WEP_SA_Winchester_Fire_Single_S')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Wildcat_SND.wildcat_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Wildcat_SND.wildcat_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_Winchester.Play_WEP_SA_Winchester_Handling_DryFire'
	EjectedShellForegroundDuration=1.5f

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'WEP_Wildcat_ARCH.Wildcat_LaserSight_1P'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Uncommon_DROW' // Loot beam fx (no offset)

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	BonesToLockOnEmpty=(RW_Hammer)
	bHasFireLastAnims=true

	FireAnim=Shoot_Iron

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Medium_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Weight, Add=2)))
	WeaponUpgrades[3]=(Stats=((Stat=EWUS_Damage0, Scale=1.45f), (Stat=EWUS_Weight, Add=3)))
}