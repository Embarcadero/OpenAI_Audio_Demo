unit ChatGPTHelper;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls,
  FMX.Controls.Presentation, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, JSON, System.Threading,
  System.Net.Mime, System.Generics.Collections,
  REST.Client, REST.Types, REST.Authenticator.Basic;

type
  IChatGPTHelper = interface
    function SendTextToChatGPT(const Text: string): string;
    function GetJSONWithImage(const Prompt: string; ResponseFormat: Integer): string;
    function GetImageURLFromJSON(const JsonResponse: string): string;
    function GetImageAsStream(const ImageURL: string): TMemoryStream;
    function GetImageBASE64FromJSON(const JsonResponse: string): string;
    function GetGeneratedSpeechAsStream(const Input: string; const Voice: string): TMemoryStream;
    function GetGeneratedTextFromSpeech(const InputAudioFilePath: string): string;
  end;

  TChatGPT = class(TInterfacedObject, IChatGPTHelper)
  private
    FNetHttpClient: TNetHTTPClient;
    FHttpBasicAuthenticator: THTTPBasicAuthenticator;
    FRestRequest: TRESTRequest;
    FRestClient: TRESTClient;
    FOpenAIApiKey: string;
    FText: string;
    function FormatJSON(const JSON: string): string;
    function SendTextToChatGPT(const Text: string): string;
    function GetJSONWithImage(const Prompt: string; ResponseFormat: Integer): string;
    function GetImageURLFromJSON(const JsonResponse: string): string;
    function GetImageAsStream(const ImageURL: string): TMemoryStream;
    function GetImageBASE64FromJSON(const JsonResponse: string): string;
    function GetGeneratedSpeechAsStream(const Input: string; const Voice: string): TMemoryStream;
    function GetGeneratedTextFromSpeech(const InputAudioFilePath: string): string;
  public
    constructor Create(const NetHttpClient: TNetHTTPClient;
      const OpenAIApiKey: string); overload;
    constructor Create(const HttpBasicAuthentificator: THTTPBasicAuthenticator;
      const RESTClient: TRESTClient; const RESTRequest: TRESTRequest;
      const OpenAIApiKey: string); overload;
    class function MessageContentFromChatGPT(const JsonAnswer: string): string;
  end;

implementation

{ TFirebaseAuth }

constructor TChatGPT.Create(const NetHttpClient: TNetHTTPClient;
  const OpenAIApiKey: string);
begin
  FNetHttpClient := NetHttpClient;
  if OpenAIApiKey <> '' then
    FOpenAIApiKey := OpenAIApiKey
  else
  begin
    ShowMessage('OpenAI API key is empty!');
    Exit;
  end;
end;

constructor TChatGPT.Create(const HttpBasicAuthentificator: THTTPBasicAuthenticator;
  const RESTClient: TRESTClient; const RESTRequest: TRESTRequest;
  const OpenAIApiKey: string);
begin
  FHttpBasicAuthenticator := HttpBasicAuthentificator;
  FRestRequest :=  RESTRequest;
  FRestClient := RESTClient;
  if OpenAIApiKey <> '' then
    FOpenAIApiKey := OpenAIApiKey
  else
  begin
    ShowMessage('OpenAI API key is empty!');
    Exit;
  end;
end;

function TChatGPT.FormatJSON(const JSON: string): string;
var
  JsonObject: TJsonObject;
begin
  JsonObject := TJsonObject.ParseJSONValue(JSON) as TJsonObject;
  try
    if Assigned(JsonObject) then
      Result := JsonObject.Format()
    else
      Result := JSON;
  finally
    JsonObject.Free;
  end;
end;

function TChatGPT.GetGeneratedSpeechAsStream(const Input, Voice: string): TMemoryStream;
var
  JObj: TJsonObject;
  Request: string;
  MyHeaders: TArray<TNameValuePair>;
  StringStream: TStringStream;
begin
  JObj := nil;
  StringStream := nil;
  try
    Result := TMemoryStream.Create;
    SetLength(MyHeaders, 2);
    MyHeaders[0] := TNameValuePair.Create('Authorization', FOpenAIApiKey);
    MyHeaders[1] := TNameValuePair.Create('Content-Type', 'application/json');
    JObj := TJSONObject.Create;
    JObj.AddPair('model', 'tts-1');
    JObj.AddPair('input', Input);
    JObj.AddPair('voice', Voice);
    Request := JObj.ToString;
    StringStream := TStringStream.Create(Request, TEncoding.UTF8);
    FNetHttpClient.Post('https://api.openai.com/v1/audio/speech',
      StringStream, Result, MyHeaders);
  finally
    JObj.Free;
    StringStream.Free;
  end;
end;

function TChatGPT.GetGeneratedTextFromSpeech(const InputAudioFilePath: string): string;
begin
  FRESTClient.Authenticator := FHTTPBasicAuthenticator;
  FRESTRequest.Method := TRESTRequestMethod.rmPOST;
  FHTTPBasicAuthenticator.Password := FOpenAIApiKey;
  FRESTClient.BaseURL := 'https://api.openai.com/v1/audio/transcriptions';
  FRESTRequest.AddParameter('response_format', 'text',
    TRESTRequestParameterKind.pkREQUESTBODY);
  FRESTRequest.AddParameter('model', 'whisper-1',
    TRESTRequestParameterKind.pkREQUESTBODY);
  FRESTRequest.AddFile('file', InputAudioFilePath,
    TRESTContentType.ctAPPLICATION_OCTET_STREAM);
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Execute;
  Result := FRESTRequest.Response.Content;
