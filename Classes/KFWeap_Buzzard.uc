class KFWeap_Buzzard extends KFWeap_RifleBase;

/*
const SecondaryFireAnim = 'Shoot_Secondary';
const SecondaryFireIronAnim = 'Shoot_Secondary_Iron';

const SecondaryReloadAnim = 'Reload_Secondary';
const SecondaryReloadAnim_Elite = 'Reload_Secondary_Elite';

// Used on the server to keep track of grenades
var int ServerTotalAltAmmo;

var(Positioning) vector SecondaryFireOffset;

var transient bool bCanceledAltAutoReload;
*/

var protected const array<vector2D> PelletSpread;

// Disable normal bullet spread
simulated function rotator AddSpread(rotator BaseAim)
{
	return BaseAim; // do nothing
}

// Returns number of projectiles to fire from SpawnProjectile
simulated function byte GetNumProjectilesToFire(byte FireModeNum)
{
	return NumPellets[CurrentFireMode];
}

// Same as AddSpread(), but used with MultiShotSpread
static function rotator AddMultiShotSpread( rotator BaseAim, float CurrentSpread, byte PelletNum )
{
	local vector X, Y, Z;
	local float RandY, RandZ;

	if (CurrentSpread == 0) // 0.3214
	{
		return BaseAim;
	}
	else
	{
        // No randomized spread, it's controlled in PelletSpread down bellow
		GetAxes(BaseAim, X, Y, Z);
		RandY = default.PelletSpread[PelletNum].Y; //* RandRange( 0.5f, 1.5f
		RandZ = default.PelletSpread[PelletNum].X;
		return rotator(X + RandY * CurrentSpread * Y + RandZ * CurrentSpread * Z);
	}
}

// Tight choke skill - remove if you want slugs ("combines" 9 bullets into one)
simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local KFPerk InstigatorPerk;

	if (CurrentFireMode == DEFAULT_FIREMODE)
	{
		InstigatorPerk = GetPerk();
		if (InstigatorPerk != none)
		{
			Spread[CurrentFireMode] = default.Spread[CurrentFireMode] * InstigatorPerk.GetTightChokeModifier();
		}
	}

	return super.SpawnAllProjectiles(KFProjClass, RealStartLoc, AimDir);
}

// Return true if this weapon should play the fire last animation for this shoot animation
simulated function bool ShouldPlayFireLast(byte FireModeNum)
{
    if( SpareAmmoCount[GetAmmoType(FireModeNum)] == 0 )
    {
        return true;
    }

    return false;
}

