class KFLocalMessage_DROW_PowerUp extends KFLocalMessage;

enum EGameMessageType
{
	GMT_PowerUpIceMonsterActivated,
	GMT_PowerUpHellishRagingActivated
};

var localized string PowerUpIceMonsterActivatedMessage;
var localized string PowerUpHellishRagingActivatedMessage;

// Returns a hex color code for the supplied message type
static function string GetHexColor(int Switch)
{
    switch ( Switch )
	{
		case GMT_PowerUpIceMonsterActivated:
		case GMT_PowerUpHellishRagingActivated:
             return default.GameColor;
	}

	return "00FF00";
}

static function string GetString(
	optional int Switch,
	optional bool bPRI1HUD,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	switch ( Switch )
	{
		case GMT_PowerUpIceMonsterActivated:
            return default.PowerUpIceMonsterActivatedMessage;
        case GMT_PowerUpHellishRagingActivated:
            return default.PowerUpHellishRagingActivatedMessage;
		default:
			return "";
	}
}

DefaultProperties
{
	Lifetime=15

	bIsConsoleMessage=true
 	bIsUnique=false
 	bIsSpecial=false
 	bBeep=false
}