unit Option;
{$mode delphi} // much less verbose for generics lol
{$modeswitch advancedrecords}

interface
uses Typinfo, SysUtils;

type
    TOption<T> = record
        strict private
            Value  : T;
            Exists : Boolean;
        public
        function Get: T;
        function IsSome: Boolean;
        class function Some  (AValue : T): TOption<T>; static;
        class function None: TOption<T>; static;
    end;
const
    PointerTypes = [
        tkPointer,  tkClass,   tkInterface, tkClassRef, tkProcVar,
        tkDynArray, tkUString, tkLString,   tkWString
    ];
implementation
class function TOption<T>.Some (AValue : T): TOption<T>;
var
    theType: TTypeKind;
begin
    Result := Default(TOption<T>);
    theType := GetTypeKind(T);
    
    if theType in PointerTypes then
    begin
        if AValue = nil then raise Exception.Create('Attempt to create `Some` of nil');
    end
    else if theType = tkMethod then
    begin
        if TMethod((@AValue)^).Code = nil then raise Exception.Create('Attempt to create `Some` of nil');
    end;
    Result.Exists := True;
    Result.Value  := AValue;
end;

class function TOption<T>.None: TOption<T>;
begin
    Result := Default(TOption<T>);
    Result.Exists := False;
end;

function TOption<T>.IsSome: Boolean;
begin
    Result := Self.Exists;
end;

function TOption<T>.Get: T;
begin
    if not Self.Exists then raise Exception.Create('Attempt to get value of None');
    Result := Self.Value;
end;
end.