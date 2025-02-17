﻿{*********************************************}
{*                                           *}
{*     Artem's Visual Components Library     *}
{*        Windows 7 AeroPeek Wrapper         *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2021                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit ACL.UI.AeroPeek;

{$I ACL.Config.inc}

interface

uses
  Types, Windows, SysUtils, Classes, Messages, ActiveX, ShlObj, Graphics, ObjectArray, PropSys, ImgList,
  // ACL
  ACL.Classes,
  ACL.Classes.Collections,
  ACL.Classes.StringList,
  ACL.Classes.Timer,
  ACL.FileFormats.INI,
  ACL.Geometry,
  ACL.Graphics,
  ACL.UI.Controls.BaseControls,
  ACL.UI.ImageList,
  ACL.Utils.Common,
  ACL.Utils.FileSystem;

const
  IID_IObjectArray: TGUID = '{92CA9DCD-5622-4BBA-A805-5E9F541BD8C9}';
  IID_IPropertyStorage: TGUID = '{886d8eeb-8cf2-4446-8d02-cdba1dbdcf99}';

type
  TACLAeroPeek = class;

  { TACLAeroPeekJumpToObjectListItem }

  TACLAeroPeekJumpToObjectListItem = class
  protected
    FArguments: UnicodeString;
    FDisplayName: UnicodeString;
    FFileName: UnicodeString;
    FIconFileName: UnicodeString;
    FIconIndex: Integer;
  public
    function CreateLink: IShellLinkW;
    //
    property Arguments: UnicodeString read FArguments;
    property DisplayName: UnicodeString read FDisplayName;
    property FileName: UnicodeString read FFileName;
    property IconFileName: UnicodeString read FIconFileName;
    property IconIndex: Integer read FIconIndex;
  end;

  { TACLAeroPeekJumpToObjectList }

  TACLAeroPeekJumpToObjectList = class(TACLUnknownObject, IObjectArray)
  strict private
    FList: TACLObjectList;

    function GetItem(Index: Integer): TACLAeroPeekJumpToObjectListItem;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(const AFileName, AArguments, ADisplayName, AIconFileName: UnicodeString; AIconIndex: Integer);
    procedure Clear;
    // IObjectArray
    function GetAt(uiIndex: UINT; const riid: TIID; out ppv): HRESULT; stdcall;
    function GetCount(var pcObjects: UINT): HRESULT; stdcall;
    //
    property Items[Index: Integer]: TACLAeroPeekJumpToObjectListItem read GetItem; default;
  end;

  { TACLAeroPeekJumpToList }

  TACLAeroPeekJumpToList = class
  strict private
    FJumpList: ICustomDestinationList;
    FList: TACLAeroPeekJumpToObjectList;
  protected
    property JumpList: ICustomDestinationList read FJumpList;
    property List: TACLAeroPeekJumpToObjectList read FList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(const AFileName, ADisplayName: UnicodeString); overload;
    procedure Add(const AFileName, AArguments, ADisplayName, AIconFileName: UnicodeString; AIconIndex: Integer); overload;
    procedure Commit;
  end;

  { TACLAeroPeekButton }

  TACLAeroPeekButton = class(TCollectionItem)
  strict private
    FEnabled: Boolean;
    FHint: UnicodeString;
    FImageIndex: Integer;

    procedure SetEnabled(AValue: Boolean);
    procedure SetHint(const AValue: UnicodeString);
    procedure SetImageIndex(AIndex: Integer);
  public
    constructor Create(Collection: TCollection); override;
    //
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Hint: UnicodeString read FHint write SetHint;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
  end;

  { TACLAeroPeekButtons }

  TACLAeroPeekButtons = class(TCollection)
  strict private
    FOwner: TACLAeroPeek;

    function GetItem(Index: Integer): TACLAeroPeekButton;
  protected
    procedure CheckForInitialization;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TACLAeroPeek); virtual;
    function Add(const AHint: UnicodeString; AImageIndex: Integer = -1): TACLAeroPeekButton;
    procedure Clear;
    procedure Delete(Index: Integer);
    //
    property Items[Index: Integer]: TACLAeroPeekButton read GetItem; default;
  end;

  { TACLAeroPeek }

  TACLAeroPeekProgressState = (appsNormal, appsPaused, appsStopped);

  TACLAeroPeekButtonClickEvent = procedure (Sender: TObject; AButtonIndex: Integer) of object;
  TACLAeroPeekDrawPreviewEvent = procedure (Sender: TObject; ABitmap: TACLBitmap) of object;

  TACLAeroPeek = class(TACLUnknownObject)
  strict private
    FButtons: TACLAeroPeekButtons;
    FForceCustomPreview: Boolean;
    FImageList: TACLImageList;
    FInitialized: Boolean;
    FJumpToList: TACLAeroPeekJumpToList;
    FLivePreviewTimer: TACLTimer;
    FOwnerWindow: HWND;
    FProgress: Int64;
    FProgressState: TACLAeroPeekProgressState;
    FProgressTotal: Int64;
    FShowProgress: Boolean;
    FShowProgressCanBeIndeterminate: Boolean;
    FShowStatusAsColor: Boolean;
    FTaskBarList: ITaskbarList3;
    FThumbnailSize: TSize;
    FWindowProcOld: Pointer;
    FWindowProcPtr: Pointer;

    FOnButtonClick: TACLAeroPeekButtonClickEvent;
    FOnDrawPreview: TACLAeroPeekDrawPreviewEvent;
    FOnInitialize: TNotifyEvent;

    function GetAvailable: Boolean;
    function GetProgressPresents: Boolean;
    function SetWindowProc(AWindowProc: Pointer): Pointer;
    procedure ImageListChanged(Sender: TObject);
    procedure LivePreviewTimerHandler(Sender: TObject);
    procedure OwnerWindowWndProc(var AMessage: TMessage);
    procedure SetForceCustomPreview(const Value: Boolean);
    procedure SetOnDrawPreview(AValue: TACLAeroPeekDrawPreviewEvent);
    procedure SetProgressState(AValue: TACLAeroPeekProgressState);
    procedure SetShowProgress(AValue: Boolean);
    procedure SetShowProgressCanBeIndeterminate(AValue: Boolean);
    procedure SetShowStatusAsColor(AValue: Boolean);
  private
    FTaskBarButtons: array [0..6] of TThumbButton;
    FTaskBarButtonsInitialized: Boolean;

    procedure StartLivePreviewTimer;
    procedure StopLivePreviewTimer;
    procedure SyncButtons;
    procedure SyncProgress;
    procedure UpdateForceIconicRepresentation;
    procedure UpdatePeekPreview;
    procedure UpdateThumbnailPreview;
  protected
    function CreatePeekPreview(out AHasFrame: Boolean): TACLBitmap;
    procedure DoButtonClick(AIndex: Integer); virtual;
    procedure DoDrawPreview(ABitmap: TACLBitmap); virtual;
    procedure DoInitialize; virtual;
    procedure SetWindowAttribute(AAttr: Cardinal; AValue: LongBool);
    //
    procedure HookOwnerWindow; virtual;
    procedure UnhookOwnerWindow; virtual;
    //
    property Available: Boolean read GetAvailable;
    property Initialized: Boolean read FInitialized;
    property OwnerWindow: HWND read FOwnerWindow;
    property Progress: Int64 read FProgress;
    property ProgressPresents: Boolean read GetProgressPresents;
    property ProgressTotal: Int64 read FProgressTotal;
    property TaskBarList: ITaskbarList3 read FTaskBarList;
  public
    constructor Create(AOwnerWindow: HWND); virtual;
    destructor Destroy; override;
    procedure ConfigLoad(AConfig: TACLIniFile; const ASection: UnicodeString); virtual;
    procedure ConfigSave(AConfig: TACLIniFile; const ASection: UnicodeString); virtual;
    procedure UpdateOverlay(AIcon: HICON; const AHint: UnicodeString);
    procedure UpdatePreview;
    procedure UpdateProgress(const AProgress, AProgressTotal: Int64);
    //
    property Buttons: TACLAeroPeekButtons read FButtons;
    property ForceCustomPreview: Boolean read FForceCustomPreview write SetForceCustomPreview;
    property ImageList: TACLImageList read FImageList;
    property JumpToList: TACLAeroPeekJumpToList read FJumpToList;
    property ProgressState: TACLAeroPeekProgressState read FProgressState write SetProgressState;
    property ShowProgress: Boolean read FShowProgress write SetShowProgress;
    property ShowProgressCanBeIndeterminate: Boolean read FShowProgressCanBeIndeterminate write SetShowProgressCanBeIndeterminate;
    property ShowStatusAsColor: Boolean read FShowStatusAsColor write SetShowStatusAsColor;
    //
    property OnButtonClick: TACLAeroPeekButtonClickEvent read FOnButtonClick write FOnButtonClick;
    property OnDrawPreview: TACLAeroPeekDrawPreviewEvent read FOnDrawPreview write SetOnDrawPreview;
    property OnInitialize: TNotifyEvent read FOnInitialize write FOnInitialize;
  end;

implementation

uses
  DwmApi, Math, ACL.Utils.Strings, ACL.Utils.Desktop;

const
  CLSID_CustomDestinationList: TGUID = '{77f10cf0-3db5-4966-b520-b7c54fd35ed6}';
  CLSID_TaskbarList: TGUID = '{56fdf344-fd6d-11d0-958a-006097c9a090}';

const
  sThumbButtonsAlreadyCreated = 'You cannot add or remove thumb buttons after aero peek initialization';
  StateMap: array[TACLAeroPeekProgressState] of Integer = (TBPF_NORMAL, TBPF_PAUSED, TBPF_ERROR);

var
  WM_TASKBARBUTTONCREATED: Cardinal = 0;

procedure CreateObj(const CLSID, IID: TCLSID; out AObj);
begin
  if Failed(CoCreateInstance(CLSID, nil, CLSCTX_INPROC_SERVER, IID, AObj)) then
    Pointer(AObj) := nil;
end;

{ TACLAeroPeekButton }

constructor TACLAeroPeekButton.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FEnabled := True;
end;

procedure TACLAeroPeekButton.SetEnabled(AValue: Boolean);
begin
  if AValue <> FEnabled then
  begin
    FEnabled := AValue;
    Changed(True);
  end;
end;

procedure TACLAeroPeekButton.SetHint(const AValue: UnicodeString);
begin
  if AValue <> FHint then
  begin
    FHint := AValue;
    Changed(True);
  end;
end;

procedure TACLAeroPeekButton.SetImageIndex(AIndex: Integer);
begin
  if AIndex <> FImageIndex then
  begin
    FImageIndex := AIndex;
    Changed(True);
  end;
end;

{ TACLAeroPeekButtons }

constructor TACLAeroPeekButtons.Create(AOwner: TACLAeroPeek);
begin
  inherited Create(TACLAeroPeekButton);
  FOwner := AOwner;
end;

procedure TACLAeroPeekButtons.CheckForInitialization;
begin
  if FOwner.FTaskBarButtonsInitialized then
    raise Exception.Create(sThumbButtonsAlreadyCreated);
end;

procedure TACLAeroPeekButtons.Clear;
begin
  CheckForInitialization;
  inherited Clear;
end;

procedure TACLAeroPeekButtons.Delete(Index: Integer);
begin
  CheckForInitialization;
  inherited Delete(Index);
end;

function TACLAeroPeekButtons.Add(const AHint: UnicodeString; AImageIndex: Integer = -1): TACLAeroPeekButton;
begin
  CheckForInitialization;
  BeginUpdate;
  try
    Result := TACLAeroPeekButton(inherited Add);
    Result.ImageIndex := AImageIndex;
    Result.Hint := AHint;
  finally
    EndUpdate;
  end;
end;

procedure TACLAeroPeekButtons.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  FOwner.SyncButtons;
end;

function TACLAeroPeekButtons.GetItem(Index: Integer): TACLAeroPeekButton;
begin
  Result := TACLAeroPeekButton(inherited Items[Index]);
end;

{ TACLAeroPeekJumpToObjectListItem }

function TACLAeroPeekJumpToObjectListItem.CreateLink: IShellLinkW;
var
  AKey: TPropertyKey;
  AStorage: IPropertyStore;
  AVar: TPropVariant;
begin
  CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLinkW, Result);
  if Assigned(Result) then
  begin
    Result.SetPath(PWideChar(FFileName));
    Result.SetArguments(PWideChar(FArguments));
    Result.SetIconLocation(PWideChar(FIconFileName), IconIndex);

    if Succeeded(Result.QueryInterface(IID_IPropertyStorage, AStorage)) then
    try
      AVar.vt := VT_LPWSTR;
      AVar.pwszVal := PWideChar(FDisplayName);
      AKey.fmtid := StringToGUID('{F29F85E0-4FF9-1068-AB91-08002B27B3D9}');
      AKey.pid := 2;
      AStorage.SetValue(AKey, AVar);
      AStorage.Commit;
    finally
      AStorage := nil;
    end;
  end;