// Returns animation to play based on reload type and status
simulated function name GetReloadAnimName( bool bTacticalReload )
{
	if ( AmmoCount[0] > 0 )
	{
		// Disable half-reloads for now.  This can happen if server gets out
		// of sync, but choosing the wrong animation will just make it worse!
		`warn("Grenade launcher reloading with non-empty mag");
	}

	return bTacticalReload ? ReloadEmptyMagEliteAnim : ReloadEmptyMagAnim;
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

// Alt-fire uses same ammo as Default-fire mode
simulated function StartFire(byte FireModeNum)
{
	if (FireModeNum == DEFAULT_FIREMODE)
	{
		if (AmmoCount[FireModeNum] < AmmoCost[ALTFIRE_FIREMODE] && SpareAmmoCount[FireModeNum] > 0)
		{
			BeginFire(RELOAD_FIREMODE);
			return;
		}
	}

	super.StartFire(FireModeNum);
}

// Secondary firemode

/*
// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	if (bCanceledAltAutoReload)
	{
		bCanceledAltAutoReload = false;
		TryToAltReload();
		return;
	}

	// StartFire - StopFire called from KFPlayerInput
	StartFire(ALTFIRE_FIREMODE);
}

simulated function BeginFire( Byte FireModeNum )
{
	local bool bStoredAutoReload;

	// We are trying to reload the weapon but the primary ammo in already at full capacity
	if ( FireModeNum == RELOAD_FIREMODE && !CanReload() )
	{
		// Store the cuurent state of bCanceledAltAutoReload in case its not possible to do the reload
		bStoredAutoReload = bCanceledAltAutoReload;
		bCanceledAltAutoReload = false;

		if(CanAltAutoReload())
		{
			TryToAltReload();
			return;
		}

		bCanceledAltAutoReload = bStoredAutoReload;
	}

	super.BeginFire( FireModeNum );
}

// Drop this item out in to the world
function DropFrom(vector StartLocation, vector StartVelocity)
{
	local DroppedPickup P;

	// Offset spawn closer to eye location
	StartLocation.Z += Instigator.BaseEyeHeight / 2;

	if( !CanThrow() )
	{
		return;
	}

	if( DroppedPickupClass == None || DroppedPickupMesh == None )
	{
		Destroy();
		return;
	}

	// the last bool param is to prevent collision from preventing spawns
	P = Spawn(DroppedPickupClass,,, StartLocation,,,true);
	if( P == None )
	{
		// if we can't spawn the pickup (likely for collision reasons),
		// just return without removing from inventory or destroying, which removes from inventory
		PlayerController(Instigator.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Game', GMT_FailedDropInventory );
		return;
	}

	if( Instigator != None && Instigator.InvManager != None )
	{
		Instigator.InvManager.RemoveFromInventory(Self);

		if( Instigator.IsAliveAndWell() && !Instigator.InvManager.bPendingDelete )
		{
			`DialogManager.PlayDropWeaponDialog( KFPawn(Instigator) );
		}
	}

	//`Warn("DropFromA SPARE AMMO 0"$SpareAmmoCount[0]$"\n SPARE AMMO 1" $SpareAmmoCount[1]$"\n AmmoCount 0" $AmmoCount[0]$"\n AmmoCount 1" $AmmoCount[1]$"\n ServerTotalAltAmmo" $ServerTotalAltAmmo$"\	n");
	if(Role == ROLE_Authority && !Instigator.IsLocallyControlled())
	{
		SpareAmmoCount[1] = ServerTotalAltAmmo;
		AmmoCount[1] = AmmoCount[1];
	}
	else
	{
		//do nothing because we are offline
	}

	//`Warn("DropFromB SPARE AMMO 0"$SpareAmmoCount[0]$"\n SPARE AMMO 1" $SpareAmmoCount[1]$"\n AmmoCount 0" $AmmoCount[0]$"\n AmmoCount 1" $AmmoCount[1]$"\n ServerTotalAltAmmo" $ServerTotalAltAmmo$"\	n");

	SetupDroppedPickup( P, StartVelocity );

	Instigator = None;
	GotoState('');

	AIController = None;
}

// Initializes ammo counts, when weapon is spawned.
function InitializeAmmo()
{
	local KFPerk CurrentPerk;
	Super.InitializeAmmo();
	// Add Secondary ammo to our secondary spare ammo count both of these are important, in order to allow dropping the weapon to function properly.
	SpareAmmoCount[1]	= Min(SpareAmmoCount[1] + (InitialSpareMags[1] * MagazineCapacity[1]) + AmmoCount[1], GetMaxAmmoAmount(1) - AmmoCount[1]);
	
	//Because SpareAmmoCount was set to zero before the previous line, we call again the variable modification depending on perk abilities
	CurrentPerk = GetPerk();
	CurrentPerk.ModifySpareAmmoAmount(self, SpareAmmoCount[ALTFIRE_FIREMODE], , true);
	SpareAmmoCount[ALTFIRE_FIREMODE] -= AmmoCount[1]; //Accounting for the extra shot calculated.
	ServerTotalAltAmmo += SpareAmmoCount[1];

	// Make sure the server doesn't get extra shots on listen servers.
	if(Role == ROLE_Authority && !Instigator.IsLocallyControlled())
	{
		ServerTotalAltAmmo += AmmoCount[1];
	}
}

simulated function ConsumeAmmo( byte FireModeNum )
{
	local byte AmmoType;
	local bool bNoInfiniteAmmo;
	local int OldAmmoCount;

	if(UsesSecondaryAmmo() && FireModeNum == ALTFIRE_FIREMODE && Role == ROLE_Authority && !Instigator.IsLocallyControlled())
	{
		AmmoType = GetAmmoType(FireModeNum);

		OldAmmoCount = AmmoCount[AmmoType];
		Super.ConsumeAmmo(FireModeNum);

		bNoInfiniteAmmo = (OldAmmoCount - AmmoCount[AmmoType]) > 0 || AmmoCount[AmmoType] == 0;
		if ( bNoInfiniteAmmo )
		{
			ServerTotalAltAmmo--;
		}
	}
	else
	{
		Super.ConsumeAmmo(FireModeNum);
	}
}

// Make sure user can't fire infinitely if they cheat to get infinite ammo locally
simulated event bool HasAmmo( byte FireModeNum, optional int Amount=1 )
{
	local byte AmmoType;

	AmmoType = GetAmmoType(FireModeNum);

	if(AmmoType == 1 && Role == ROLE_Authority && UsesSecondaryAmmo() && !Instigator.IsLocallyControlled())
	{
		if(ServerTotalAltAmmo <= 0)
		{
			return false;
		}
	}

	return Super.HasAmmo(FireModeNum, Amount );
}

