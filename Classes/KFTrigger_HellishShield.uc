class KFTrigger_HellishShield extends KFTrigger_PowerUp;

/*
enum EText_Type
{
	EText1,
};

var() EText_Type TextOnActivation;
var() bool GiveTextToAllPlayers;

var bool bCanTextBeActivated;
*/

// var() AkEvent WalkinSoundEvent;
// var() AkEvent WalkoutSoundEvent;

var() AkEvent ActivatingSoundEvent;

// simulated function PostBeginPlay()
// {
//     super.PostBeginPlay();

//     if (WorldInfo.NetMode != NM_DedicatedServer)
//     {
// 		// LoadMonsterAI();
// 		SpawnFriendlyAI();
// 	}
// }


// function bool UsedBy(Pawn User)
// {
//     if (bCanBeActivated)
//     {
//         //Set reactivation timer to prevent button spam
//         bCanBeActivated = false;
// 		bPowerUpActivated = true;

// 		UpdateStatus();
//         ActivatePowerUp(User);
//         SetTimer(ReactivationTime, false, 'ReactivateTrigger');

//         ActivateText(User);

// 		if(ActivationPowerUpSoundEvent != none)
// 		{
// 			PlaySoundBase(ActivationPowerUpSoundEvent, false, WorldInfo.NetMode == NM_DedicatedServer);
// 		}

//         //Activate objective completion for turning on generator
//         TriggerObjectiveCompletion();
//     }    

//     return true;
// }

/*
function LoadMonsterAI()
{
    local KFPlayercontroller KFPC;
    Local KFPawn_Human KFPH;

	foreach WorldInfo.AllActors( class'KFPawn_Human', KFPH )
    {
    	if ( KFPH != none )
        {
   			foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
			{
				if( KFPC != none)
				{
					SpawnFriendlyAI();
				}
			}
		}
	}
}
*/

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
    super.Touch(Other, OtherComp, HitLocation, HitNormal);
    class'KFPlayerController'.static.UpdateInteractionMessages(Other);

    // Turns humans into ZEDs
	// PickMe();

    // if(WalkinSoundEvent != none && WorldInfo.NetMode != NM_Client)
	// {
	// 	PlaySoundBase(WalkinSoundEvent, false, WorldInfo.NetMode == NM_DedicatedServer);
	// }
}

/*
function PickMe(optional bool bPossess=true )
{
	local KFPlayercontroller KFPC;
    local class<KFPawn_Human> PawnClass;
    Local KFPawn_Human KFPH;

	KFPH = KFPawn_Human( Outer );
	KFPC = KFPlayercontroller( Outer );

    PawnClass = class<KFPawn_Human>( DynamicLoadObject("KFGameContent.KFPawn_ZedFleshpound", class'Class') );

    if( PawnClass != none )
    {
        if( bPossess )
        {
            // KFGameInfo(WorldInfo.Game).SetTeam( KFPlayerController(Outer), KFGameInfo(WorldInfo.Game).Teams[0] );
            KFPC.Possess( KFPH, false );
            // ServerCamera( 'ThirdPerson' );
            // SetWonGameCamera();
            SetNEWGameCamera();
            KFPH.SetPhysics( PHYS_Falling );
        }
    }
}

function SetNEWGameCamera()
{
	local KFPlayerController KFPC;

	foreach WorldInfo.AllControllers( class'KFPlayerController', KFPC )
	{
		KFPC.ServerCamera( 'ThirdPerson' );
	}
}
*/

event UnTouch(Actor Other)
{
    super.UnTouch(Other);
    class'KFPlayerController'.static.UpdateInteractionMessages(Other);

    // if(WalkoutSoundEvent != none && WorldInfo.NetMode != NM_Client)
	// {
	// 	PlaySoundBase(WalkoutSoundEvent, false, WorldInfo.NetMode == NM_DedicatedServer);
	// }
}

function ActivatePowerUp(Pawn user)
{
	local KFPlayerController KFPC;

    //Notify Kismet that the power up has been activated
    NotifyPowerUpActivated();
	
	if(ActivatingSoundEvent != none && WorldInfo.NetMode != NM_Client)
	{
		PlaySoundBase(ActivatingSoundEvent, false, WorldInfo.NetMode == NM_DedicatedServer);
	}

	if(!GivePowerUpToAllPlayers)
	{
		if( user != none )
		{
			KFPC = KFPlayerController(user.Controller);
			if( KFPC != none )
			{
				switch( PowerUpOnActivation )
				{
					// Base powerup to start custom powerup and play message
					case EPowerUp_HellishRage:
					KFPC.ReceiveLocalizedMessage( class'KFLocalMessage_DROW_PowerUp', GMT_PowerUpHellishRagingActivated );
					KFPC.ReceivePowerUp(class'KFPowerUp_HellishRaging');
					break;
				}
			}
		}
	}
	else
	{
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			switch( PowerUpOnActivation )
			{
				// Base powerup to start custom powerup and play message
				case EPowerUp_HellishRage:
				KFPC.ReceiveLocalizedMessage( class'KFLocalMessage_DROW_PowerUp', GMT_PowerUpHellishRagingActivated );
				KFPC.ReceivePowerUp(class'KFPowerUp_HellishRaging');
				break;
			}
		}
	}
}

/*
function ActivateText(Pawn user)
{
	local KFPlayerController KFPC;

    //Notify Kismet that the power up has been activated
    NotifyPowerUpActivated();
	
	if(TextTimer1 > 5)
	{
		if(!GiveTextToAllPlayers)
		{
			if( user != none )
			{
				KFPC = KFPlayerController(user.Controller);
				if( KFPC != none )
				{
					switch( TextOnActivation )
					{
						case EText1:
						KFPC.ReceiveLocalizedMessage( class'KFLocalMessage_DROW_PowerUp', GMT_Text1 );
						break;
					}
	
				}
			}
		}
		else
		{
			foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
			{
				switch( TextOnActivation )
				{
					case EText1:
					KFPC.ReceiveLocalizedMessage( class'KFLocalMessage_DROW_PowerUp', GMT_Text1 );
					break;
				}
			}
		}
	}
}
*/

defaultproperties
{
	bStatic=false
	bNoDelete=false
	bProjTarget=false
	
	// Sounds
	ActivatingSoundEvent=AkEvent'WW_ENV_HellmarkStation.Play_KFTrigger_Activation'
	// WalkinSoundEvent=AkEvent'WW_UI_Menu.Play_AAR_XP_OPEN'
	// WalkoutSoundEvent=AkEvent'WW_UI_Menu.Play_AAR_STATLINE_TEXT'

	Begin Object Name=CollisionCylinder
		CollisionRadius=500 //350
		CollisionHeight=500
	End Object
}