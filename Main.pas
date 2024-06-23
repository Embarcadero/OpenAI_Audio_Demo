unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.StdCtrls, FMX.Controls.Presentation, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Rtti,
  FMX.ScrollBox, FMX.Grid, FMX.Memo, FMX.TabControl, FMX.Memo.Types,
  Json, FMX.Objects, System.Threading, System.Net.Mime, System.IOUtils,
  FMX.Media, ChatGPTHelper, Data.Bind.Components, Data.Bind.ObjectScope,
  REST.Client, REST.Types, REST.Authenticator.Basic;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    ShadowEffect4: TShadowEffect;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    Button1: TButton;
    TabItem2: TTabItem;
    Label2: TLabel;
    NetHTTPClient1: TNetHTTPClient;
    Memo2: TMemo;
    Label4: TLabel;
    MediaPlayer1: TMediaPlayer;
    Memo1: TMemo;
    Button4: TButton;
    RESTRequest1: TRESTRequest;
    RESTClient1: TRESTClient;
    HTTPBasicAuthenticator1: THTTPBasicAuthenticator;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
    FOpenAIApiKey: string;
    FAudioFilePath: string;
  public
    { Public declarations }
  end;
var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
var
  GPTHelper: IChatGPTHelper;
  ImageStream: TMemoryStream;
begin
  TTask.Run(
    procedure
    begin
      GPTHelper := TChatGPT.Create(NetHTTPClient1, 'Bearer ' + FOpenAIApiKey);
      ImageStream := GPTHelper.GetGeneratedSpeechAsStream(Memo2.Text, 'onyx');
      try
        TThread.Synchronize(nil,
          procedure
          begin
            if FileExists(FAudioFilePath) then
            begin
              DeleteFile(FAudioFilePath);
              ImageStream.SaveToFile(FAudioFilePath);
            end
            else
              ImageStream.SaveToFile(FAudioFilePath);
            MediaPlayer1.FileName := FAudioFilePath;
            MediaPlayer1.Play;
            ShowMessage('All is done!!!');
          end);
      finally
        ImageStream.Free;
      end;
    end);
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  GPTHelper: IChatGPTHelper;
  Text: string;
begin
  TTask.Run(
    procedure
    begin
      GPTHelper := TChatGPT.Create(HTTPBasicAuthenticator1,
        RESTClient1, RESTRequest1, FOpenAIApiKey);
      Text := GPTHelper.GetGeneratedTextFromSpeech(FAudioFilePath);
      TThread.Synchronize(nil,
        procedure
        begin
          Memo1.Text := Text;
          ShowMessage('All is done!!!');
        end);
    end);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FAudioFilePath := TPath.Combine(TPath.GetDocumentsPath, 'GeneratedVoice.mp3');
  FOpenAIApiKey := '*** ADD YOUR API KEY HERE ****';
end;

end.
