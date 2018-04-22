{
  MIT License

  Copyright (c) 2017-2018 Marcos Douglas B. Santos

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
}
unit JamesDataTests;

{$include James.inc}

interface

uses
  Classes, SysUtils, Variants, DB, TypInfo,
  JamesData,
  JamesDataClss,
  JamesTestingClss;

type
  TDataStreamTest = class(TTestCase)
  published
    procedure AsString;
    procedure SaveStream;
    procedure SaveStrings;
  end;

  TDataParamTest = class(TTestCase)
  published
    procedure AutoDataType;
  end;

  TDataParamsTest = class(TTestCase)
  published
    procedure Add;
    procedure AddParam;
    procedure AddParams;
    procedure GetByIndex;
    procedure GetByName;
    procedure Count;
    procedure AsStringWithSeparator;
  end;

  TDataGuidTest = class(TTestCase)
  published
    procedure NewGuid;
    procedure NullGuid;
    procedure ValueAsVariant;
    procedure ValueWithoutBrackets;
    procedure SmallString;
  end;

  TFakeConstraint = class(TInterfacedObject, IDataConstraint)
  private
    FValue: Boolean;
    FId: string;
    FText: string;
  public
    constructor Create(Value: Boolean; const Id, Text: string);
    class function New(Value: Boolean; const Id, Text: string): IDataConstraint;
    function Evaluate: IDataResult;
  end;

  TDataConstraintsTest = class(TTestCase)
  published
    procedure ReceiveConstraint;
    procedure GetConstraint;
    procedure EvaluateTrue;
    procedure EvaluateFalse;
    procedure EvaluateTrueAndFalse;
  end;

  TDataFileTest = class(TTestCase)
  published
    procedure Path;
    procedure Name;
    procedure Stream;
  end;

implementation

{ TDataParamsTest }

procedure TDataParamsTest.Add;
begin
  CheckEquals(
    10,
    TDataParams.New
      .Add('foo', ftSmallint, 10)
      .Get(0)
      .AsInteger
  );
end;

procedure TDataParamsTest.AddParam;
var
  P: IDataParam;
begin
  P := TDataParam.New('foo', 20);
  CheckEquals(
    P.AsInteger,
    TDataParams.New
      .Add(P)
      .Get(0)
      .AsInteger
  );
end;

procedure TDataParamsTest.AddParams;
begin
  CheckEquals(
    5,
    TDataParams.New
      .Add(TDataParam.New('1', 1))
      .Add(TDataParam.New('2', 2))
      .Add(
        TDataParams.New
          .Add(TDataParam.New('3', 3))
          .Add(TDataParam.New('4', 4))
          .Add(TDataParam.New('5', 4))
      )
      .Count
  );
end;

procedure TDataParamsTest.GetByIndex;
begin
  CheckEquals(
    2,
    TDataParams.New
      .Add(TDataParam.New('1', 1))
      .Add(TDataParam.New('2', 2))
      .Get(1)
      .AsInteger
  );
end;

procedure TDataParamsTest.GetByName;
begin
  CheckEquals(
    33,
    TDataParams.New
      .Add(TDataParam.New('foo', 22))
      .Add(TDataParam.New('bar', 33))
      .Get('bar')
      .AsInteger
  );
end;

procedure TDataParamsTest.Count;
begin
  CheckEquals(
    5,
    TDataParams.New
      .Add(TDataParam.New('1', 1))
      .Add(TDataParam.New('2', 2))
      .Add(TDataParam.New('3', 3))
      .Add(TDataParam.New('4', 4))
      .Add(TDataParam.New('5', 4))
      .Count
  );
end;

procedure TDataParamsTest.AsStringWithSeparator;
begin
  CheckEquals(
    '1;2;3',
    TDataParams.New
      .Add(TDataParam.New('1', 1))
      .Add(TDataParam.New('2', 2))
      .Add(TDataParam.New('3', 3))
      .AsString(';')
  );
end;

{ TDataStreamTest }

procedure TDataStreamTest.AsString;
const
  TXT: string = 'Line1-'#13#10'Line2-'#13#10'Line3';
var
  Buf: TMemoryStream;
  Ss: TStrings;
