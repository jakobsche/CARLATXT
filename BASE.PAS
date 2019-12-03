{ Das Anwendungsobjekt }

unit Base;


interface


uses
  App, Dialogs, Drivers, Editors, Menus, Objects, Views;


const

  cmSelectBluePalette = 100;
  cmSelectCyanPalette = 101;
  cmSelectGrayPalette = 102;

  cmDummy             = 1000;
  cmSelectWindow      = 1001;
  cmMono              = 1002;
  cmBW                = 1003;
  cmColor             = 1004;
  cmResolution        = 1005;
  cmInfo              = 1006;
  cmShowClipboard     = 1007;


  CarlaEditorCommands = [cmSelectBluePalette, cmSelectCyanPalette, cmSelectGrayPalette];


type


  { TAboutBox }

  PAboutBox = ^TAboutBox;
  TAboutBox = object(TDialog)
    constructor Init;
  end;

  { TCarlaEditor }

  PCarlaEditor = ^TCarlaEditor;
  TCarlaEditor = object(TEditWindow)
    destructor Done; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;


  { TEditWindowList }

  PEditWindowList = ^TEditWindowList;
  TEditWindowList = object(TCollection)
    procedure Error(Code, Info: Integer); virtual;
    procedure FreeItem(Item: Pointer); virtual;
  end;


  { TWindowListBox }

  PWindowListBox = ^TWindowListBox;
  TWindowListBox = object(TListBox)
    function GetText(Item: Integer; MaxLen: Integer): string; virtual;
  end;


  { TWindowListDialog }

  PWindowListDialog = ^TWindowListDialog;
  TWindowListDialog = object(TDialog)
    WindowListBox: PWindowListBox;
    constructor Init;
    destructor Done; virtual;
  end;

  { TTextApp }

  TTextApp = object(TApplication)
    constructor Init;
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    function NewEditWindow(AFileName: FNameStr): PCarlaEditor;
    procedure OutOfMemory; virtual;
    procedure ShowMessage(Msg: string);
  private
    ClipboardWindow: PEditWindow;
    EditWindowList: PEditWindowList;
    HighResolution: Boolean;
  end;


var
  TextApp: TTextApp;


implementation

uses MsgBox, Memory;


type
  TWindowListViewData = packed record
    List: PEditWindowList;
    Focused: Integer;
  end;



{ TAboutBox }

constructor TAboutBox.Init;
var
  R: TRect;
  Button: PButton;
begin
  R.Assign(0, 0, 40, 20);
  inherited Init(R, 'Info');
  Options := Options or ofCentered;
  R.Assign(1, 1, 39, 2);
  Insert(New(PStaticText, Init(R, 'ASCII file editor')));
  R.Assign(1, 3, 39, 4);
  Insert(New(PStaticText, Init(R, 'Copyright 2019 Andreas Jakobsche')));
  R.Assign(1, 5, 39, 7);
  Insert(New(PStaticText, Init(R, 'dedicated to Carla Fischer, carlafischer.de')));
  R.Assign(1, 8, 39, 12);
  Insert(New(PStaticText, Init(R, 'This application uses DPMI, if it is available, else it will perhaps have problems to ' +
    'allocate enough memory for your operations.')));
  R.Assign(1, 13, 39, 17);
  Insert(New(PStaticText, Init(R, 'Source code, documentation, and the most recent version of this application are ' +
    'available ' +
    'at https://github.com/jakobsche/CARLATXT.')));
  R.Assign(0, 17, 6, 19);
  Button := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Button^.Options := Button^.Options or ofCenterX;
  Insert(Button);
end;


{ TCarlaEditor }

procedure TCarlaEditor.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What <> evNothing then
    case Event.Command of
      cmSelectBluePalette: begin
          Palette := wpBlueWindow;
          Redraw;
          ClearEvent(Event)
        end;
      cmSelectCyanPalette: begin
          Palette := wpCyanWindow;
          Redraw;
          ClearEvent(Event)
        end;
      cmSelectGrayPalette: begin
          Palette := wpGrayWindow;
          Redraw;
          ClearEvent(Event)
        end;
    end;
end;

destructor TCarlaEditor.Done;
begin
  if TextApp.EditWindowList <> nil then
    with TextApp.EditWindowList^ do
      if IndexOf(@Self) > -1 then Free(@Self);
  inherited Done;