end;

{ TACLAeroPeekJumpToObjectList }

constructor TACLAeroPeekJumpToObjectList.Create;
begin
  inherited Create;
  FList := TACLObjectList.Create;
end;

destructor TACLAeroPeekJumpToObjectList.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLAeroPeekJumpToObjectList.Add(
  const AFileName, AArguments, ADisplayName, AIconFileName: UnicodeString; AIconIndex: Integer);
var
  AItem: TACLAeroPeekJumpToObjectListItem;
begin
  AItem := TACLAeroPeekJumpToObjectListItem.Create;
  AItem.FArguments := AArguments;
  AItem.FDisplayName := ADisplayName;
  AItem.FFileName := AFileName;
  AItem.FIconFileName := AIconFileName;
  AItem.FIconIndex := AIconIndex;
  FList.Add(AItem);
end;

procedure TACLAeroPeekJumpToObjectList.Clear;
begin
  FList.Clear;
end;

function TACLAeroPeekJumpToObjectList.GetAt(uiIndex: UINT; const riid: TIID; out ppv): HRESULT; stdcall;
begin
  Result := Items[uiIndex].CreateLink.QueryInterface(riid, ppv);
end;

function TACLAeroPeekJumpToObjectList.GetCount(var pcObjects: UINT): HRESULT;
begin
  pcObjects := FList.Count;
  Result := S_OK;
