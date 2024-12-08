unit Zoomicon.Helpers.RTL.StringsHelpers;

interface
  uses
    System.Classes; //for TStrings

  type

    TStringsHelper = class helper for TStrings
      function GetLines(const AStart, AEnd: Integer; const AddTrailingLineBreak :Boolean = false): string;
    end;


implementation
  uses
    System.Math; //for Min

{$REGION 'TStringsHelper'}

  function TStringsHelper.GetLines(const AStart, AEnd: Integer; const AddTrailingLineBreak :Boolean = false): string; //see https://stackoverflow.com/a/11028950
  begin
    Result := '';
    if (AStart < AEnd) then
      Exit;

    var LLast := Min(AEnd, Count - 1);
    for var I := AStart to  (LLast - 1) do
      Result := Result + Self[I] + sLineBreak;

    Result := Result + Self[LLast]; //add the last item separately to avoid the extra line-break

    if AddTrailingLineBreak then
      Result := Result + sLineBreak;
  end;

{$ENDREGION}

end.