end;

procedure TCarlaEditor.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and sfSelected <> 0 then
    if Enable then EnableCommands(CarlaEditorCommands)
    else DisableCommands(CarlaEditorCommands)
end;

{ TWindowListBox }

function TWindowListBox.GetText(Item: Integer; MaxLen: Integer): string;
var
  W: PCarlaEditor;
  S: string;
begin
  S := '';
  if List <> nil then begin
    W := List^.At(Item);
    if W = nil then S := ''
    else S := W^.GetTitle(MaxLen - 2);
  end;
  GetText := S
end;


{ TWindowListDialog }

constructor TWindowListDialog.Init;
var
  R: TRect;
  SB: PScrollBar;
begin
  R.Assign(0, 0, 40, 20);
  inherited Init(R, 'Windows');
  Options := Options or ofCenterX or ofCenterY;
  R.Assign(38, 1, 39, 15);
  New(SB, Init(R));
  Insert(SB);
  R.Assign(1, 1, 38, 15);
  New(WindowListBox, Init(R, 1, SB));
  Insert(WindowListBox);
  R.Assign(1, 16, 11, 18);
  Insert(New(PButton, Init(R, 'OK', cmOK, bfDefault)));
  R.Assign(11, 16, 21, 18);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, 0)));
  WindowListBox^.Focus
end;

destructor TWindowListDialog.Done;
begin
  inherited Done;
end;

{ TTextApp }

constructor TTextApp.Init;
var
  NumberL: Longint;
begin
  MaxHeapSize := 1024  {16384   32768};
  EditorDialog := StdEditorDialog;
  inherited Init;
  HighResolution := ScreenMode and smFont8x8 <> 0;
  EditWindowList := New(PEditWindowList, Init(0, 1));
  ClipboardWindow := NewEditWindow('');
  if ClipboardWindow = nil then ShowMessage('No clipboard created')
  else begin
    ClipboardWindow^.Palette := wpCyanWindow;
    Clipboard := ClipboardWindow^.Editor;
    ClipBoardWindow^.Hide;
    NumberL := EditWindowList^.Count;
    MessageBox('%d windows collected', @NumberL, mfInformation or mfOKButton)
  end;
  DisableCommands([cmSelectBluePalette, cmSelectCyanPalette, cmSelectGrayPalette])
end;

destructor TTextApp.Done;
begin
  Dispose(EditWindowList, Done);
  EditWindowList := nil;
  inherited Done
end;

procedure TTextApp.HandleEvent(var Event: TEvent);
var
  R: TRect;
  NumberL: Longint;
  WindowListViewData: TWindowListViewData;
  W: PCarlaEditor;

  function HasFocus(Item: PView): Boolean; far;
  begin
    HasFocus := Item = Desktop^.Current
  end;

  procedure SetDisplayColor(Mode: Word);
  begin
    if HighResolution then SetScreenMode(Mode or smFont8x8)
    else SetScreenMode(Mode and not smFont8x8);
    Redraw;
  end;

begin
  inherited HandleEvent(Event);
  if Event.What and evCommand <> 0 then begin
    case Event.Command of
      cmNew: begin
          if NewEditWindow('') = nil then ShowMessage('No new Window')
          else begin
            NumberL := EditWindowList^.Count;
            MessageBox('%d windows collected', @NumberL, mfInformation or mfOKButton)
          end;
          ClearEvent(Event)
        end;
      cmOpen: begin
          ShowMessage('Datei îffnen');
          ClearEvent(Event);
        end;
      cmSelectWindow: begin
          if EditWindowList <> nil then begin
            WindowListViewData.List := EditWindowList;
            WindowListViewData.Focused := 0;
            Pointer(W) := EditWindowList^.FirstThat(@HasFocus);
            if W <> nil then WindowListViewData.Focused := EditWindowList^.IndexOf(W);
            if ExecuteDialog(New(PWindowListDialog, Init), @WindowListViewData) = cmOK then begin
              W := EditWindowList^.At(WindowListViewData.Focused);
              if PEditWindow(W) = ClipboardWindow then W^.Show;
              W^.Focus
            end
          end;
          ClearEvent(Event)
        end;
      cmResolution: begin
          if HighResolution then SetScreenMode(ScreenMode and not smFont8x8)
          else SetScreenMode(ScreenMode or smFont8x8);
          HighResolution := not HighResolution;
          ClearEvent(Event);
        end;
      cmMono: begin
          SetDisplayColor(smMono);
          ClearEvent(Event);
        end;
      cmBW: begin
          SetDisplayColor(smBW80);
          ClearEvent(Event);
        end;
      cmColor: begin
          SetDisplayColor(smCO80);
          ClearEvent(Event)
        end;
      cmInfo: begin
          ExecuteDialog(New(PAboutBox, Init), nil);
          ClearEvent(Event)
        end;
      cmShowClipboard: begin
          with ClipboardWindow^ do begin
            Show;
            Focus
          end;
          ClearEvent(Event)
        end;
    end
  end