end;

function TACLAeroPeekJumpToObjectList.GetItem(Index: Integer): TACLAeroPeekJumpToObjectListItem;
begin
  Result := TACLAeroPeekJumpToObjectListItem(FList.Items[Index]);
end;

{ TACLAeroPeekJumpToList }

constructor TACLAeroPeekJumpToList.Create;
begin
  inherited Create;
  FList := TACLAeroPeekJumpToObjectList.Create;
  CreateObj(CLSID_CustomDestinationList, ICustomDestinationList, FJumpList);
end;

destructor TACLAeroPeekJumpToList.Destroy;
begin
  FJumpList := nil;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TACLAeroPeekJumpToList.Add(const AFileName, AArguments, ADisplayName, AIconFileName: UnicodeString; AIconIndex: Integer);
begin
  FList.Add(AFileName, AArguments, ADisplayName, AIconFileName, AIconIndex);
end;

procedure TACLAeroPeekJumpToList.Add(const AFileName, ADisplayName: UnicodeString);
begin
  Add(AFileName, '', ADisplayName, AFileName, 0);
end;

procedure TACLAeroPeekJumpToList.Commit;

  // note: lock AObjArr while TaskList changing, otherthis - AV.
  procedure DoAfterCommit(AOldObjects: IObjectArray);
  begin
    AOldObjects._AddRef;
    AOldObjects._Release;
  end;

