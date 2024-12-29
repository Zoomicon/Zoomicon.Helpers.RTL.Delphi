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

implementation
  uses
    RTLConsts; //for SFileTooLong

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

end.
