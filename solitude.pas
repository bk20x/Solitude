program Solitude;
uses Lexing, Ast, Option, SysUtils, StrUtils, Classes;

{$assertions ON}
var
    lexer : TLexer;
    s : String;
    strs : TStringList;
    text : AnsiString;
    procedure PrintKeywordHashes;
    var
        i : Integer;
        hash : Cardinal;
        keywords : array of AnsiString;
    begin
        keywords := [
            'do', 'end', 'if', 'else', 'proc', 'while', 'for', 'type', 'struct', 'return', 'and', 'or', 'in'
        ];
        for i := Low(keywords) to High(keywords) do
        begin
            hash := SymHash(PChar(keywords[i]), Length(keywords[i]));
            Write('Hash of ' + keywords[i] + ' = '); WriteLn(hash);
        end;
    end;
begin
    strs := TStringList.Create;
    strs.LoadFromFile(paramStr(1));
    PrintKeywordHashes();
    text := strs.text;
    lexer := CreateLexer(text);
    
    with lexer do
    begin
        NextToken(lexer);
        while token.kind <> TkEof do
        begin
            WriteLn(Format('%s at Line: %d Col: %d', [TokenImage(token), token.LineInfos.Line, token.LineInfos.Col]));
            NextToken(lexer);
        end;
        {if token.kind = TkEof then 
            WriteLn('Program: ');
            for s in SplitString(buf, String(LF)) do
                WriteLn('    ' + s);}
        
    end;    
end.