var
  AMaxSlot: Cardinal;
  AObjArr: IObjectArray;
begin
  if JumpList <> nil then
  begin
    if Succeeded(JumpList.BeginList(AMaxSlot, IID_IObjectArray, AObjArr)) then
    try
      JumpList.AddUserTasks(List);
    finally
      JumpList.CommitList;
      DoAfterCommit(AObjArr);
    end;
  end;
end;

{ TACLAeroPeek }

constructor TACLAeroPeek.Create(AOwnerWindow: HWND);
begin
  inherited Create;
  FShowProgress := True;
  FShowStatusAsColor := True;
  FShowProgressCanBeIndeterminate := True;
  FProgressState := appsNormal;
  FOwnerWindow := AOwnerWindow;
  FImageList := TACLImageList.Create(nil);
  FImageList.ColorDepth := cd32Bit;
  FImageList.OnChange := ImageListChanged;
  FButtons := TACLAeroPeekButtons.Create(Self);
  FJumpToList := TACLAeroPeekJumpToList.Create;
  CreateObj(CLSID_TaskbarList, IID_ITaskbarList3, FTaskBarList);
  HookOwnerWindow;
end;

destructor TACLAeroPeek.Destroy;
begin
  UnhookOwnerWindow;
  StopLivePreviewTimer;
  FImageList.OnChange := nil;
  FTaskBarList := nil;
  FreeAndNil(FJumpToList);
  FreeAndNil(FImageList);
  FreeAndNil(FButtons);
  inherited Destroy;
