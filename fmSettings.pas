unit fmSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TSettingsForm = class(TForm)
    Memo1: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SettingsForm: TSettingsForm;

implementation

{$R *.dfm}

//uses
//  IniFiles;
//
//
//procedure SaveFormInformation();
//var
//  i : Integer;
//  form : TForm;
//  iniFile : TIniFile;
//begin
//  iniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'FormInfo.ini');
//  try
//    for i := 0 to Screen.FormCount - 1 do
//    begin
//      form := Screen.Forms[i];
//      if form.Visible then
//      begin
//        iniFile.WriteInteger(form.Name, 'Width', form.Width);
//        iniFile.WriteInteger(form.Name, 'Height', form.Height);
//        iniFile.WriteInteger(form.Name, 'Left', form.Left);
//        iniFile.WriteInteger(form.Name, 'Top', form.Top);
//        iniFile.WriteBool(form.Name, 'Visible', form.Visible);
//        iniFile.WriteBool(form.Name, 'IsMaximized', form.WindowState = wsMaximized)
//      end;
//    end;
//  finally
//    iniFile.Free;
//  end;
//end;
//
//procedure RestoreForms();
//var
//  i : Integer;
//  iniFile : TIniFile;
//  form : TForm;
//  FormClass : TFormClass;
//  Sections : TStringList;
//begin
//  iniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'FormInfo.ini');
//  Sections := TStringList.Create;
//
//  try
//    IniFile.ReadSections(Sections);
//    for i := 0 to Sections.Count -1 do
//    begin
//
//      {form := Application.FindComponent(Sections[i]) as TForm;
//      if not Assigned(form) then
//      begin
//        FormClass := TFormClass(GetClass('T' + Sections[i]));
//        Application.CreateForm(FormClass, form);
//        form.Free;
//      end;}
//
//      //Since not all Forms are initialized in the beginning this bit
//      //does it for you. If the Form is nil then create Form
////      if Application.FindComponent(Sections[i]) as TForm = nil then
////      begin
////        //FormClass := TFormClass(FindClass('T' + Sections[i]));
////        FormClass := TFormClass(GetClass('T' + Sections[i]));
////        form := Application.FindComponent(Sections[i]) as TForm;
////        Application.CreateForm(FormClass, form);
////        form.Free;
////      end;
//
//      //this puts the current read form of the ini File in a TForm Object
//      //to then change its properties
//      form := Application.FindComponent(Sections[i]) as TForm;
//      with form do
//      begin
//        form.Top := IniFile.ReadInteger(form.Name, 'Top', Top);
//        form.Left := IniFile.ReadInteger(form.Name, 'Left', Left);
//        form.Height := IniFile.ReadInteger(form.Name, 'Height', Height);
//        form.Width := IniFile.ReadInteger(form.Name, 'Width', Width);
//        if iniFile.ReadBool(form.Name, 'IsMaximized', WindowState = wsMaximized) then
//          form.WindowState := wsMaximized
//        else
//          form.WindowState := wsNormal;
////        form.Position := poDesigned;
////        if not (Sections[i] = 'F_Main') then
////          form.Visible := IniFile.ReadBool(form.Name, 'Visible', Visible);
//      end;
//    end;
//  finally
//    Sections.Free;
////    form.Free;
//    iniFile.Free;
//  end;
//end;

end.