// Overridden so any grenades added will go to the spare ammo and not the clip.
function int AddSecondaryAmmo(int Amount)
{
	local int OldAmmo;
	// If we can't accept spare ammo, then abort
	if( !CanRefillSecondaryAmmo() )
	{
		return 0;
	}

	if(Role == ROLE_Authority && !Instigator.IsLocallyControlled())
	{
		OldAmmo = ServerTotalAltAmmo;
		ServerTotalAltAmmo = Min(ServerTotalAltAmmo + Amount, GetMaxAmmoAmount(1));
		ClientGiveSecondaryAmmo(Amount);
		return ServerTotalAltAmmo - OldAmmo;
	}
	else
	{
		OldAmmo = SpareAmmoCount[1];
		ClientGiveSecondaryAmmo(Amount);
		return SpareAmmoCount[1] - OldAmmo;
	}
}

// Give client specified amount of ammo (used player picks up ammo on the server)
reliable client function ClientGiveSecondaryAmmo(byte Amount)
{
	SpareAmmoCount[1] = Min(SpareAmmoCount[1] + Amount, GetMaxAmmoAmount(1) - AmmoCount[1]);
	TryToAltReload();
}

function SetOriginalValuesFromPickup( KFWeapon PickedUpWeapon )
{
	local KFWeap_Buzzard Weap;

	Super.SetOriginalValuesFromPickup(PickedUpWeapon);

	if(Role == ROLE_Authority && !Instigator.IsLocallyControlled())
	{
		Weap = KFWeap_Buzzard(PickedUpWeapon);
		ServerTotalAltAmmo = Weap.ServerTotalAltAmmo;
		SpareAmmoCount[1] = ServerTotalAltAmmo - AmmoCount[1];
		//`Warn("SPARE AMMO 0"$SpareAmmoCount[0]$"\n SPARE AMMO 1" $SpareAmmoCount[1]$"\n AmmoCount 0" $AmmoCount[0]$"\n AmmoCount 1" $AmmoCount[1]$"\n ServerTotalAltAmmo" $ServerTotalAltAmmo$"\	n");
		ClientForceSecondarySpareAmmo(SpareAmmoCount[1]);
	}
	else
	{
		// If we're locally controlled, don't bother using ServerTotalAltAmmo.
		SpareAmmoCount[1] = PickedUpWeapon.SpareAmmoCount[1];
	}
}

reliable client function ClientForceSecondarySpareAmmo(byte NewSecondarySpareAmmo)
{
	if (Role < ROLE_Authority)
	{
		SpareAmmoCount[1] = NewSecondarySpareAmmo;
		NotifyHUDofWeapon(Pawn(Owner));
	}
}

simulated state FiringSecondaryState extends WeaponSingleFiring
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

    // This function returns the world location for spawning the visual effects
    // Overridden to use a special offset for throwing grenades
	simulated event vector GetMuzzleLoc()
	{
		local vector MuzzleLocation;

		// swap fireoffset temporarily
		FireOffset = SecondaryFireOffset;
		MuzzleLocation = Global.GetMuzzleLoc();
		FireOffset = default.FireOffset;

		return MuzzleLocation;
	}

	// Get whether we should play the reload anim as well or not
	simulated function name GetWeaponFireAnim(byte FireModeNum)
	{
		return bUsingSights ? SecondaryFireIronAnim : SecondaryFireAnim;
	}
}

// Don't allow secondary fire to make a primary fire shell particle come out of the gun.
simulated function CauseMuzzleFlash(byte FireModeNum)
{
	local bool AutoShellEject;

	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		if (MuzzleFlash == None)
		{
			AttachMuzzleFlash();
		}

		AutoShellEject = MuzzleFlash.bAutoActivateShellEject;

		MuzzleFlash.bAutoActivateShellEject = false;

		Super.CauseMuzzleFlash(FireModeNum);

		MuzzleFlash.bAutoActivateShellEject = AutoShellEject;
	}
	else
	{
		Super.CauseMuzzleFlash(FireModeNum);
	}
}

// Do not allow alternate fire to tell the weapon to reload. Alt reload occurs in a separate codepath
simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return false;
	}

	return Super.ShouldAutoReload(FireModeNum);
}

// Called on local player when reload starts and replicated to server
simulated function SendToAltReload()
{
	ReloadAmountLeft = MagazineCapacity[1];
	GotoState('AltReloading');
	if ( Role < ROLE_Authority )
	{
		ServerSendToAltReload();
	}
}

