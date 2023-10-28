{*
 *  URUWorks
 *
 *  The contents of this file are used with permission, subject to
 *  the Mozilla Public License Version 2.0 (the "License"); you may
 *  not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.mozilla.org/MPL/2.0.html
 *
 *  Software distributed under the License is distributed on an
 *  "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 *  implied. See the License for the specific language governing
 *  rights and limitations under the License.
 *
 *  Copyright (C) 2023 URUWorks, uruworks@gmail.com.
 *}

unit formAudioToTextModel;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmAudioToTextModel }

  TfrmAudioToTextModel = class(TForm)
    btnClose: TButton;
    btnDownload: TButton;
    cboModel: TComboBox;
    procedure btnCloseClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

  TModelInfo = record
    Name,
    Size,
    URL : String;
  end;

  TModels = array[0..9] of TModelInfo;

var
  frmAudioToTextModel: TfrmAudioToTextModel;

// -----------------------------------------------------------------------------

implementation

uses
  procWorkspace, procConfig, procTypes, formDownload;

const
  Models: TModels =
  (
    (Name: 'base'; Size: '148 MB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin'),
    (Name: 'base.en'; Size: '148 MB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin'),
    (Name: 'tiny'; Size: '78 MB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin'),
    (Name: 'tiny.en'; Size: '78 MB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin'),
    (Name: 'small'; Size: '488 MB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin'),
    (Name: 'small.en'; Size: '488 MB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin'),
    (Name: 'medium'; Size: '1.53 GB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin'),
    (Name: 'medium.en'; Size: '1.53 GB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin'),
    (Name: 'large'; Size: '3.1 GB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin'),
    (Name: 'large-v1'; Size: '3.1 GB'; URL: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v1.bin')
  );

  FasterModels: TModels =
  (
    (Name: 'base'; Size: '148 MB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-base/resolve/main/'),
    (Name: 'base.en'; Size: '148 MB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-base.en/resolve/main/'),
    (Name: 'tiny'; Size: '78 MB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-tiny/resolve/main/'),
    (Name: 'tiny.en'; Size: '78 MB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-tiny.en/resolve/main/'),
    (Name: 'small'; Size: '488 MB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-small/resolve/main/'),
    (Name: 'small.en'; Size: '488 MB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-small.en/resolve/main/'),
    (Name: 'medium'; Size: '1.53 GB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-medium/resolve/main/'),
    (Name: 'medium.en'; Size: '1.53 GB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-medium.en/resolve/main/'),
    (Name: 'large-v1'; Size: '3.1 GB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-large-v1/resolve/main/'),
    (Name: 'large-v2'; Size: '3.1 GB'; URL: 'https://huggingface.co/guillaumekln/faster-whisper-large-v2/resolve/main/')
  );

  FasterModelFiles: array[0..3] of String = ('model.bin', 'config.json', 'vocabulary.txt', 'tokenizer.json');

var
  ModelsToUse: TModels;

{$R *.lfm}

// -----------------------------------------------------------------------------

{ TfrmAudioToTextModel }

// -----------------------------------------------------------------------------

procedure TfrmAudioToTextModel.FormCreate(Sender: TObject);
var
  i: Integer;
  s: String;
begin
  LoadLanguage(Self);

  if Tools.WhisperEngine = TWhisperEngine.WhisperCPP then
    ModelsToUse := Models
  else
    ModelsToUse := FasterModels;

  cboModel.Items.BeginUpdate;
  for i := 0 to Length(ModelsToUse)-1 do
  begin
    s := ModelsToUse[i].Name;

    if ((Tools.WhisperEngine = TWhisperEngine.WhisperCPP) and FileExists(ConcatPaths([WhisperModelsFolder, s+'.bin']))) or
      ((Tools.WhisperEngine = TWhisperEngine.FasterWhisper) and FileExists(ConcatPaths([WhisperModelsFolder, 'faster-whisper-'+s, 'model.bin']))) then
      s := '* ' + s;

    cboModel.Items.Add(Format('%s (%s)', [s, ModelsToUse[i].Size]));
  end;

  if cboModel.Items.Count > 0 then cboModel.ItemIndex := 0;
  cboModel.Items.EndUpdate;
end;

// -----------------------------------------------------------------------------

procedure TfrmAudioToTextModel.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
  frmAudioToTextModel := NIL;
end;

// -----------------------------------------------------------------------------

procedure TfrmAudioToTextModel.FormShow(Sender: TObject);
begin
  CheckColorTheme(Self);
end;

// -----------------------------------------------------------------------------

procedure TfrmAudioToTextModel.btnCloseClick(Sender: TObject);
begin
  Close;
end;

// -----------------------------------------------------------------------------

procedure TfrmAudioToTextModel.btnDownloadClick(Sender: TObject);
var
  s, d: String;
  i: Integer;
begin
  if Tools.WhisperEngine = TWhisperEngine.WhisperCPP then
  begin
    s := ConcatPaths([WhisperModelsFolder, ModelsToUse[cboModel.ItemIndex].Name+'.bin']);
    ShowDownloadDialog(ModelsToUse[cboModel.ItemIndex].URL, s);
  end
  else
  begin
    d := ConcatPaths([WhisperModelsFolder, 'faster-whisper-' + ModelsToUse[cboModel.ItemIndex].Name]);
    CreateDir(d);
    for i := 0 to Length(FasterModelFiles)-1 do
    begin
      s := ConcatPaths([d, FasterModelFiles[i]]);
      ShowDownloadDialog(ModelsToUse[cboModel.ItemIndex].URL + FasterModelFiles[i], s);
    end;
  end;
end;

// -----------------------------------------------------------------------------

end.