end;

procedure TACLAeroPeek.ConfigLoad(AConfig: TACLIniFile; const ASection: UnicodeString);
begin
  ShowProgress := AConfig.ReadBool(ASection, 'ShowPlayingProgress', True);
  ShowStatusAsColor := AConfig.ReadBool(ASection, 'ShowStatusAsColor', True);
end;

procedure TACLAeroPeek.ConfigSave(AConfig: TACLIniFile; const ASection: UnicodeString);
begin
  AConfig.WriteBool(ASection, 'ShowStatusAsColor', ShowStatusAsColor);
  AConfig.WriteBool(ASection, 'ShowPlayingProgress', ShowProgress);
end;

procedure TACLAeroPeek.UpdateOverlay(AIcon: HICON; const AHint: UnicodeString);
begin
  if Available then
    TaskBarList.SetOverlayIcon(OwnerWindow, AIcon, PWideChar(AHint));
end;

procedure TACLAeroPeek.UpdatePreview;
begin
  if Available then
  begin
    if FLivePreviewTimer <> nil then
    begin
      UpdateThumbnailPreview;
      UpdatePeekPreview;
    end
    else
      DwmInvalidateIconicBitmaps(OwnerWindow);
  end;
end;

procedure TACLAeroPeek.UpdateProgress(const AProgress, AProgressTotal: Int64);
begin
  if (AProgress <> FProgress) or (AProgressTotal <> FProgressTotal) then
  begin
    FProgress := AProgress;
    FProgressTotal := AProgressTotal;
    SyncProgress;
  end;
end;

procedure TACLAeroPeek.StartLivePreviewTimer;
begin
  if FLivePreviewTimer = nil then
    FLivePreviewTimer := TACLTimer.CreateEx(LivePreviewTimerHandler, 40, True);
  UpdatePreview;
end;

procedure TACLAeroPeek.StopLivePreviewTimer;
begin
  FreeAndNil(FLivePreviewTimer);
end;

function TACLAeroPeek.CreatePeekPreview(out AHasFrame: Boolean): TACLBitmap;
var
  AIcon: TIcon;
  AWindowInfo: TWindowInfo;
  AWindowPlacement: TWindowPlacement;