begin
  Buf := TMemoryStream.Create;
  Ss := TStringList.Create;
  try
    Buf.WriteBuffer(TXT[1], Length(TXT) * SizeOf(Char));
    Ss.Text := TXT;
    CheckEquals(TXT, TDataStream.New(Buf).AsString, 'Test Stream');
    CheckEquals(TXT, TDataStream.New(TXT).AsString, 'Test String');
    CheckEquals(TXT+#13#10, TDataStream.New(Ss).AsString, 'Test Strings');
  finally
    Buf.Free;
    Ss.Free;
  end;
end;

procedure TDataStreamTest.SaveStream;
const
  TXT: string = 'ABCDEFG#13#10IJL';
var
  Buf: TMemoryStream;
  S: string;
begin
  Buf := TMemoryStream.Create;
  try
    TDataStream.New(TXT).Save(Buf);
    SetLength(S, Buf.Size * SizeOf(Char));
    Buf.Position := 0;
    Buf.ReadBuffer(S[1], Buf.Size);
    CheckEquals(TXT, S);
  finally
    Buf.Free;
  end;
end;

procedure TDataStreamTest.SaveStrings;
const
  TXT: string = 'ABCDEFG#13#10IJLMNO-PQRS';
var
  Ss: TStrings;
begin
  Ss := TStringList.Create;
  try
    TDataStream.New(TXT).Save(Ss);
    CheckEquals(TXT+#13#10, Ss.Text);
  finally
    Ss.Free;
  end;
end;

{ TDataParamTest }

procedure TDataParamTest.AutoDataType;
var
  Params: IDataParams;
begin
  Params := TDataParams.New
    .Add(TDataParam.New('p1', 'str'))
    .Add(TDataParam.New('p2', 10))
    .Add(TDataParam.New('p3', 20.50))
    ;
  CheckEquals(
    GetEnumName(TypeInfo(TFieldType), Integer(ftString)),
    GetEnumName(TypeInfo(TFieldType), Integer(Params.Get(0).DataType))
  );
  CheckEquals(
    GetEnumName(TypeInfo(TFieldType), Integer(ftSmallint)),
    GetEnumName(TypeInfo(TFieldType), Integer(Params.Get(1).DataType))
  );
  CheckEquals(
    GetEnumName(TypeInfo(TFieldType), Integer(ftFloat)),
    GetEnumName(TypeInfo(TFieldType), Integer(Params.Get(2).DataType))
  );
end;

{ TDataGuidTest }

procedure TDataGuidTest.NewGuid;
begin
  StringToGUID(TDataGuid.New.AsString);
end;

procedure TDataGuidTest.NullGuid;
begin
  CheckEquals(
    TNullGuid.New.AsString,
    TDataGuid.New('foo').AsString
  );
end;

procedure TDataGuidTest.ValueAsVariant;
begin
  CheckEquals(
    TNullGuid.New.AsString,
    TDataGuid.New(NULL).AsString
  );
end;

procedure TDataGuidTest.ValueWithoutBrackets;
const
  G: string = 'FCCE420A-8C4F-4E54-84D1-39001AE344BA';
begin
  CheckEquals(
    '{' + G + '}',
    TDataGuid.New(G).AsString
  );
end;

procedure TDataGuidTest.SmallString;
const
  V = '89000BC9';
  G = '{'+V+'-5700-43A3-B340-E34A1656F683}';
begin
  CheckEquals(
    V, TDataGuid.New(G).AsSmallString
  );
end;

{ TFakeConstraint }

constructor TFakeConstraint.Create(Value: Boolean; const Id, Text: string);
begin
  inherited Create;
  FValue := Value;
  FId := Id;
  FText := Text;
end;

class function TFakeConstraint.New(Value: Boolean; const Id, Text: string
  ): IDataConstraint;
begin
  Result := Create(Value, Id, Text);
end;

function TFakeConstraint.Evaluate: IDataResult;
begin
  Result := TDataResult.New(
    FValue,
    TDataParam.New(FId, ftString, FText)
  );
end;

{ TDataConstraintsTest }

procedure TDataConstraintsTest.ReceiveConstraint;
begin
  CheckTrue(
    TDataConstraints.New
      .Add(TFakeConstraint.New(True, 'id', 'foo'))
      .Evaluate
      .Success
  );
end;

procedure TDataConstraintsTest.GetConstraint;
begin
  CheckEquals(
    'foo',
    TDataConstraints.New
      .Add(TFakeConstraint.New(True, 'id', 'foo'))
      .Evaluate
      .Data
      .AsString
  );
end;

procedure TDataConstraintsTest.EvaluateTrue;
begin
  CheckTrue(
    TDataConstraints.New
      .Add(TFakeConstraint.New(True, 'id', 'foo'))
      .Add(TFakeConstraint.New(True, 'id', 'foo'))
      .Evaluate
      .Success
  );
end;

procedure TDataConstraintsTest.EvaluateFalse;
begin
  CheckFalse(
    TDataConstraints.New
      .Add(TFakeConstraint.New(False, 'id', 'foo'))
      .Add(TFakeConstraint.New(False, 'id', 'foo'))
      .Evaluate
      .Success
  );
end;

procedure TDataConstraintsTest.EvaluateTrueAndFalse;
begin
  CheckFalse(
    TDataConstraints.New
      .Add(TFakeConstraint.New(True, 'id', 'foo'))
      .Add(TFakeConstraint.New(False, 'id', 'foo'))
      .Evaluate
      .Success
  );
end;

{ TDataFileTest }

procedure TDataFileTest.Path;
begin
  CheckEquals('c:\path\', TDataFile.New('c:\path\filename.txt').Path);
end;

procedure TDataFileTest.Name;
begin
  CheckEquals('filename.txt', TDataFile.New('c:\path\filename.txt').Name);
end;

procedure TDataFileTest.Stream;
const
  TXT: string = 'ABCC~#';
  FILE_NAME: string = 'file.txt';
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteBuffer(TXT[1], Length(TXT) * SizeOf(Char));
    M.SaveToFile(FILE_NAME);
    CheckEquals(TXT, TDataFile.New(FILE_NAME).Stream.AsString);
  finally
    DeleteFile(FILE_NAME);
    M.Free;
  end;
end;

initialization
  TTestSuite.New('Data')
    .Add(TTest.New(TDataStreamTest))
    .Add(TTest.New(TDataParamTest))
    .Add(TTest.New(TDataParamsTest))
    .Add(TTest.New(TDataGuidTest))
    .Add(TTest.New(TDataConstraintsTest))
    .Add(TTest.New(TDataFileTest))
    ;

end.
