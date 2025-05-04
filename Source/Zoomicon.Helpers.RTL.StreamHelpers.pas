unit Zoomicon.Helpers.RTL.StreamHelpers;

interface
  uses
    System.Classes, //for TStream, TComponent
    System.SysUtils; //for TBytes

  type

    TStreamErrorHelper = class helper for TStream
      function ReadComponent(const Instance: TComponent; const ReaderError: TReaderError): TComponent;
    end;

    TStreamReadAllHelper = class helper(TStreamErrorHelper) for TStream
      function ReadAllBytes: TBytes;
      function ReadAllText(const DefaultEncoding: TEncoding = nil; const ForceDefaultEncoding: Boolean = false): string;
    end;

    TStreamPreambleHelper = class helper(TStreamReadAllHelper) for TStream
      function ReadBytes(const MaxBytes: Integer): TBytes;
      function PeekBytes(const MaxBytes: Integer): TBytes;
      function PeekString(const MaxBytes: Integer; Encoding: TEncoding = nil): String;
      procedure SkipBOM_UTF8;
      //TODO: Add SkipBOM_UTF16_BE (Big-Endian), SkipBOM_UTF16_LE (Little-Endian)
    end;

implementation
  uses
    System.RTLConsts, //for SFileTooLong
    System.Math; //for Min

{$REGION 'TStreamErrorHelper'}

function TStreamErrorHelper.ReadComponent(const Instance: TComponent; const ReaderError: TReaderError): TComponent;
begin //based on TStream.ReadComponent (of Delphi 11 RTL, as on 2022-01-24)
  var reader := TReader.Create(Self, 4096);
  reader.OnError := ReaderError; //the error handler can ignore specific not found properties
  try
    result := Reader.ReadRootComponent(Instance); //if we pass nil returns a new instance
  finally
    Reader.Free;
  end;
end;

{$ENDREGION}

{$REGION 'TStreamReadAllHelper'}

  function TStreamReadAllHelper.ReadAllBytes: TBytes;
  begin
    var LDataSize := Size; //TStream.Size is Int64
    {$IFDEF CPU32BITS}
    if LDataSize > MaxInt then
      raise EInOutError.CreateRes(@SFileTooLong); //need to check this, since TStream.SetLength accepts Integer which has platform-specific size
    {$ENDIF}
    SetLength(Result, LDataSize);
    ReadBuffer(result, Length(result));
  end;

  function TStreamReadAllHelper.ReadAllText(const DefaultEncoding: TEncoding = nil; const ForceDefaultEncoding: Boolean = false): string;
  var FoundEncoding: TEncoding;
  begin
    var Buff := ReadAllBytes;
    if ForceDefaultEncoding then
      FoundEncoding := DefaultEncoding
      else
      FoundEncoding := nil; //doc for TEncoding.GetBufferEncoding writes: "The AEncoding parameter should have the value NIL, otherwise its value is used to detect the encoding" //Note: Delphi doesn't auto-initialize local variables, so we need to explicitly set to nil
    var BOMLength := TEncoding.GetBufferEncoding(Buff, FoundEncoding, DefaultEncoding);
    result := FoundEncoding.GetString(Buff, BOMLength, Length(Buff) - BOMLength); //TODO: not sure if this will do transcoding if the real encoding of the file was different from DefaultEncoding and we used ForceDefaultEncoding=true - may need to implement it somehow
  end;

{$ENDREGION}

{$REGION 'TStreamPreambleHelper'}

  function TStreamPreambleHelper.ReadBytes(const MaxBytes: Integer): TBytes;
  begin
    var LReadLen := Min(MaxBytes, Size - Position);
    SetLength(Result, LReadLen);
    ReadBuffer(Result[0], LReadLen);
  end;

  function TStreamPreambleHelper.PeekBytes(const MaxBytes: Integer): TBytes;
  begin
    var LOldPos := Position;  //save current position
    try
      Result := ReadBytes(MaxBytes);
    finally
      Position := LOldPos;  //restore position
    end;
  end;

  function TStreamPreambleHelper.PeekString(const MaxBytes: Integer; Encoding: TEncoding = nil): String;
  begin
    if Encoding = nil then
      Encoding := TEncoding.UTF8;  // Default to UTF-8

    var LBytes := PeekBytes(MaxBytes);  // Use byte peek function
    Result := Encoding.GetString(LBytes);  // Convert to string
  end;

  procedure TStreamPreambleHelper.SkipBOM_UTF8;
  begin
    var LStreamStartPos := Position;
    const UTF8_BOM = TBytes.Create($EF, $BB, $BF);
    if not (ReadBytes(Length(UTF8_BOM)) = UTF8_BOM) then //if not starting with UTF8 BOM...
      Position := LStreamStartPos; //...go back to original position
  end;

{$ENDREGION}

end.