begin
  if IsIconic(OwnerWindow) then
  begin
    AHasFrame := False;
    AWindowPlacement.length := SizeOf(AWindowPlacement);
    GetWindowPlacement(OwnerWindow, AWindowPlacement);
    Result := TACLBitmap.CreateEx(AWindowPlacement.rcNormalPosition, pf32bit, True);
    acDrawDragImage(Result.Canvas, Result.ClientRect, 100);

    AIcon := TIcon.Create;
    try
      AIcon.Handle := SendMessage(OwnerWindow, WM_GETICON, ICON_BIG, 0);
      if AIcon.HandleAllocated then
        Result.Canvas.Draw((Result.Width - AIcon.Width) div 2, (Result.Height - AIcon.Height) div 2, AIcon);
    finally
      AIcon.Free;
    end;
  end
  else
  begin
    AWindowInfo.cbSize := SizeOf(AWindowInfo);
    GetWindowInfo(OwnerWindow, AWindowInfo);

    Result := TACLBitmap.CreateEx(AWindowInfo.rcClient, pf32bit, True);
    Result.Canvas.Lock;
    try
      SetWindowOrgEx(Result.Canvas.Handle,
        AWindowInfo.rcClient.Left - AWindowInfo.rcWindow.Left,
        AWindowInfo.rcClient.Top - AWindowInfo.rcWindow.Top, nil);
      SendMessage(OwnerWindow, WM_PRINT, Result.Canvas.Handle,
        PRF_NONCLIENT or PRF_ERASEBKGND or PRF_CLIENT or PRF_CHILDREN);
    finally
      Result.Canvas.Unlock;
    end;

    AHasFrame :=
      (AWindowInfo.rcWindow <> AWindowInfo.rcClient) and
      (GetWindowLong(OwnerWindow, GWL_STYLE) and WS_BORDER <> 0) and
      (GetWindowLong(OwnerWindow, GWL_EXSTYLE) and WS_EX_LAYERED = 0);
  end;
end;

procedure TACLAeroPeek.DoButtonClick(AIndex: Integer);
begin
  if Assigned(OnButtonClick) then
    OnButtonClick(Self, AIndex);
end;

procedure TACLAeroPeek.DoDrawPreview(ABitmap: TACLBitmap);
var
  AHasFrame: Boolean;
  APreview: TACLBitmap;
  ASize: TSize;
begin
  if Assigned(OnDrawPreview) then
    OnDrawPreview(Self, ABitmap)
  else
  begin
    APreview := CreatePeekPreview(AHasFrame);
    try
      ASize := acFitSize(acSize(ABitmap.ClientRect), acSize(APreview.ClientRect), afmProportionalStretch);
      ABitmap.SetSize(ASize.cx, ASize.cy);
      SetStretchBltMode(ABitmap.Canvas.Handle, HALFTONE);
      acStretchBlt(ABitmap.Canvas.Handle, APreview.Canvas.Handle, ABitmap.ClientRect, APreview.ClientRect);
    finally
      APreview.Free;
    end;
  end;
end;

procedure TACLAeroPeek.DoInitialize;
begin
  FInitialized := False;
  FTaskBarButtonsInitialized := False;
  CallNotifyEvent(Self, OnInitialize); //# before FInitialize :=, to prevent to multiple call
  FInitialized := Available;
  if Initialized then
  begin
    SyncProgress;
    SyncButtons;
    UpdatePreview;
  end;
end;

procedure TACLAeroPeek.SetWindowAttribute(AAttr: Cardinal; AValue: LongBool);
begin
  if Available then
    DwmSetWindowAttribute(OwnerWindow, AAttr, @AValue, SizeOf(AValue));
end;

procedure TACLAeroPeek.HookOwnerWindow;
begin
  FWindowProcPtr := MakeObjectInstance(OwnerWindowWndProc);
  FWindowProcOld := SetWindowProc(FWindowProcPtr);
  SetWindowAttribute(DWMWA_HAS_ICONIC_BITMAP, True);
  UpdateForceIconicRepresentation;
end;

procedure TACLAeroPeek.UnhookOwnerWindow;
begin
  if FWindowProcOld <> nil then
  try
    SetWindowAttribute(DWMWA_HAS_ICONIC_BITMAP, False);
    SetWindowProc(FWindowProcOld);
    FreeObjectInstance(FWindowProcPtr);
  finally
    FWindowProcOld := nil;
    FWindowProcPtr := nil;
  end;
