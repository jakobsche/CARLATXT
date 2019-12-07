unit CharDlg;


interface

uses Dialogs;

type
  PCharacterDialog = ^TCharacterDialog;
  TCharacterDialog = object(TDialog)
    constructor Init;
    destructor Done; virtual;
  private
    ListBox: PListBox;
  end;


implementation

uses Global, Objects, Views;

type
  PCharacterCollection = ^TCharacterCollection;
  TCharacterCollection = object(TCollection)
    constructor Init;
    procedure FreeItem(Item: Pointer); virtual;
  end;

constructor TCharacterCollection.Init;
var
  i: Integer;
begin
  inherited Init(256, 0);
  for i := 0 to 255 do begin
    Insert(NewStr(Chr(i)))
  end
end;

procedure TCharacterCollection.FreeItem(Item: Pointer);
begin
  if Item <> nil then DisposeStr(Item);
end;


constructor TCharacterDialog.Init;
var
  R: TRect;
begin
  R.Assign(0, 0, 66, 20);
  inherited Init(R, 'Special Characters');
  Options := Options or ofCentered;
  HelpCtx := hcCharTable;
  R.Assign(2, 2, 65, 18);
  New(ListBox, Init(R, 16, nil));
  ListBox^.NewList(New(PCharacterCollection, Init));
  Insert(ListBox);
  R.Assign(2, 1, 65, 2);
  Insert(New(PStaticText, Init(R, ' 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F')));
  R.Assign(1, 2, 2, 18);
  Insert(New(PStaticText, Init(R, '0123456789ABCDEF')));
end;

destructor TCharacterDialog.Done;
begin
  if ListBox <> nil then ListBox^.NewList(ListBox^.List);
  inherited Done
end;

end.