// Called from client when reload starts
reliable server function ServerSendToAltReload()
{
	ReloadAmountLeft = MagazineCapacity[1];
	GotoState('AltReloading');
}

// State the weapon is in when it is being reloaded (current magazine replaced with a new one, related animations and effects played).
simulated state AltReloading extends Reloading
{
	ignores ForceReload, ShouldAutoReload, AllowSprinting;

	simulated function byte GetWeaponStateId()
	{
		local KFPerk Perk;
		local bool bTacticalReload;

		Perk = GetPerk();
		bTacticalReload = (Perk != None && Perk.GetUsingTactialReload(self));

		return (bTacticalReload ? WEP_ReloadSecondary_Elite : WEP_ReloadSecondary);
	}

	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		bCanceledAltAutoReload = true;
	}

	// Overridding super so we don't call functions we don't want to call.
	simulated function EndState(Name NextStateName)
	{
		ClearZedTimeResist();
		ClearTimer(nameof(ReloadStatusTimer));
		ClearTimer(nameof(ReloadAmmoTimer));

		CheckBoltLockPostReload();
		NotifyEndState();

		`DialogManager.PlayAmmoDialog( KFPawn(Instigator), float(SpareAmmoCount[1]) / float(GetMaxAmmoAmount(1)) );
	}

	// Overridding super so when this reload is called directly after normal reload state, there are not complications resulting from back to back reloads.
	simulated event ReplicatedEvent(name VarName)
	{
		Global.ReplicatedEvent(Varname);
	}

	// Make sure we can inturrupt secondary reload with anything
	simulated function bool CanOverrideMagReload(byte FireModeNum)
	{
		return true;
	}

	// Returns animation to play based on reload type and status
	simulated function name GetReloadAnimName( bool bTacticalReload )
	{
		// magazine relaod
		if ( AmmoCount[1] > 0 )
		{
			return (bTacticalReload) ? SecondaryReloadAnim_Elite : SecondaryReloadAnim;
		}
		else
		{
			return (bTacticalReload) ? SecondaryReloadAnim_Elite : SecondaryReloadAnim;
		}
	}

	simulated function PerformReload(optional byte FireModeNum)
	{
		Global.PerformReload(ALTFIRE_FIREMODE);

		if(Instigator.IsLocallyControlled() && Role < ROLE_Authority)
		{
			ServerSetAltAmmoCount(AmmoCount[1]);
		}

		bCanceledAltAutoReload = false;
	}

	simulated function EReloadStatus GetNextReloadStatus(optional byte FireModeNum)
	{
		return Global.GetNextReloadStatus(ALTFIRE_FIREMODE);
	}
}

reliable server function ServerSetAltAmmoCount(byte Amount)
{
	AmmoCount[1] = min(Amount, MagazineCapacity[1]);
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

simulated state Active
{
	// Initialize the weapon as being active and ready to go
	simulated event BeginState(Name PreviousStateName)
	{
		// do this last so the above code happens before any state changes
		Super.BeginState(PreviousStateName);

		// If nothing happened, try to reload
		TryToAltReload();
	}
}

// Network: Local Player
simulated function bool CanAltAutoReload()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return false;
	}

	if(!UsesSecondaryAmmo())
	{
		return false;
	}
	
	// If the weapon wants to fire its primary weapon, and it can fire, do not allow weapon to automatically alt reload
	if(PendingFire(DEFAULT_FIREMODE) && HasAmmo(DEFAULT_FIREMODE))
	{
		return false;
	}
	
	if(!CanReload(ALTFIRE_FIREMODE))
	{
		return false;
	}
	
	if (bCanceledAltAutoReload)
	{
		return false;
	}

	return true;
}

simulated function TryToAltReload()
{
	if ((IsInState('Active') || IsInState('WeaponSprinting')) && CanAltAutoReload())
	{
		SendToAltReload();
	}
}
*/

// Returns trader filter index based on weapon type (copied from riflebase)
static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

defaultproperties
{
	// Inventory
	InventorySize=5 //6
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Buzzard_MAT.UI_WeaponSelect_Buzzard'
   	AssociatedPerkClasses(0)=class'KFPerk_Berserker'
   	// AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV / Position
    MeshFOV=70
	MeshIronSightFOV=62
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=1,Y=8,Z=-5)
	IronSightPosition=(X=-13,Y=0,Z=-0.8)

	// AI warning system
	bWarnAIWhenAiming=true
    MaxAIWarningDistSQ=4000000
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=20 //38 can't pick up blades because we shoot 3 blades at cost of 1
	InitialSpareMags[0]=5
	AmmoPickupScale[0]=5.0 // blades
	bCanBeReloaded=true
	bReloadFromMagazine=true // reloading from mag is one step, while NOT reloading from mag is multi-step (open bolt, load ammo, close bolt) and not applicable for bow
	// Just like the launchers, this weapon has mag size of 1 and force reload which causes significant ammo sync issues. This fix is far from perfect, but it helps
	bAllowClientAmmoTracking=true

	// Recoil
	maxRecoilPitch=200
	minRecoilPitch=150
	maxRecoilYaw=100
	minRecoilYaw=-100
	RecoilRate=0.06
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460

	// Content
	PackageKey="Buzzard"
	FirstPersonMeshName="WEP_Buzzard_MESH.Wep_1stP_Buzzard_Rig"
	FirstPersonAnimSetNames(0)="WEP_Buzzard_ARCH.Wep_1stP_Buzzard_Anim"
	PickupMeshName="WEP_Buzzard_MESH.Wep_Buzzard_Pickup"
	AttachmentArchetypeName="WEP_Buzzard_ARCH.WEP_Buzzard_3P"
	MuzzleFlashTemplateName="WEP_HRG_Crossboom_ARCH.Wep_Crossboom_MuzzleFlash"

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Sawblade'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Blade_Buzzard'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Slashing_Buzzard'
	InstantHitDamage(DEFAULT_FIREMODE)=130 //200
	FireInterval(DEFAULT_FIREMODE)=0.3 // For this weapon, this is not the fire rate, but the time when the auto reload anim kicks in
    PenetrationPower(DEFAULT_FIREMODE)=3.0
	AmmoCost(DEFAULT_FIREMODE)=1
	FireOffset=(X=25,Y=3.0,Z=-4.0)

	Spread(DEFAULT_FIREMODE)=0.1f
	NumPellets(DEFAULT_FIREMODE)=3
	PelletSpread(0)=(X=0.0f,Y=0.0f)
	PelletSpread(1)=(X=0.0f,Y=0.45f)
	PelletSpread(2)=(X=0.0f,Y=-0.45f)

	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Sawblade'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Blade_Buzzard_ALT'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Slashing_Buzzard'
	InstantHitDamage(ALTFIRE_FIREMODE)=200
	FireInterval(ALTFIRE_FIREMODE)=0.3 // For this weapon, this is not the fire rate, but the time when the auto reload anim kicks in
	Spread(ALTFIRE_FIREMODE)=0.015 //0.007
    PenetrationPower(ALTFIRE_FIREMODE)=0 //3.0
    // NumPellets(ALTFIRE_FIREMODE)=1
	// AmmoCost(ALTFIRE_FIREMODE)=1

/*
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Sawblade' //rico blade icon or explosive like
	FiringStatesArray(ALTFIRE_FIREMODE)=FiringSecondaryState
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Blade_Buzzard_ALT'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Slashing_Buzzard'
	InstantHitDamage(ALTFIRE_FIREMODE)=200
	FireInterval(ALTFIRE_FIREMODE)=0.4
	Spread(ALTFIRE_FIREMODE)=0.007 //0.007
    PenetrationPower(ALTFIRE_FIREMODE)=0
    NumPellets(ALTFIRE_FIREMODE)=1
	AmmoCost(ALTFIRE_FIREMODE)=1
	SecondaryFireOffset=(X=25,Y=3.0,Z=-4.0)

	MagazineCapacity[1]=1
	SpareAmmoCapacity[1]=5
	InitialSpareMags[1]=1
	AmmoPickupScale[1]=1
	bCanRefillSecondaryAmmo=true;
	bUseGrenadeAsSecondaryAmmo=true
    SecondaryAmmoTexture=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Sawblade'
*/

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_SawBlade.Play_WEP_SA_Sawblade_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_SawBlade.Play_WEP_SA_Sawblade_Fire_1P')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_BladedPistol.Play_WEP_BladedPistol_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_BladedPistol.Play_WEP_BladedPistol_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_SawBlade.Play_WEP_SA_Sawblade_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_SawBlade.Play_WEP_SA_Sawblade_Handling_DryFire'

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HRG_Crossboom'
	InstantHitDamage(BASH_FIREMODE)=26

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.LaserSight_WithAttachment_1P'
	
	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	BonesToLockOnEmpty=(RW_Cable_Parent)

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.1f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.5f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Weight, Add=2)))
}