end;

function TACLAeroPeek.GetAvailable: Boolean;
begin
  Result := (FTaskBarList <> nil) and IsWinSevenOrLater;
end;

function TACLAeroPeek.GetProgressPresents: Boolean;
begin
  Result := (Progress > 0) or (ProgressTotal > 0);
end;

function TACLAeroPeek.SetWindowProc(AWindowProc: Pointer): Pointer;
begin
  Result := Pointer(SetWindowLong(OwnerWindow, GWL_WNDPROC, NativeUInt(AWindowProc)));
end;

procedure TACLAeroPeek.ImageListChanged(Sender: TObject);
begin
  SyncButtons;
end;

procedure TACLAeroPeek.OwnerWindowWndProc(var AMessage: TMessage);
begin
  case AMessage.Msg of
    WM_COMMAND:
      if HiWord(AMessage.WParam) = THBN_CLICKED then
      begin
        DoButtonClick(Loword(AMessage.WParam));
        Exit;
      end;

    WM_DWMSENDICONICLIVEPREVIEWBITMAP:
      begin
        StartLivePreviewTimer;
        Exit;
      end;

    WM_DWMSENDICONICTHUMBNAIL:
      begin
        FThumbnailSize := acSize(HiWord(AMessage.LParam), LoWord(AMessage.LParam));
        StartLivePreviewTimer;
        Exit;
      end;
  end;

  AMessage.Result := CallWindowProc(FWindowProcOld, OwnerWindow, AMessage.Msg, AMessage.WParam, AMessage.LParam);
  if AMessage.Msg = WM_TASKBARBUTTONCREATED then
    DoInitialize;
  if AMessage.Msg = WM_NCDESTROY then
    UnhookOwnerWindow;
end;

procedure TACLAeroPeek.LivePreviewTimerHandler(Sender: TObject);
var
  AClassName: string;
begin
  AClassName := acGetClassName(WindowFromPoint(MouseCursorPos));
  if acSameTextEx(AClassName, ['TaskListThumbnailWnd', 'MSTaskListWClass', 'ToolbarWindow32']) then
  begin
    UpdateThumbnailPreview;
    UpdatePeekPreview;
  end
  else
    StopLivePreviewTimer;
end;

procedure TACLAeroPeek.SetForceCustomPreview(const Value: Boolean);
begin
  if FForceCustomPreview <> Value then
  begin
    FForceCustomPreview := Value;
    UpdateForceIconicRepresentation;
  end;
end;

procedure TACLAeroPeek.SetOnDrawPreview(AValue: TACLAeroPeekDrawPreviewEvent);
begin
  FOnDrawPreview := AValue;
  UpdateForceIconicRepresentation;
end;

procedure TACLAeroPeek.SetProgressState(AValue: TACLAeroPeekProgressState);
begin
  if AValue <> FProgressState then
  begin
    FProgressState := AValue;
    SyncProgress;
  end;
end;

procedure TACLAeroPeek.SetShowProgress(AValue: Boolean);
begin
  if AValue <> FShowProgress then
  begin
    FShowProgress := AValue;
    SyncProgress;
  end;
end;

procedure TACLAeroPeek.SetShowProgressCanBeIndeterminate(AValue: Boolean);
begin
  if FShowProgressCanBeIndeterminate <> AValue then
  begin
    FShowProgressCanBeIndeterminate := AValue;
    SyncProgress;
  end;
end;

procedure TACLAeroPeek.SetShowStatusAsColor(AValue: Boolean);
begin
  if AValue <> FShowStatusAsColor then
  begin
    FShowStatusAsColor := AValue;
    SyncProgress;
  end;
end;

