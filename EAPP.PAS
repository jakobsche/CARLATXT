unit EApp;


interface

uses App, Objects, Views;


const
  BackgroundText = 'carlafischer.de '#3' ';
  CCarlaBackground = #3;

type

  TCarlaDrawBuffer = array[0..254] of Word;
  PCarlaDrawBuffer = ^TCarlaDrawBuffer;

  { TCarlaBackground }

  PCarlaBackground = ^TCarlaBackground;
  TCarlaBackground = object(TBackground)
    Wrap: Boolean;
    constructor Init(var R: TRect; AText: string);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure FillRect(var R: TRect);
    function GetPalette: PPalette; virtual;
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
    procedure InitBackground; virtual;
  end;


  { TExtendedApplication }

  TExtendedApplication = object(TApplication)
    procedure InitDesktop; virtual;
  end;


implementation

uses Drivers;

function Min(a, b: Integer): Integer;
begin
  if a <= b then Min := a
  else Min := b
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

procedure TCarlaDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  Background := New(PCarlaBackground, Init(R, BackgroundText));
  PCarlaBackground(Background)^.Wrap := True
end;


{ TExtendedApplication }

procedure TExtendedApplication.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(0, -1);
  Desktop := New(PCarlaDesktop, Init(R))
end;


end.