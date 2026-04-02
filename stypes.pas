unit STypes;
{$mode objfpc}
{$modeswitch advancedrecords}
interface
type
    TTypeKind = (TkAlias, TkObject,   TkBool, TkChar,
                 TkNil,   TkTypename, TkEnum, TkArray,
                 TkRange);

    PType = ^TType;

    TFieldRecord = record
        Name:   PChar;
        SType:  PType;
        Offset: Word;
    end;

    PFieldRecord = ^TFieldRecord;

    TFieldList = record
        Count  : Word;
        Fields : PFieldRecord;
        constructor Create (FieldCount : Word);
        function Get (Index : Word) : TFieldRecord;
        //function Size : Word;
        //procedure Add (Field : TFieldRecord);
        procedure Destroy;
    end;

    TType = record
        Name : PChar;
        Size : Word;
        case Kind : TTypeKind of
            TkAlias   : (Original : PType);
            TkObject  : (Fields : TFieldList);
    end;


implementation


constructor TFieldList.Create (FieldCount : Word);
begin
    Self.Count := FieldCount;
    GetMem(Self.Fields, SizeOf(TFieldRecord) * FieldCount);
end;

function TFieldList.Get (Index : Word) : TFieldRecord;
begin
    Result := Self.Fields[Index];
end;

procedure TFieldList.Destroy;
begin
    if Assigned(Self.Fields) then FreeMem(Self.Fields);
end;
end.
