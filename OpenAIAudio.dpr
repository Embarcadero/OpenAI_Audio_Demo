program OpenAIAudio;
uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {Form1},
  ChatGPTHelper in 'ChatGPTHelper.pas';

{$R *.res}
begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
