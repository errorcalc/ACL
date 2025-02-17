{$R-} { Range-Checking }
{$Q-} { Overflow checking }

{$IF NOT DEFINED(ACL_RTTI_ALL)}
  {$WEAKLINKRTTI ON}
  {$IF DEFINED(ACL_RTTI_OFF)}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ELSE}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([vcPublic, vcPublished])}
  {$IFEND}
{$IFEND}

{$IF DEFINED(CPUX64) || DEFINED(CPU64)}
  {$DEFINE CPUX64}
{$IFEND}

{$WARN DUPLICATE_CTOR_DTOR OFF} // We does not support for C++Builder

// ---------------------------------------------------------------------------------------------------------------------
// Debug and Logging
// ---------------------------------------------------------------------------------------------------------------------

{$IFDEF DEBUG}
  {.$DEFINE ACL_LOG_CMDLINE}
  {.$DEFINE ACL_LOG_REGISTRY}
{$ENDIF}

// ---------------------------------------------------------------------------------------------------------------------
// Graphics
// ---------------------------------------------------------------------------------------------------------------------

{$DEFINE ACL_BLURFILTER_USE_SHARED_RESOURCES}

{$DEFINE ACL_TEXTLAYOUT_RTL_SUPPORT}
{$DEFINE ACL_TEXTLAYOUT_USE_FONTCACHE}

{$IFDEF ACL_TEXTLAYOUT_RTL_SUPPORT}
  {$UNDEF ACL_TEXTLAYOUT_USE_FONTCACHE}
{$ENDIF}

// ---------------------------------------------------------------------------------------------------------------------
// IDE Versions
// ---------------------------------------------------------------------------------------------------------------------

{$IFDEF VER320} // 10.2 Tokyo
  {$DEFINE DELPHI102TOKYO}
{$ENDIF}

{$IFDEF VER330} // 10.3 Rio
  {$DEFINE DELPHI102TOKYO}
  {$DEFINE DELPHI103RIO}
{$ENDIF}

{$IFDEF VER340} // 10.4 Sydney
  {$DEFINE DELPHI102TOKYO}
  {$DEFINE DELPHI103RIO}
  {$DEFINE DELPHI104SYDNEY}
{$ENDIF}

{$IFDEF VER350} // 11.0 Alexandria
  {$DEFINE DELPHI102TOKYO}
  {$DEFINE DELPHI103RIO}
  {$DEFINE DELPHI104SYDNEY}
  {$DEFINE DELPHI110ALEXANDRIA}
{$ENDIF}
