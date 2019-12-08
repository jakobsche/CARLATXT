{ Das Anwendungsobjekt }

unit Base;


interface


uses
  App, EApp, Dialogs, Drivers, Editors, Menus, Objects, Views;



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
  cmShowCharTable     = 1008;


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
    constructor Init(var Bounds: TRect; FileName: FNameStr; ANumber: Integer);
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
    procedure HandleEvent(var Event: TEvent); virtual;
  end;


  { TWindowListDialog }

  PWindowListDialog = ^TWindowListDialog;
  TWindowListDialog = object(TDialog)
    WindowListBox: PWindowListBox;
    constructor Init;
    destructor Done; virtual;
  end;


  PTextAppStatusLine = ^TTextAppStatusLine;
  TTextAppStatusLine = object(TStatusLine)
    function Hint(AHelpCtx: Word): string; virtual;
  end;

  { TTextApp }

  TTextApp = object(TExtendedApplication)
    constructor Init;
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    function NewEditWindow(AFileName: FNameStr): PCarlaEditor;
    procedure OutOfMemory; virtual;
    procedure ShowMessage(Msg: string);
    procedure WriteShellMsg; virtual;
  private
    ClipboardWindow: PCarlaEditor;
    EditWindowList: PEditWindowList;
    HighResolution: Boolean;
  end;


var
  TextApp: TTextApp;


implementation

uses Global, MsgBox, Memory, StdDlg, DOS, CharDlg;


type
  TWindowListViewData = packed record {fÅr TTextApp.HandleEvent verwendet}
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
  inherited Init(R, 'About CARLATXT');
  Options := Options or ofCentered;
  R.Assign(1, 1, 39, 2);
  Insert(New(PStaticText, Init(R, 'ASCII file editor')));
  R.Assign(1, 3, 39, 4);
  Insert(New(PStaticText, Init(R, 'Copyright 2019 Andreas Jakobsche')));
  R.Assign(1, 5, 39, 7);
  Insert(New(PStaticText, Init(R, 'dedicated to Carla Fischer, carlafischer.de')));
  R.Assign(1, 8, 39, 11);
  Insert(New(PStaticText, Init(R, 'This application requires DPMI. If it is not available, messages about missing files are ' +
    'generated.')));
  R.Assign(1, 12, 39, 16);
  Insert(New(PStaticText, Init(R, 'Source code, documentation, and the most recent version of this application are ' +
    'available ' +
    'at https://github.com/jakobsche/CARLATXT.')));
  R.Assign(0, 17, 6, 19);
  Button := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Button^.Options := Button^.Options or ofCenterX;
  Insert(Button);
end;


{ TCarlaEditor }

constructor TCarlaEditor.Init(var Bounds: TRect; FileName: FNameStr; ANumber: Integer);
begin
  inherited Init(Bounds, FileName, ANumber);
  HelpCtx := hcCarlaEditor
end;

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
      if IndexOf(@Self) > -1 then Delete(@Self);
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

procedure TWindowListBox.HandleEvent(var Event: TEvent);
var
  E: TEvent;
begin
  if Event.What = evMouseDown then begin
    if Event.Double then begin
      {TextApp.ShowMessage('Doppelklick wahrgenommen');}
      with E do begin
        E.What := evCommand;
        E.Command := cmOK;
        E.InfoPtr := @Self;
        PutEvent(E)
      end;
      ClearEvent(Event)
    end
  end;
  inherited HandleEvent(Event);
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
  Insert(New(PButton, Init(R, 'O~K~', cmOK, bfDefault)));
  R.Assign(11, 16, 21, 18);
  Insert(New(PButton, Init(R, '~C~ancel', cmCancel, 0)));
  WindowListBox^.Focus
end;

destructor TWindowListDialog.Done;
begin
  inherited Done;
end;


{ TTextAppStatusLine }

function TTextAppStatusLine.Hint(AHelpCtx: Word): string;
begin
  case AHelpCtx of

  { Vordefinierte Hilfekontexte }
    hcNoContext: Hint := 'Select an option';
    hcDragging: Hint := 'Use '#27' '#26' '#24' '#25' with or without Shift, Esc resets, '#$11#$D9' completes';

  { Diese Anwendung }
    hcShowClipboard: Hint := 'Display clipboard content';
    hcCarlaEditor: Hint := 'Write / edit text or select an option';
    hcShowCharTable: Hint := 'To insert special characters';
    hcCharTable: Hint := 'Select a character';

  { Vordefinierte Hilfekontexte }
    hcNew: Hint := 'Create file';
    hcOpen: Hint := 'Edit file from disk';
    hcSave: Hint := 'Save text';
    hcSaveAs: Hint := 'Save text to new file';
    hcSaveAll: Hint := 'Save all open files';
    hcChangeDir: Hint := 'Make other directory default';
    hcDOSShell: Hint := 'Use DOS shell';
    hcExit: Hint := 'Quit this application';
    hcUndo: Hint := 'Discard last change';
    hcCut: Hint := 'Cut selected text to clipboard';
    hcCopy: Hint := 'Copy selected text to clipboard';
    hcPaste: Hint := 'Insert from clipboard';
    hcClear: Hint := 'Remove selected text';
    hcTile: Hint := 'Place windows near each other';
    hcCascade: Hint := 'Place Windows particularly overlapping each other';
    hcCloseAll: Hint := 'Close all windows';
    hcResize: Hint := 'Size and move the active window';
    hcZoom: Hint := 'Toggle window size to maximum or reverse';
    hcNext: Hint := 'Select next window';
    hcPrev: Hint := 'Select previous window';
    hcClose: Hint := 'close the active window';

  { Geerbte Hilfekontexte }
    else Hint := inherited Hint(AHelpCtx);

  end
