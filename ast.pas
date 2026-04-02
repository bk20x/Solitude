unit Ast;

interface
uses STypes, Option;
type
    TNodeKind = (NkEmpty, NkSymbol, NkBinop, NkVardecl);

    PNode = ^TNode;

    TPNodeOption = specialize TOption<PNode>;
    TPTypeOption = specialize TOption<PType>;

    TNode = record
        case Kind : TNodeKind of
            NkSymbol  : (Name : PChar);
            NkBinop   : (LeftExpr, RightExpr : PNode);
            NkVardecl : (Lhs : PNode; Rhs : TPNodeOption; DeclaredType : TPTypeOption);
    end;


implementation

end.