end;

function TChatGPT.GetImageAsStream(const ImageURL: string): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  FNetHTTPClient.Get(ImageURL, Result);
end;

function TChatGPT.GetImageURLFromJSON(const JsonResponse: string): string;
var
  Json: TJsonObject;
  DataArr: TJsonArray;
begin
  Json := TJsonObject.ParseJSONValue(JsonResponse) as TJsonObject;
  try
    if Assigned(Json) then
    begin
      DataArr := TJsonArray(Json.Get('data').JsonValue);
      Result := TJSONPair(TJSONObject(DataArr.Items[0]).Get('url')).JsonValue.Value;
    end
    else
      Result := '';
  finally
    Json.Free;
  end;
end;

function TChatGPT.GetImageBASE64FromJSON(const JsonResponse: string): string;
var
  Json: TJsonObject;
  DataArr: TJsonArray;
begin
  Json := TJsonObject.ParseJSONValue(JsonResponse) as TJsonObject;
  try
    if Assigned(Json) then
    begin
      DataArr := TJsonArray(Json.Get('data').JsonValue);
      Result := TJSONPair(TJSONObject(DataArr.Items[0]).Get('b64_json')).JsonValue.Value;
    end
    else
      Result := '';
  finally
    Json.Free;
  end;
end;


function TChatGPT.GetJSONWithImage(const Prompt: string; ResponseFormat: Integer): string;
var
  JObj: TJsonObject;
  Request: string;
  ResponseContent, StringStream: TStringStream;
  MyHeaders: TArray<TNameValuePair>;
begin
  JObj := nil;
  ResponseContent := nil;
  StringStream := nil;
  try
    SetLength(MyHeaders, 2);
    MyHeaders[0] := TNameValuePair.Create('Authorization', FOpenAIApiKey);
    MyHeaders[1] := TNameValuePair.Create('Content-Type', 'application/json');
    JObj := TJSONObject.Create;
    with JObj do
    begin
      Owned := False;
      AddPair('model', 'dall-e-2');
      if ResponseFormat = 1 then
        AddPair('response_format','b64_json')
      else
        AddPair('response_format','url');
      AddPair('prompt', Prompt);
      AddPair('n', TJSONNumber.Create(1));
      AddPair('size', '1024x1024');
    end;
    Request := Jobj.ToString;
    StringStream := TStringStream.Create(Request, TEncoding.UTF8);
    ResponseContent := TStringStream.Create;
    FNetHttpClient.Post('https://api.openai.com/v1/images/generations',
      StringStream, ResponseContent, MyHeaders);
    Result := ResponseContent.DataString;
  finally
    JObj.Free;
    ResponseContent.Free;
    StringStream.Free;
  end;
end;

class function TChatGPT.MessageContentFromChatGPT(const JsonAnswer: string): string;
var
  Mes: TJsonArray;
  JsonResp: TJsonObject;
begin
  JsonResp := nil;
  try
    JsonResp := TJsonObject.ParseJSONValue(JsonAnswer) as TJsonObject;
    if Assigned(JsonResp) then
    begin
      Mes := TJsonArray(JsonResp.Get('choices').JsonValue);
      Result := TJsonObject(TJsonObject(Mes.Get(0)).Get('message').JsonValue).
      GetValue('content').Value;
    end
    else
      Result := '';
  finally
    JsonResp.Free;
  end;
end;

function TChatGPT.SendTextToChatGPT(const Text: string): string;
var
  JArr: TJsonArray;
  JObj, JObjOut: TJsonObject;
  Request: string;
  ResponseContent, StringStream: TStringStream;
  Headers: TArray<TNameValuePair>;
  I: Integer;
begin
  JArr := nil;
  JObj := nil;
  JObjOut := nil;
  ResponseContent := nil;
  StringStream := nil;
  try
    SetLength(Headers, 2);
    Headers[0] := TNameValuePair.Create('Authorization', FOpenAIApiKey);
    Headers[1] := TNameValuePair.Create('Content-Type', 'application/json');
    JObj := TJsonObject.Create;
    JObj.Owned := False;
    JObj.AddPair('role', 'user');
    JArr := TJsonArray.Create;
    JArr.AddElement(JObj);
    Self.FText := Text;
    JObj.AddPair('content', FText);
    JObjOut := TJsonObject.Create;
    JObjOut.AddPair('model', 'gpt-3.5-turbo');
    JObjOut.AddPair('messages', Trim(JArr.ToString));
    JObjOut.AddPair('temperature', TJSONNumber.Create(0.7));
    Request := JObjOut.ToString.Replace('\', '');
    for I := 0 to Length(Request) - 1 do
    begin
      if ((Request[I] = '"') and (Request[I + 1] = '[')) or
        ((Request[I] = '"') and (Request[I - 1] = ']')) then
      begin
        Request[I] := ' ';
      end;
    end;
    ResponseContent := TStringStream.Create;
    StringStream := TStringStream.Create(Request, TEncoding.UTF8);
    FNetHttpClient.Post('https://api.openai.com/v1/chat/completions',
      StringStream, ResponseContent, Headers);
    Result := FormatJSON(ResponseContent.DataString);
  finally
    StringStream.Free;
    ResponseContent.Free;
    JObjOut.Free;
    JArr.Free;
    JObj.Free;
  end;
end;

end.