end;


{ TTextApp }

constructor TTextApp.Init;
begin
  MaxHeapSize := 1024;
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
  end;
  DisableCommands(CarlaEditorCommands)
end;

destructor TTextApp.Done;
begin
  Dispose(EditWindowList, Done);
  EditWindowList := nil;
  inherited Done
end;

procedure TTextApp.HandleEvent(var Event: TEvent);

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

  procedure SaveItem(Item: PCarlaEditor); far;
  begin
    if Item <> ClipboardWindow then begin
      Item^.Show;
      Item^.Select;
      Item^.Editor^.Save
    end
  end;

var
  R: TRect;
  WindowListViewData: TWindowListViewData;
  W: PCarlaEditor;
  FN: string;
  i: Integer;
begin
  inherited HandleEvent(Event);
  if Event.What and evCommand <> 0 then begin
    case Event.Command of
      cmNew: begin
          if NewEditWindow('') = nil then ShowMessage('No new Window')
          else begin

          end;
          ClearEvent(Event)
        end;
      cmOpen: begin
          FN := '';
          if ExecuteDialog(New(PFileDialog, Init('*.*', 'Open', '', fdOKButton, 0)), @FN) <> cmCancel then
          begin
            if NewEditWindow(FN) = nil then ShowMessage('No new Window')
            else begin

            end;
          end;
          ClearEvent(Event);
        end;
      cmSaveAll: begin
          ShowMessage('Alles speichern');
          EditWindowList^.ForEach(@SaveItem);
          ClearEvent(Event)
        end;
      cmCloseAll: with EditWindowList^ do begin
          {Anmerkung: Die Zwischenablage bleibt erhalten, wird beim Schlie·en
          also nicht entfernt.}
          i := 0;
          while Count > 1 do begin
            PCarlaEditor(Items^[i])^.Close;
            if Items^[i] = ClipboardWindow then Inc(i);
          end;
          ClearEvent(Event);
        end;
      cmChangeDir: begin
          ExecuteDialog(New(PChDirDialog, Init(cdNormal, 0)), nil);
          ClearEvent(Event)
        end;
      cmSelectWindow: begin
          if EditWindowList <> nil then begin
            WindowListViewData.List := EditWindowList;
            WindowListViewData.Focused := 0;
            Pointer(W) := EditWindowList^.FirstThat(@HasFocus);
            if W <> nil then WindowListViewData.Focused := EditWindowList^.IndexOf(W);
            if ExecuteDialog(New(PWindowListDialog, Init), @WindowListViewData) = cmOK then begin
              W := EditWindowList^.At(WindowListViewData.Focused);
              if W = ClipboardWindow then W^.Show;
              W^.Focus
            end
          end;
          ClearEvent(Event)
        end;
      cmResolution: begin
          SetScreenMode(ScreenMode xor smFont8x8);
          HighResolution := ScreenMode and smFont8x8 <> 0;
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
      cmShowCharTable: begin
          ExecuteDialog(New(PCharacterDialog, Init), nil);
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
        NewItem('C~h~aracter table ...', '', kbNoKey, cmShowCharTable, hcShowCharTable,
        NewLine(
        NewItem('~S~how Clipboard', '', kbNoKey, cmShowClipboard, hcShowClipboard,
        nil)))))),
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
        NewItem('~L~ist...', 'Alt-0', kbAlt0, cmSelectWindow, hcNoContext,
        nil))))),
    NewSubMenu('~H~elp', hcNoContext,
      NewMenu(
        NewItem('~A~bout ...', 'F1', kbF1, cmInfo, hcNoContext,
        nil)),
    nil))))))));
end;

procedure TTextApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PTextAppStatusLine, Init(R,
    NewStatusDef($0000, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu,
      StdStatusKeys(
      nil))),
    nil)));
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

procedure TTextApp.WriteShellMsg;
begin
  PrintStr('Type EXIT to return to CARLATXT'#13#10#13#10)
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