procedure TACLAeroPeek.SyncButtons;

  procedure PrepareButton(var B: TThumbButton; AItem: TACLAeroPeekButton; AIndex: Integer);
  begin
    ZeroMemory(@B, SizeOf(B));
    B.dwMask := THB_BITMAP or THB_FLAGS or THB_TOOLTIP;
    acStrLCopy(@B.szTip[0], AItem.Hint, Length(B.szTip));
    B.dwFlags := IfThen(AItem.Enabled, THBF_ENABLED, THBF_DISABLED);
    B.iBitmap := AItem.ImageIndex;
    B.iId := AIndex;
  end;

  procedure UpdateThumbBar(AButtons: PThumbButton; AButtonsCount: Integer);
  begin
    TaskBarList.ThumbBarSetImageList(OwnerWindow, ImageList.Handle);
    if FTaskBarButtonsInitialized then
      TaskBarList.ThumbBarUpdateButtons(OwnerWindow, AButtonsCount, AButtons)
    else
    begin
      TaskBarList.ThumbBarAddButtons(OwnerWindow, AButtonsCount, AButtons);
      FTaskBarButtonsInitialized := True;
    end;
  end;

var
  AButtonsCount: Integer;
  I: Integer;
begin
  if FTaskBarButtonsInitialized or (Buttons.Count <> 0) then
  begin
    AButtonsCount := Min(Buttons.Count, Length(FTaskBarButtons));
    for I := 0 to AButtonsCount - 1 do
      PrepareButton(FTaskBarButtons[I], Buttons[I], I);
    if Initialized then
      UpdateThumbBar(@FTaskBarButtons[0], AButtonsCount);
  end;
end;

procedure TACLAeroPeek.SyncProgress;

  function CalculateState: Cardinal;
  begin
    if (ProgressTotal = 0) and ShowProgressCanBeIndeterminate then
      Result := TBPF_INDETERMINATE
    else
      if ShowStatusAsColor then
        Result := StateMap[ProgressState]
      else
        if ProgressTotal = 0 then
          Result := TBPF_NOPROGRESS
        else
          Result := TBPF_NORMAL;
  end;

var
  AState: Cardinal;
begin
  if Initialized then
  begin
    if ShowProgress and ProgressPresents then
    begin
      AState := CalculateState;
      TaskBarList.SetProgressState(OwnerWindow, AState);
      if (AState <> TBPF_NOPROGRESS) and (AState <> TBPF_INDETERMINATE) then
        TaskBarList.SetProgressValue(OwnerWindow, Progress, ProgressTotal);
    end
    else
      if ShowStatusAsColor and ProgressPresents then
      begin
        TaskBarList.SetProgressState(OwnerWindow, StateMap[ProgressState]);
        TaskBarList.SetProgressValue(OwnerWindow, 100, 100);
      end
      else
        TaskBarList.SetProgressState(OwnerWindow, TBPF_NOPROGRESS);
  end;
end;

procedure TACLAeroPeek.UpdateForceIconicRepresentation;
begin
  SetWindowAttribute(DWMWA_FORCE_ICONIC_REPRESENTATION, Assigned(OnDrawPreview) or ForceCustomPreview);
end;

procedure TACLAeroPeek.UpdatePeekPreview;
var
  ABitmap: TACLBitmap;
  AHasBorder: Boolean;
begin
  ABitmap := CreatePeekPreview(AHasBorder);
  try
    DwmSetIconicLivePreviewBitmap(OwnerWindow, ABitmap.Handle, nil, IfThen(AHasBorder, DWM_SIT_DISPLAYFRAME));
  finally
    ABitmap.Free;
  end;
end;

procedure TACLAeroPeek.UpdateThumbnailPreview;
var
  ABitmap: TACLBitmap;
begin
  ABitmap := TACLBitmap.CreateEx(FThumbnailSize, pf32bit);
  try
    DoDrawPreview(ABitmap);
    DwmSetIconicThumbnail(OwnerWindow, ABitmap.Handle, 0);
  finally
    ABitmap.Free;
  end;
end;

initialization
  WM_TASKBARBUTTONCREATED := RegisterWindowMessage('TaskbarButtonCreated');
end.