end;

procedure TTextApp.InitMenuBar;
var
  R: TRect;
begin
  R.Assign(0, 0, Size.X, 1);
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile', 0,
      NewMenu(
        StdFileMenuItems(nil)),
    NewSubMenu('~E~dit', 0,
      NewMenu(
        StdEditMenuItems(
        NewLine(
        NewItem('~S~how Clipboard', '', kbNoKey, cmShowClipboard, hcNoContext,
        nil)))),
    NewSubMenu('~V~iew', 0,
      NewMenu(
        NewItem('~R~esolution', '', kbNoKey, cmResolution, hcNoContext,
        NewSubMenu('~S~creen Mode', hcNoContext,
          NewMenu(
            NewItem('~M~onochrome', '', kbNoKey, cmMono, hcNoContext,
            NewItem('~B~lack and White', '', kbNoKey, cmBW, hcNoContext,
            NewItem('~C~olor', '', kbNoKey, cmColor, hcNoContext,
            nil)))),
        nil))),
    NewSubMenu('~W~indow', 0,
      NewMenu(
        StdWindowMenuItems(
        NewSubMenu('Pal~e~tte', hcNoContext,
          NewMenu(
            NewItem('~B~lue', '', kbNoKey, cmSelectBluePalette, hcNoContext,
            NewItem('~C~yan', '', kbNoKey, cmSelectCyanPalette, hcNoContext,
            NewItem('~G~ray', '', kbNoKey, cmSelectGrayPalette, hcNoContext,
            nil)))),
        NewLine(
        NewItem('~L~ist...', '', kbNoKey, cmSelectWindow, hcNoContext,
        nil))))),
    NewSubMenu('~H~elp', hcNoContext,
      NewMenu(
        NewItem('~A~bout ...', 'F1', kbF1, cmInfo, hcNoContext,
        nil)),
    nil))))))));
end;

procedure TTextApp.InitStatusLine;
begin
  inherited InitStatusLine;
end;

function TTextApp.NewEditWindow(AFileName: FNameStr): PCarlaEditor;
var
  i, Number: Integer;
  R: TRect;
  W: PCarlaEditor;
begin
  Number := 0; i := 0;
  while i < EditWindowList^.Count do
    if PWindow(EditWindowList^.Items^[i])^.Number = Number then begin
      Inc(Number); i := 0
    end
    else Inc(i);
  Desktop^.GetExtent(R);
  PWindow(W) := InsertWindow(New(PCarlaEditor, Init(R, AFileName, Number)));
  if W <> nil then EditWindowList^.Insert(W);
  NewEditWindow := W
end;

procedure TTextApp.OutOfMemory;
begin
  inherited OutOfMemory;
  ShowMessage('There is not enough memory for this operation.');
end;

procedure TTextApp.ShowMessage(Msg: string);
begin
  MessageBox(Msg, nil, mfInformation or mfOKButton)
end;


{ TEditWindowList }

procedure TEditWindowList.Error(Code, Info: Integer);
var
  InfoL: Longint;
begin
  case Code of
    coIndexError: begin
        InfoL := Info;
        MessageBox('Collection index %d is invalid.', @InfoL, mfError or mfOKButton)
      end;
    coOverflow: begin
        InfoL := Info;
        MessageBox('The collection could not grow to %d items', @InfoL, mfError or mfOKButton)
      end;
    else MessageBox('Not specified collection Error', nil, mfError or mfOKButton);
  end
end;


procedure TEditWindowList.FreeItem(Item: Pointer);
begin
  {Der Speicher fÅr die Elemente (Editorfenster) wird von TextApp verwaltet.}
end;

end.
