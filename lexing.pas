unit Lexing;
{$mode objfpc}

interface
uses Strings, SysUtils;
const
    CR          = #13;
    LF          = #10;
    EOF         = #0;
    HASH_DO     = 3211;
    HASH_END    = 100571;
    HASH_IF     = 3357;
    HASH_ELSE   = 3116345;
    HASH_PROC   = 3449686;
    HASH_WHILE  = 113101617;
    HASH_FOR    = 101577;
    HASH_TYPE   = 3575610;
    HASH_STRUCT = 3402992597;
    HASH_RETURN = 3360570672;
    HASH_AND    = 96727;
    HASH_OR     = 3555;
    HASH_IN     = 3365;
    HASH_TRUE   = 3569038;
    HASH_FALSE  = 97196323;
type
    TokenKind = (TkInt, 
                 TkFloat, 
                 TkString, 
                 TkBool,
                 TkSymbol, 
                 TkOperator,
                 TkProc,     // `proc`
                 TkType,     // `type`
                 TkReturn,   // `return`
                 TkIf,       // `if`
                 TkElse,     // `else`
                 TkWhile,    // `while`
                 TkFor,      // `for`
                 TkIn,       // `in`
                 TkAnd,      // `and`
                 TkOr,       // `or`
                 TkStruct,   // `struct`
                 TkDo,       // `do`
                 TkEnd,      // `end`
                 TkDot,      // `.`
                 TkRangeSep, // `..`
                 TkLParen,   // `(`
                 TkRParen,   // `)`
                 TkColon,    // `:`
                 TkEq,       // `=`
                 TkAssign,   // `:=`
                 TkComma,    // `,`
                 TkAssoc,    // `=>`
                 TkSemicol,  // `;`. Only required for multiple expressions / statements on the same line
                 TkEof,
                 TkInvalid);

    TLineInfos = packed record
        Line, Col : Word; 
    end;

    TToken = record
        Used      : Boolean;
        LineInfos : TLineInfos; // Where the Lexer recognized this as a token (for Strings it is the Position of "... etc)
        case Kind : TokenKind of
            TkInt      : (IntVal   : Integer);
            TkBool     : (BoolVal  : Boolean);
            TkFloat    : (FloatVal : Real);
            TkString   : (StrVal   : PChar);
            TkSymbol   : (Name     : PChar);
            TkOperator : (Op       : String[3]);
            TkInvalid  : (Problem  : Char); // only deals with invalid characters. symbols are not yet resolved
    end;

    TLexer = record
        Buf      : PChar;
        Line     : Word; // Line and Col start at 1
        Col      : Word;
        Position : Integer;
        Token    : TToken;
    end;		


function  CreateLexer (const Input : AnsiString) : TLexer;
function  IsNumeric  (AChar : Char) : Boolean;
function  TokenImage (Token : TToken) : AnsiString;
function  SymHash (Str : PChar; Len : Word) : Cardinal;
procedure Advance (var Lexer : TLexer; By : Word = 1); {advances Lexer.Position and Lexer.Col by `By`. Lexer.Col is set back to 1 when CR or LF are encountered in `SkipWhitespace`}
procedure SkipWhitespace (var Lexer : TLexer);
procedure LexSymbol (var Lexer : TLexer);
procedure LexString (var Lexer : TLexer);
procedure LexNumber (var Lexer : TLexer);
procedure NextToken (var Lexer : TLexer);
procedure FreeTokenData (var Token : TToken);
procedure UseToken  (var Token : TToken);  {marks a token as being used for to not free its contents when `NextToken` is called. Going to see how i like this "transfer" over manually freeing the strings}

implementation
function SymHash (Str : PChar; Len : Word) : Cardinal;
var
    i : Word;
begin
    Result := 0;
    for i := 0 to Len - 1 do
        Result := (Result * 31) + Ord(Str[i]);
end;

function CreateLexer (const Input : AnsiString) : TLexer;
begin
    Result.Buf := PChar(Input);
    Result.Position := 0;
    Result.Line := 1;
    Result.Col  := 1;
    Result.Token.Kind := TkEof; 
end;

function IsNumeric (AChar : Char) : Boolean;
begin
    Result := AChar in ['0'..'9'];
end;

procedure Advance (var Lexer : TLexer; By : Word = 1);
begin
    Inc(Lexer.Col, By);
    Inc(Lexer.Position, By);
end;

