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
    var LFileSize := Size;
    {$IFDEF CPU32BITS}
    if LFileSize > MaxInt then
      raise EInOutError.CreateRes(@SFileTooLong);
    {$ENDIF}
    SetLength(Result, LFileSize);
    ReadBuffer(result, Length(result));
  end;

  function TStreamReadAllHelper.ReadAllText(const DefaultEncoding: TEncoding = nil; const ForceDefaultEncoding: Boolean = false): string;
  var FoundEncoding: TEncoding;
  begin
    if ForceDefaultEncoding then
      FoundEncoding := DefaultEncoding;
    var Buff := ReadAllBytes;
    var BOMLength := TEncoding.GetBufferEncoding(Buff, FoundEncoding, DefaultEncoding);
    result := FoundEncoding.GetString(Buff, BOMLength, Length(Buff) - BOMLength);
  end;

{$ENDREGION}

end.
