unit EApp;


interface

uses App, Dialogs, Objects, Views;


const
  BackgroundText = 'carlafischer.de '#3' ';
  CCarlaBackground = #3;

type

  TCarlaDrawBuffer = array[0..254] of Word; {l„nger als TDrawBuffer}
  PCarlaDrawBuffer = ^TCarlaDrawBuffer;


  { TClockView }
  PClockView = ^TClockView;
  TClockView = object(TParamText)
    constructor Init(var Bounds: TRect);
    procedure Update;
  end;

  { TCarlaBackground }

  PCarlaBackground = ^TCarlaBackground;
  TCarlaBackground = object(TBackground)
    Wrap: Boolean; {bricht Text um, sonst abgeschnitten}
    constructor Init(var R: TRect; AText: string);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure FillRect(var R: TRect);
    function GetPalette: PPalette; virtual;
    procedure SetText(AText: string);
    procedure WriteText(var X, Y: Integer; EP: TPoint; var Buffer: TCarlaDrawBuffer; Length: Word);
  private
    Text: PString;
    DBS: Word;
    DrawBuffer: PCarlaDrawBuffer;
    procedure FreeDrawBuffer;
    function GetDBLength: Word;
    procedure InitDrawBuffer;
  end;


  { TCarlaDesktop }

  PCarlaDesktop = ^TCarlaDesktop;
  TCarlaDesktop = object(TDesktop)
    constructor Init(var R: TRect);
    procedure InitBackground; virtual;
  end;


  { TExtendedApplication }

  TExtendedApplication = object(TApplication)
    ClockView: PClockView;
    procedure Idle; virtual;
    procedure InitDesktop; virtual;
  end;


implementation

uses Drivers, DOS;

function Min(a, b: Integer): Integer;
begin
  if a <= b then Min := a
  else Min := b
end;


{ TClockView }

type
  PTimeRec = ^TTimeRec;
  TTimeRec = packed record
    Hour, Minute, Second: Longint;
  end;

constructor TClockView.Init(var Bounds: TRect);
begin
  inherited Init(Bounds, '%02d:%02d:%02d', 3);
end;

procedure TClockView.Update;
var
  Hour, Minute, Second, Sec100: Word;
  TimeRec: PTimeRec absolute ParamList;
begin
  GetTime(Hour, Minute, Second, Sec100);
  if (Hour <> TimeRec^.Hour) or (Minute <> TimeRec^.Minute) or (Second <> TimeRec^.Second) then begin
    TimeRec^.Hour := Hour;
    TimeRec^.Minute := Minute;
    TimeRec^.Second := Second;
    if State and sfVisible <> 0 then Draw
  end
end;

{ TCarlaBackground }

constructor TCarlaBackground.Init(var R: TRect; AText: string);
begin
  inherited Init(R, #176);
  if AText = '' then Text := NewStr(Pattern)
  else Text := NewStr(AText);
  FreeDrawBuffer;
end;

destructor TCarlaBackground.Done;
begin
  if Text <> nil then begin
    DisposeStr(Text);
    Text := nil
  end;
  FreeDrawBuffer;
  inherited Done
end;

procedure TCarlaBackground.Draw;
var
  R: TRect;
  DX, X, Y, DXMax: Integer;
begin
  if ScreenMode and smMono = smMono then begin
    inherited Draw;
    Exit
  end;
  InitDrawBuffer;
  GetExtent(R);
  FillRect(R);
end;

procedure TCarlaBackground.FillRect(var R: TRect);
var
  X, Y, i: Integer;
begin
  X := R.A.X; Y := R.A.Y;
  while Y < R.B.Y do
    WriteText(X, Y, R.B, DrawBuffer^, GetDBLength);
end;

function TCarlaBackground.GetPalette: PPalette;
const
  P: TPalette = CCarlaBackground;
begin
  if ScreenMode and smMono = smMono then GetPalette := inherited GetPalette
  else GetPalette := @P
end;


procedure TCarlaBackground.FreeDrawBuffer;
begin
  if DrawBuffer <> nil then
    if DBS > 0 then FreeMem(DrawBuffer, DBS);
  DrawBuffer := nil;
  DBS := 0
end;

function TCarlaBackground.GetDBLength: Word;
begin
  GetDBLength := dbs div 2
end;

procedure TCarlaBackground.InitDrawBuffer;
begin
  if DrawBuffer = nil then begin
    DBS := Length(Text^) * SizeOf(Word);
    GetMem(DrawBuffer, DBS);
    MoveStr(DrawBuffer^, Text^, GetColor(1))
  end;
end;

procedure TCarlaBackground.SetText(AText: string);
begin
  if Text <> nil then DisposeStr(Text);
  Text := NewStr(AText);
  FreeDrawBuffer
end;

procedure TCarlaBackground.WriteText(var X, Y: Integer; EP: TPoint; var Buffer: TCarlaDrawBuffer; Length: Word);
var
  DX, DXAvail, DXWrite: Integer;
  DB: PCarlaDrawBuffer;
begin
  if (X >= EP.X) or (Y >= EP.Y) then Exit;
  DX := Length;
  DXAvail := EP.X - X;
  DXWrite := Min(DX, DXAvail);
  WriteBuf(X, Y, DXWrite, 1, Buffer);
  Inc(X, DXWrite);
  if X >= EP.X then begin
    X := 0; Inc(Y);
    if Wrap then
      if DXWrite < DX then
        if Y < EP.Y then begin
          DB := @DrawBuffer^[DXWrite];
          WriteText(X, Y, EP, DB^, DX - DXWrite)
        end
  end
end;


{ TCarlaDesktop }

constructor TCarlaDesktop.Init(var R: TRect);
begin
  inherited Init(R);
end;

procedure TCarlaDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  Background := New(PCarlaBackground, Init(R, BackgroundText));
  PCarlaBackground(Background)^.Wrap := True
end;


{ TExtendedApplication }

procedure TExtendedApplication.Idle;
const Busy: Boolean = False;
begin
  inherited Idle;
  if ClockView <> nil then begin
    ClockView^.Update;
    {if not Busy then begin
      Busy := True;
      MessageBox('%02d:%02d:%02d', ClockView^.ParamList, mfInformation or mfOKButton);
      Busy := False
    end}
  end
end;

procedure TExtendedApplication.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(0, -1);
  Desktop := New(PCarlaDesktop, Init(R));
  with Desktop^ do begin
    GetExtent(R);
    R.A.X := R.B.X - 8;
    R.A.Y := R.B.Y - 1;
    ClockView := New(PClockView, Init(R));
    ClockView^.GrowMode := gfGrowAll;
    Insert(ClockView)
  end
end;


end.