procedure SkipWhitespace (var Lexer : TLexer);
begin
    with Lexer do
    begin
        while (Buf[Position] <> EOF) and (Buf[Position] <= #32) do
        begin
            case Buf[Position] of 
                CR : 
                    if Buf[Position + 1] = LF then
                    begin
                        Inc(Position, 2);
                        Inc(Line);
                        Col := 1;
                    end
                    else begin
                        Inc(Position);
                        Inc(Line);
                        Col := 1;
                    end;
                LF : 
                    begin
                        Inc(Position);
                        Inc(Line);
                        Col := 1;
                    end;
            else begin
                    Advance(Lexer);
                end
            end
        end;
    end;
end;

procedure LexSymbol(var Lexer: TLexer);
var
    start: PChar;
    len  : Word;
    hash : Cardinal;
begin

    with Lexer do
    begin
        start := Buf + Position;
        while (Buf[Position] in ['a'..'z', 'A'..'Z']) do
            Advance(Lexer);
        len  := (Buf + Position) - start;
        hash := SymHash(start, len); 
        case hash of
            HASH_DO     : Token.Kind := TkDo;
            HASH_END    : Token.Kind := TkEnd;
            HASH_PROC   : Token.Kind := TkProc;
            HASH_WHILE  : Token.Kind := TkWhile;
            HASH_FOR    : Token.Kind := TkFor;
            HASH_IF     : Token.Kind := TkIf;
            HASH_ELSE   : Token.Kind := TkElse;
            HASH_TYPE   : Token.Kind := TkType;
            HASH_RETURN : Token.Kind := TkReturn;
            HASH_STRUCT : Token.Kind := TkStruct;
            HASH_AND    : Token.Kind := TkAnd;
            HASH_OR     : Token.Kind := TkOr;
            HASH_IN     : Token.Kind := TkIn;
            HASH_TRUE   :
                    begin
                        Token.Kind := TkBool;
                        Token.BoolVal := True;
                    end;
            HASH_FALSE  :
                    begin
                        Token.Kind := TkBool;
                        Token.BoolVal := False;
                    end;
        else
            Token.Kind := TkSymbol;
            Token.Name := StrAlloc(len + 1);
            StrLCopy(Token.Name, start, len);
        end;
    end;
end;

procedure LexString (var Lexer : TLexer);
var
    theString : AnsiString;
begin
    theString := '';
    with Lexer do
    begin
        Advance(Lexer);
        while (Buf[Position] <> #0) and (Buf[Position] <> '"') do
        begin
            if (Buf[Position] = '\') then 
            begin
                Advance(Lexer);
                case Buf[Position] of
                    '"' : theString := theString + '"';
                    '\' : theString := theString + '\';
                    'n' : theString := theString + #10;
                    'r' : theString := theString + #13;
                    't' : theString := theString + #9;
                else
                    theString := theString + Buf[Position];
                end;
            end
            else theString := theString + Buf[Position];
            Advance(Lexer);
        end;    
        if Buf[Position] = '"' then Advance(Lexer);
        Token.Kind      := TkString;
        Token.StrVal    := StrNew(PChar(theString));
    end;
end;

procedure LexNumber(var Lexer: TLexer);
var
    start   : Integer;
    isFloat : Boolean;
    current : Char;
    next    : Char;
    substr  : AnsiString;
begin
    start := Lexer.Position;
    isFloat := False;
    with Lexer do
    begin
        while True do
        begin
            current := Buf[Position];
            case current of
                '0'..'9': ; 
                '.': 
                    begin
                        { if the dot isnt followed by digit leave TkDot and following symbol to be tokenized separately (for UFCS) }
                        next := Buf[Position + 1];
                        if not IsNumeric(next) then break;
                        isFloat := True;
                    end;
                'e', 'E': isFloat := True;
                '+', '-':
                    begin
                        { allowed only as the sign or after exponent }
                        if (Position <> start) and (not (Buf[Position - 1] in ['e', 'E'])) then break;
                    end;
                else break;
            end;
            Advance(Lexer);
        end;
        
        SetString(substr, @Buf[start], Position - start);
    
        if isFloat then
        begin
            Token.Kind := TkFloat;
            Token.FloatVal := StrToFloat(substr);
        end
        else
        begin
            Token.Kind := TkInt;
            Token.IntVal := StrToInt(substr);
        end;
    end;
end;

procedure NextToken (var Lexer : TLexer);
var
    nextChar: Char;
begin
    if not Lexer.Token.Used then FreeTokenData(Lexer.Token);
    SkipWhitespace(Lexer);
    with Lexer do
    begin
        Token.LineInfos.Col  := Col;
        Token.LineInfos.Line := Line;
        case Buf[Position] of
            EOF      : Token.Kind := TkEof;
            '.'      : 
                begin
                    nextChar := Buf[Position + 1];
                    if nextChar = '.' then
                    begin
                        Advance(Lexer, 2);
                        Token.Kind := TkRangeSep;
                    end
                    else begin
                        Advance(Lexer); 
                        Token.Kind := TkDot;
                    end;
                end;
            ','      :
                begin
                    Advance(Lexer);
                    Token.Kind := TkComma;
                end;
            '('      :
                begin
                    Advance(Lexer);
                    Token.Kind := TkLParen;
                end;
            ')'      :
                begin
                    Advance(Lexer);
                    Token.Kind := TkRParen;
                end;
            ':'      :
                begin
                    nextChar := Buf[Position + 1];
                    if nextChar = '=' then 
                    begin
                        Advance(Lexer, 2);
                        Token.Kind := TkAssign;
                    end
                    else begin
                        Advance(Lexer);
                        Token.Kind := TkColon;
                    end;
                end;
            ';'      :
                begin
                    Advance(Lexer);
                    Token.Kind := TkSemicol;
                end;
            '='      :
                begin
                    nextChar := Buf[Position + 1];
                    if nextChar = '>' then
                    begin
                        Advance(Lexer, 2);
                        Token.Kind := TkAssoc;
                    end
                    else begin
                        Advance(Lexer);
                        Token.Kind := TkEq;
                    end
                end;
            '"'      : LexString(Lexer);
            '0'..'9' : LexNumber(Lexer);
            'a'..'z', 'A'..'Z': LexSymbol(Lexer);
            '-', '+' : 
                begin
                    nextChar := Buf[Position + 1];
                    if IsNumeric(nextChar) then 
                    begin
                        LexNumber(Lexer);
                    end
                    else begin
                        Token.Kind := TkOperator;
                        Token.Op   := Buf[Position];
                        Advance(Lexer);
                    end;
                end;
            '*', '/', '^', '%':
                begin
                    Token.Kind := TkOperator;
                    Token.Op   := Buf[Position];
                    Advance(Lexer);
                end;
            '<', '>':
                begin
                    nextChar := Buf[Position + 1];
                    if nextChar = '=' then
                    begin
                        Token.Kind := TkOperator;
                        Token.Op   := Buf[Position] + nextChar;
                        Advance(Lexer, 2);
                    end
                    else begin
                        Token.Kind := TkOperator;
                        Token.Op   := Buf[Position];
                        Advance(Lexer);
                    end;
                end;
        else 
            begin
                Token.Kind := TkInvalid;
                Token.Problem := Buf[Position];
                Advance(Lexer);
            end;
        end;
    end;
end;

procedure FreeTokenData (var Token : TToken);
begin
    case Token.Kind of
        TkString : StrDispose(Token.StrVal);
        TkSymbol : StrDispose(Token.Name);
    end;
    Token.Kind := TkEof;
end;

function TokenImage (Token : TToken) : AnsiString;
var
    kindString : String;
begin
    kindString := '';
    case Token.Kind of
        TkEof     : Result := 'Token(EOF)';
        TkAssoc   : Result := 'Token(`=>`)';
        TkDot     : Result := 'Token(`.`)';
        TkRangeSep: Result := 'Token(`..`)';
        TkComma   : Result := 'Token(`,`)';
        TkLParen  : Result := 'Token(`(`)';
        TkRParen  : Result := 'Token(`)`)';
        TkColon   : Result := 'Token(`:`)';
        TkSemicol : Result := 'Token(`;`)';
        TkAssign  : Result := 'Token(`:=`)';
        TkEq      : Result := 'Token(`=`)';
        TkIf      : Result := 'Token(`if`)';
        TkElse    : Result := 'Token(`else`)';
        TkWhile   : Result := 'Token(`while`)';        
        TkDo      : Result := 'Token(`do`)';
        TkEnd     : Result := 'Token(`end`)';
        TkProc    : Result := 'Token(`proc`)';
        TkType    : Result := 'Token(`type`)';       
        TkReturn  : Result := 'Token(`return`)';
        TkFor     : Result := 'Token(`for`)';
        TkIn      : Result := 'Token(`in`)';
        TkAnd     : Result := 'Token(`and`)';
        TkOr      : Result := 'Token(`or`)';
        TkStruct  : Result := 'Token(`struct`)';
        TkFloat   : Result := Format('Token(Kind: Float, Value: %f)',    [Token.FloatVal]);
        TkInt     : Result := Format('Token(Kind: Int, Value: %d)',      [Token.IntVal]);
        TkString  : Result := Format('Token(Kind: String, Value: %s)',   [Token.StrVal]);        
        TkSymbol  : Result := Format('Token(Kind: Symbol, Value: %s)',   [Token.Name]); 
        TkBool    : Result := Format('Token(Kind: Bool, Value: %s)',     [BoolToStr(Token.BoolVal)]);
        TkOperator: Result := Format('Token(Kind: Operator, Value: %s)', [Token.Op]);
        TkInvalid : Result := Format('Invalid Token(%s)', [Token.Problem]);
    else
        WriteStr(kindString, Token.Kind);
        Result := 'To String not implemented for Token Kind ' + kindString;
    end;
end;

procedure UseToken (var Token : TToken);
begin
    Token.Used := True;
end;
end.
