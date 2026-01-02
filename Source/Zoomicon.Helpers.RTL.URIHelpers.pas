unit Zoomicon.Helpers.RTL.URIHelpers;

interface
  uses
    System.Net.URLClient; //for TURI

  type

    TURIHelper = record helper for TURI
      function Ext: String;
    end;

    function IsURI(const Value: String): Boolean;

    function ExtractUrlExt(const Url: TURI): String; overload;
    function ExtractUrlExt(const Url: String): String; overload;

implementation
  uses
    SysUtils; //for String.IsEmpty

  {$REGION 'TURIHelper'}

  function TURIHelper.Ext: String;
  begin
    result := ExtractUrlExt(Self);
  end;

  {$ENDREGION}

  {$REGION 'Helpers'}

  function IsURI(const Value: String): Boolean;
  begin
    Result := Value.StartsWith('http://', true) or Value.StartsWith('https://', true); //TODO: a bit naive implementation
  end;

  function ExtractUrlExt(const Url: TURI): String;
  begin
    // Path contains everything after the host, e.g. "/a/b/file.png"
    var Path := Url.Path;

    if Path.IsEmpty then
      Exit;

    // Extract filename from path
    var LastSlash := Path.LastIndexOf('/');
    var FileName :=
      if (LastSlash >= 0) then
        Path.Substring(LastSlash + 1)
      else
        Path;

    if FileName.IsEmpty then
      Exit;

    // Extract extension INCLUDING the dot (".png")
    Result := ExtractFileExt(FileName);
  end;

  function ExtractUrlExt(const Url: String): String;
  begin
    result := ExtractUrlExt(TURI.Create(Url)); //TURI.Create(Url).Ext
  end;

  {$ENDREGION}

end.
