{*******************************************************}
{                                                       }
{         基于HCView的电子病历程序  作者：荆通          }
{                                                       }
{ 此代码仅做学习交流使用，不可用于商业目的，由此引发的  }
{ 后果请使用者承担，加入QQ群 649023932 来获取更多的技术 }
{ 交流。                                                }
{                                                       }
{*******************************************************}

unit frm_PatientRecord;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, frm_RecordEdit, Vcl.ExtCtrls,
  Vcl.ComCtrls, emr_Common, Vcl.Menus, HCCustomData, System.ImageList,
  Vcl.ImgList, EmrElementItem, EmrGroupItem, HCDrawItem, Vcl.StdCtrls, Xml.XMLDoc,
  Xml.XMLIntf, FireDAC.Comp.Client;

type
  TTraverse = class(TObject)
  public
    const
      Normal = 0;
      ReplaceElement = 1;  // 模板加载后替换宏元素
      WriteTraceInfo = 2;  // 遍历内容，为新痕迹增加痕迹信息
      ShowTrace = 3;  // 显示痕迹内容
  end;

type
  TXmlStruct = class(TObject)
  private
    FXmlDoc: IXMLDocument;
    FDeGroupNodes: TList;
    FDETable: TFDMemTable;
  public
    constructor Create;
    destructor Destroy; override;
    procedure TraverseItem(const AData: THCCustomData;
      const AItemNo, ATag: Integer; var AStop: Boolean);
    property XmlDoc: IXMLDocument read FXmlDoc;
  end;

  TfrmPatientRecord = class(TForm)
    spl1: TSplitter;
    pgRecordEdit: TPageControl;
    tsHelp: TTabSheet;
    tvRecord: TTreeView;
    pmRecord: TPopupMenu;
    mniNew: TMenuItem;
    pmpg: TPopupMenu;
    mniCloseRecordEdit: TMenuItem;
    mniEdit: TMenuItem;
    mniDelete: TMenuItem;
    mniView: TMenuItem;
    mniPreview: TMenuItem;
    il: TImageList;
    mniN1: TMenuItem;
    mniN2: TMenuItem;
    pnl1: TPanel;
    btn1: TButton;
    mniXML: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mniNewClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tvRecordExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure tvRecordDblClick(Sender: TObject);
    procedure pgRecordEditMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure mniCloseRecordEditClick(Sender: TObject);
    procedure mniEditClick(Sender: TObject);
    procedure mniViewClick(Sender: TObject);
    procedure mniDeleteClick(Sender: TObject);
    procedure mniPreviewClick(Sender: TObject);
    procedure pmRecordPopup(Sender: TObject);
    procedure mniN2Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure mniXMLClick(Sender: TObject);
  private
    { Private declarations }
    FPatientInfo: TPatientInfo;
    FOnCloseForm: TNotifyEvent;
    procedure ReplaceTemplateElement(const ARecordEdit: TfrmRecordEdit);
    procedure DoTraverseItem(const AData: THCCustomData;
      const AItemNo, ATag: Integer; var AStop: Boolean);
    procedure ClearRecordNode;
    procedure RefreshRecordNode;
    procedure DoSaveRecordContent(Sender: TObject);
    procedure DoRecordChangedSwitch(Sender: TObject);
    procedure DoRecordReadOnlySwitch(Sender: TObject);

    function GetRecordEditPageIndex(const ARecordID: Integer): Integer;
    function GetPageRecordEdit(const APageIndex: Integer): TfrmRecordEdit;
    procedure CloseRecordEditPage(const APageIndex: Integer;
      const ASaveChange: Boolean = True);

    function GetPatientNode: TTreeNode;

    procedure GetPatientRecordListUI;
    procedure EditPatientDeSet(const ADeSetID, ARecordID: Integer);

    procedure LoadPatientDeSetContent(const ADeSetID: Integer);
    procedure LoadPatientRecordContent(const ARecordID: Integer);
    procedure DeletePatientRecord(const ARecordID: Integer);

    procedure GetNodeRecordInfo(const ANode: TTreeNode; var ADeSetPID, ARecordID: Integer);

    /// <summary> 打开节点对应的病程(创建编辑器并加载，不做其他处理) </summary>
    procedure OpenPatientDeSet(const ADeSetID, ARecordID: Integer);

    /// <summary> 返回指定病历对应的节点 </summary>
    function FindRecordNode(const ARecordID: Integer): TTreeNode;

    /// <summary> 审核文档内容 </summary>
    procedure CheckRecordContent(const ARecordEdit: TfrmRecordEdit);
  public
    { Public declarations }
    UserInfo: TUserInfo;
    /// <summary> 保存文档内容结构到XML文件 </summary>
    procedure SaveStructureToXml(const ARecordEdit: TfrmRecordEdit;
      const AFileName: string);
    property OnCloseForm: TNotifyEvent read FOnCloseForm write FOnCloseForm;
    property PatientInfo: TPatientInfo read FPatientInfo;
  end;

implementation

uses
  DateUtils, HCCommon, HCStyle, HCParaStyle, EmrView, frm_DM,
  emr_BLLServerProxy, emr_BLLConst, frm_TemplateList,
  Data.DB, HCSectionData;

{$R *.dfm}

var
  FTraverseDT: TDateTime;

procedure TfrmPatientRecord.btn1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmPatientRecord.CheckRecordContent(
  const ARecordEdit: TfrmRecordEdit);
var
  vItemTraverse: TItemTraverse;
begin
  FTraverseDT := TBLLServer.GetServerDateTime;
  vItemTraverse := TItemTraverse.Create;
  try
    vItemTraverse.Tag := TTraverse.WriteTraceInfo;
    vItemTraverse.Process := DoTraverseItem;
    ARecordEdit.EmrView.TraverseItem(vItemTraverse);
  finally
    vItemTraverse.Free;
  end;
  ARecordEdit.EmrView.FormatData;
end;

procedure TfrmPatientRecord.ClearRecordNode;
var
  i: Integer;
  vNode: TTreeNode;
begin
  for i := 0 to tvRecord.Items.Count - 1 do
  begin
    //ClearTemplateGroupNode(tvTemplate.Items[i]);
    vNode := tvRecord.Items[i];
    if vNode <> nil then
    begin
      if TreeNodeIsRecordDeSet(vNode) then
        TRecordDeSetInfo(vNode.Data).Free
      else
        TRecordInfo(vNode.Data).Free;
    end;
  end;

  tvRecord.Items.Clear;
end;

procedure TfrmPatientRecord.CloseRecordEditPage(const APageIndex: Integer;
  const ASaveChange: Boolean);
var
  i: Integer;
  vPage: TTabSheet;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if APageIndex >= 0 then
  begin
    vPage := pgRecordEdit.Pages[APageIndex];

    for i := 0 to vPage.ControlCount - 1 do
    begin
      if vPage.Controls[i] is TfrmRecordEdit then
      begin
        if ASaveChange and (vPage.Tag > 0) then  // 需要检测变动且是病历
        begin
          vfrmRecordEdit := (vPage.Controls[i] as TfrmRecordEdit);
          if vfrmRecordEdit.EmrView.IsChanged then  // 有变动
          begin
            if MessageDlg('是否保存病历 ' + TRecordInfo(vfrmRecordEdit.ObjectData).RecName + ' ？',
              mtWarning, [mbYes, mbNo], 0) = mrYes
            then
            begin
              DoSaveRecordContent(vfrmRecordEdit);
            end;
          end;
        end;

        vPage.Controls[i].Free;
        Break;
      end;
    end;
    
    vPage.Free;

    if APageIndex > 0 then
      pgRecordEdit.ActivePageIndex := APageIndex - 1;
  end;
end;

procedure TfrmPatientRecord.DeletePatientRecord(const ARecordID: Integer);
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_DELETEINCHRECORD;  // 删除指定的住院病历
      ABLLServerReady.ExecParam.I['RID'] := ARecordID;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
        raise Exception.Create(ABLLServer.MethodError);
    end);
end;

procedure TfrmPatientRecord.DoRecordChangedSwitch(Sender: TObject);
var
  vText: string;
begin
  if (Sender is TfrmRecordEdit) then
  begin
    if (Sender as TfrmRecordEdit).Parent is TTabSheet then
    begin
      if (Sender as TfrmRecordEdit).EmrView.IsChanged then
        vText := TRecordInfo((Sender as TfrmRecordEdit).ObjectData).RecName + '*'
      else
        vText := TRecordInfo((Sender as TfrmRecordEdit).ObjectData).RecName;

      ((Sender as TfrmRecordEdit).Parent as TTabSheet).Caption := vText;
    end;
  end;
end;

procedure TfrmPatientRecord.DoRecordReadOnlySwitch(Sender: TObject);
begin
  if (Sender is TfrmRecordEdit) then
  begin
    if (Sender as TfrmRecordEdit).Parent is TTabSheet then
    begin
      if (Sender as TfrmRecordEdit).EmrView.ActiveSection.PageData.ReadOnly then
        ((Sender as TfrmRecordEdit).Parent as TTabSheet).ImageIndex := 1
      else
        ((Sender as TfrmRecordEdit).Parent as TTabSheet).ImageIndex := 0;
    end;
  end;
end;

procedure TfrmPatientRecord.DoSaveRecordContent(Sender: TObject);
var
  vSM: TMemoryStream;
  vRecordInfo: TRecordInfo;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  vSM := TMemoryStream.Create;
  try
    vfrmRecordEdit := Sender as TfrmRecordEdit;
    vRecordInfo := TRecordInfo(vfrmRecordEdit.ObjectData);

    CheckRecordContent(vfrmRecordEdit);  // 检查文档质控、痕迹等问题
    vfrmRecordEdit.EmrView.SaveToStream(vSM);

    if vRecordInfo.ID > 0 then  // 编辑后保存
    begin
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_SAVERECORDCONTENT;  // 保存指定的住院病历
          ABLLServerReady.ExecParam.I['rid'] := vRecordInfo.ID;
          ABLLServerReady.ExecParam.ForcePathObject('content').LoadBinaryFromStream(vSM);
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if ABLLServer.MethodRunOk then  // 服务端方法返回执行成功
            ShowMessage('保存成功！')
          else
            ShowMessage(ABLLServer.MethodError);
        end);
    end
    else  // 保存新建的病历
    begin
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_NEWINCHRECORD;  // 保存新建病历
          ABLLServerReady.ExecParam.I['PatID'] := FPatientInfo.PatID;
          ABLLServerReady.ExecParam.I['VisitID'] := FPatientInfo.VisitID;
          ABLLServerReady.ExecParam.I['desid'] := vRecordInfo.DesID;
          ABLLServerReady.ExecParam.S['Name'] := vRecordInfo.RecName;
          ABLLServerReady.ExecParam.S['CreateUserID'] := UserInfo.ID;
          ABLLServerReady.ExecParam.ForcePathObject('Content').LoadBinaryFromStream(vSM);
          //
          ABLLServerReady.AddBackField('RecordID');
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if ABLLServer.MethodRunOk then  // 服务端方法返回执行成功
          begin
            vRecordInfo.ID := ABLLServer.BackField('RecordID').AsInteger;
            ShowMessage('保存病历 ' + vRecordInfo.RecName + ' 成功！');
            GetPatientRecordListUI;
            tvRecord.Selected := FindRecordNode(vRecordInfo.ID);
          end
          else
            ShowMessage(ABLLServer.MethodError);
        end);
    end;
  finally
    FreeAndNil(vSM);
  end;
end;

procedure TfrmPatientRecord.DoTraverseItem(const AData: THCCustomData;
  const AItemNo, ATag: Integer; var AStop: Boolean);
var
  vDeItem: TDeItem;

  {$REGION 'SetElementText 替换元素内容'}
  procedure SetElementText;
  var
    vDeIndex: string;
  begin
    vDeIndex := vDeItem[TDeProp.Index];
    if vDeIndex <> '' then  // 是数据元
    begin
      dm.OpenSql('SELECT MacroType, MacroField FROM Comm_Dic_DataElementMacro WHERE DeID = ' + vDeIndex);
      if dm.qryTemp.RecordCount = 1 then  // 有此数据元的替换信息
      begin
        case dm.qryTemp.FieldByName('MacroType').AsInteger of
          1:  // 患者信息
            vDeItem.Text := FPatientInfo.FieldByName(dm.qryTemp.FieldByName('MacroField').AsString).AsString;

//          2:  // 用户信息
//          3:  // 病历信息
//          4:  // 环境信息(如当前时间等)
        end;
      end;
    end;
  end;
  {$ENDREGION}

begin
  if (not (AData.Items[AItemNo] is TDeItem))
    //or (not (AData.Items[AItemNo] is TDeGroup))
  then
    Exit;  // 只对元素、数据组生效

  vDeItem := AData.Items[AItemNo] as TDeItem;

  case ATag of
    TTraverse.ReplaceElement:  // 元素内容赋值
      if AData.Items[AItemNo].StyleNo > THCStyle.Null then  // 是文本内容
        SetElementText;

    TTraverse.WriteTraceInfo:  // 遍历元素内容
      begin
        case vDeItem.StyleEx of
          cseNone: vDeItem[TDeProp.Trace] := '';

          cseDel:
            begin
              if vDeItem[TDeProp.Trace] = '' then  // 新痕迹
                vDeItem[TDeProp.Trace] := UserInfo.NameEx + '(' + UserInfo.ID + ') 删除 ' + FormatDateTime('YYYY-MM-DD HH:mm:SS', FTraverseDT);
            end;

          cseAdd:
            begin
              if vDeItem[TDeProp.Trace] = '' then  // 新痕迹
                vDeItem[TDeProp.Trace] := UserInfo.NameEx + '(' + UserInfo.ID + ') 添加 ' + FormatDateTime('YYYY-MM-DD HH:mm:SS', FTraverseDT);
            end;
        end;
      end;

    TTraverse.ShowTrace: // 痕迹显示隐藏
      begin
        if AData.Items[AItemNo] is TDeItem then
        begin
          if vDeItem.StyleEx = TStyleExtra.cseDel then
            vDeItem.Visible := not vDeItem.Visible;
        end;
      end;
  end;
end;

procedure TfrmPatientRecord.EditPatientDeSet(const ADeSetID, ARecordID: Integer);
//var
//  vEmrRichView: TEmrRichView;
//  i: Integer;
begin
  //OpenPatientDeSet(ADeSetID, ARecordID);
//  OpenPatientRecord(tvRecord.Selected);  // 打开
//
//  if (not TreeNodeIsRecordDeSet(tvRecord.Selected))  // 非病程
//    and (pgRecordEdit.ActivePageIndex >= 0)  // 切换到要编辑的病历
//  then
//  begin
//    vEmrRichView := GetPageRecordEdit(pgRecordEdit.ActivePageIndex).EmrView;
//    for i := 0 to vEmrRichView.Sections.Count - 1 do
//    begin
//      vEmrRichView.Sections[i].Header.ReadOnly := True;
//      vEmrRichView.Sections[i].Footer.ReadOnly := True;
//      vEmrRichView.Sections[i].Data.ReadOnly := False;
//    end;
//  end;
end;

function TfrmPatientRecord.FindRecordNode(const ARecordID: Integer): TTreeNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to tvRecord.Items.Count - 1 do
  begin
    if TreeNodeIsRecord(tvRecord.Items[i]) then
    begin
      if ARecordID = TRecordInfo(tvRecord.Items[i].Data).ID then
      begin
        Result := tvRecord.Items[i];
        Break;
      end;
    end;
  end;
end;

procedure TfrmPatientRecord.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if Assigned(FOnCloseForm) then
    FOnCloseForm(Self);
end;

procedure TfrmPatientRecord.FormCreate(Sender: TObject);
begin
  //SetWindowLong(Handle, GWL_EXSTYLE, (GetWindowLong(handle, GWL_EXSTYLE) or WS_EX_APPWINDOW));
  FPatientInfo := TPatientInfo.Create;
end;

procedure TfrmPatientRecord.FormDestroy(Sender: TObject);
var
  i, j: Integer;
begin
  for i := 0 to pgRecordEdit.PageCount - 1 do
  begin
    for j := 0 to pgRecordEdit.Pages[i].ControlCount - 1 do
    begin
      if pgRecordEdit.Pages[i].Controls[j] is TfrmRecordEdit then
      begin
        pgRecordEdit.Pages[i].Controls[j].Free;
        Break;
      end;
    end;
  end;

  FreeAndNil(FPatientInfo);
end;

procedure TfrmPatientRecord.FormShow(Sender: TObject);
begin
  Caption := FPatientInfo.BedNo + '床，' + FPatientInfo.Name;
  pnl1.Caption := FPatientInfo.BedNo + '床，' + FPatientInfo.Name + '，'
    + FPatientInfo.Sex + '，' + FPatientInfo.Age + '，' + FPatientInfo.PatID.ToString + '，'
    + FPatientInfo.InpNo + '，' + FPatientInfo.VisitID.ToString + '，'
    + FormatDateTime('YYYY-MM-DD HH:mm', FPatientInfo.InDeptDateTime) + '入科，'
    + FPatientInfo.CareLevel.ToString + '级护理';

  GetPatientRecordListUI;
end;

procedure TfrmPatientRecord.GetNodeRecordInfo(const ANode: TTreeNode;
  var ADeSetPID, ARecordID: Integer);
var
  vNode: TTreeNode;
begin
  ADeSetPID := -1;
  ARecordID := -1;

  if TreeNodeIsRecord(ANode) then  // 病历节点
  begin
    ARecordID := TRecordInfo(ANode.Data).ID;

    ADeSetPID := -1;
    vNode := ANode;
    while vNode.Parent <> nil do
    begin
      vNode := vNode.Parent;
      if TreeNodeIsRecordDeSet(vNode) then
      begin
        ADeSetPID := TRecordDeSetInfo(vNode.Data).DesPID;  // 病历所属数据集大类
        Break;
      end;
    end;
  end;
end;

function TfrmPatientRecord.GetPageRecordEdit(const APageIndex: Integer): TfrmRecordEdit;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to pgRecordEdit.Pages[APageIndex].ControlCount - 1 do
  begin
    if pgRecordEdit.Pages[APageIndex].Controls[i] is TfrmRecordEdit then
    begin
      Result := (pgRecordEdit.Pages[APageIndex].Controls[i] as TfrmRecordEdit);
      Break;
    end;
  end;
end;

procedure TfrmPatientRecord.GetPatientRecordListUI;
var
  vPatNode: TTreeNode;
begin
  RefreshRecordNode;  // 清空所有节点，然后添加本次住院信息节点

  vPatNode := GetPatientNode;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETINCHRECORDLIST;  // 获取指定的住院患者病历列表
      ABLLServerReady.ExecParam.I['PatID'] := FPatientInfo.PatID;
      ABLLServerReady.ExecParam.I['VisitID'] := FPatientInfo.VisitID;
      ABLLServerReady.BackDataSet := True;  // 告诉服务端要将查询数据集结果返回
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    var
      vRecordInfo: TRecordInfo;
      vRecordDeSetInfo: TRecordDeSetInfo;
      vDesPID: Integer;
      vNode: TTreeNode;
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      vDesPID := 0;
      vNode := nil;
      if AMemTable <> nil then
      begin
        if AMemTable.RecordCount > 0 then
        begin
          tvRecord.Items.BeginUpdate;
          try
            with AMemTable do
            begin
              First;
              while not Eof do
              begin
                if vDesPID <> FieldByName('desPID').AsInteger then
                begin
                  vDesPID := FieldByName('desPID').AsInteger;
                  vRecordDeSetInfo := TRecordDeSetInfo.Create;
                  vRecordDeSetInfo.DesPID := vDesPID;

                  vNode := tvRecord.Items.AddChildObject(vPatNode, GetDeSet(vDesPID).GroupName, vRecordDeSetInfo);
                  vNode.HasChildren := True;
                end;

                vRecordInfo := TRecordInfo.Create;
                vRecordInfo.ID := FieldByName('ID').AsInteger;
                vRecordInfo.DesID := FieldByName('desID').AsInteger;
                vRecordInfo.RecName := FieldByName('Name').AsString;

                tvRecord.Items.AddChildObject(vNode, vRecordInfo.RecName, vRecordInfo);

                Next;
              end;
            end;
          finally
            tvRecord.Items.EndUpdate;
          end;
        end;
      end;
    end);
end;

function TfrmPatientRecord.GetRecordEditPageIndex(
  const ARecordID: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to pgRecordEdit.PageCount - 1 do
  begin
    if pgRecordEdit.Pages[i].Tag = ARecordID then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TfrmPatientRecord.LoadPatientDeSetContent(const ADeSetID: Integer);
var
  vfrmRecordEdit: TfrmRecordEdit;
  vSM: TMemoryStream;
  vPage: TTabSheet;
  vIndex: Integer;
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETDESETRECORDCONTENT;  // 获取模板分组子分组和模板
      ABLLServerReady.ExecParam.I['PatID'] := FPatientInfo.PatID;
      ABLLServerReady.ExecParam.I['VisitID'] := FPatientInfo.VisitID;
      ABLLServerReady.ExecParam.I['pid'] := ADeSetID;
      ABLLServerReady.BackDataSet := True;  // 告诉服务端要将查询数据集结果返回
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    //var
    //  vDeGroup: TDeGroup;
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      if AMemTable <> nil then
      begin
        if AMemTable.RecordCount > 0 then
        begin
          vIndex := 0;

          vfrmRecordEdit := TfrmRecordEdit.Create(nil);  // 创建编辑器
          //vfrmRecordEdit.HideToolbar;  // 病程合并显示不支持编辑
          //vfrmRecordEdit.ObjectData := tvRecord.Selected.Data;
          //vfrmRecordEdit.OnChangedSwitch := DoRecordChangedSwitch;
          vfrmRecordEdit.OnReadOnlySwitch := DoRecordReadOnlySwitch;

          vPage := TTabSheet.Create(pgRecordEdit);
          vPage.Caption := '病程记录';
          vPage.Tag := -ADeSetID;
          vPage.PageControl := pgRecordEdit;
          vfrmRecordEdit.Align := alClient;
          vfrmRecordEdit.Parent := vPage;

          vFrmRecordEdit.EmrView.BeginUpdate;
          try
            vSM := TMemoryStream.Create;
            try
              with AMemTable do
              begin
                First;
                while not Eof do
                begin
                  vSM.Clear;
                  //GetRecordContent(FieldByName('id').AsInteger, vSM);  // 单个加载
                  (AMemTable.FieldByName('content') as TBlobField).SaveToStream(vSM);
                  if vSM.Size > 0 then
                  begin
                    if vIndex > 0 then  // 从第二个病程起，在前一个后面换行再插入
                    begin
                      vfrmRecordEdit.EmrView.ActiveSection.ActiveData.SelectLastItemAfterWithCaret;
                      vfrmRecordEdit.EmrView.InsertBreak;
                      vfrmRecordEdit.EmrView.ApplyParaAlignHorz(TParaAlignHorz.pahLeft);
                    end;

                    {// 插入病程数据组
                    vDeGroup := TDeGroup.Create;
                    vDeGroup.Propertys.Add(DeIndex + '=' + FieldByName('id').AsString);
                    vDeGroup.Propertys.Add(DeName + '=' + FieldByName('name').AsString);
                    //vDeGroup.Propertys.Add(DeCode + '=' + sgdDE.Cells[2, sgdDE.Row]);
                    vFrmRecordEdit.EmrView.InsertDeGroup(vDeGroup);

                    // 选择到数据组中间
                    vfrmRecordEdit.EmrView.ActiveSection.ActiveData.SelectItemAfter(
                      vfrmRecordEdit.EmrView.ActiveSection.ActiveData.Items.Count - 2); }

                    vfrmRecordEdit.EmrView.InsertStream(vSM);  // 插入内容
                    //Break;
                  end;

                  Inc(vIndex);
                  Next;
                end;
              end;
            finally
              vSM.Free;
            end;
          finally
            vFrmRecordEdit.EmrView.EndUpdate;
          end;

          vfrmRecordEdit.Show;

          pgRecordEdit.ActivePage := vPage;
        end
        else
          ShowMessage('没有病程病历！');
      end;
    end);
end;

procedure TfrmPatientRecord.LoadPatientRecordContent(const ARecordID: Integer);
var
  vSM: TMemoryStream;
  vfrmRecordEdit: TfrmRecordEdit;
  vPage: TTabSheet;
begin
  vSM := TMemoryStream.Create;
  try
    GetRecordContent(ARecordID, vSM);
    if vSM.Size > 0 then
    begin
      vfrmRecordEdit := TfrmRecordEdit.Create(nil);  // 创建编辑器
      vfrmRecordEdit.ObjectData := tvRecord.Selected.Data;
      vfrmRecordEdit.OnSave := DoSaveRecordContent;
      vfrmRecordEdit.OnChangedSwitch := DoRecordChangedSwitch;
      vfrmRecordEdit.OnReadOnlySwitch := DoRecordReadOnlySwitch;

      vPage := TTabSheet.Create(pgRecordEdit);
      vPage.Caption := tvRecord.Selected.Text;
      vPage.Tag := ARecordID;
      vPage.PageControl := pgRecordEdit;

      vfrmRecordEdit.Align := alClient;
      vfrmRecordEdit.Parent := vPage;  // 赋值父窗口，以便加载后状态(只读等)在父容器显示

      try
        vfrmRecordEdit.EmrView.LoadFromStream(vSM);
        vfrmRecordEdit.EmrView.ReadOnly := True;
        vfrmRecordEdit.Show;
        pgRecordEdit.ActivePage := vPage;
      except
        on E: Exception do
        begin
          vPage.RemoveControl(vfrmRecordEdit);
          FreeAndNil(vfrmRecordEdit);

          pgRecordEdit.RemoveControl(vPage);
          FreeAndNil(vPage);

          ShowMessage('错误：打开病历时出错，事件：TfrmPatientRecord.LoadPatientRecordContent，异常：' + E.Message);
        end;
      end;
    end;
  finally
    vSM.Free;
  end;
end;

procedure TfrmPatientRecord.mniCloseRecordEditClick(Sender: TObject);
begin
  CloseRecordEditPage(pgRecordEdit.ActivePageIndex);
end;

procedure TfrmPatientRecord.mniDeleteClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // 不是病历节点

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then  // 有效的病历
  begin
    if MessageDlg('删除病历 ' + tvRecord.Selected.Text + ' ？',
      mtWarning, [mbYes, mbNo], 0) = mrYes
    then
    begin
      vPageIndex := GetRecordEditPageIndex(vRecordID);
      if vPageIndex >= 0 then  // 打开了
        CloseRecordEditPage(pgRecordEdit.ActivePageIndex, False);

      DeletePatientRecord(vRecordID);

      tvRecord.Items.Delete(tvRecord.Selected);
    end;
  end;
end;

procedure TfrmPatientRecord.mniEditClick(Sender: TObject);
var
  i, vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // 不是病历节点

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(vRecordID);
    if vPageIndex < 0 then  // 没打开
    begin
      LoadPatientRecordContent(vRecordID);  // 加载内容
      vPageIndex := GetRecordEditPageIndex(vRecordID);
    end
    else  // 已经打开则切换到
      pgRecordEdit.ActivePageIndex := vPageIndex;

    // 切换读写部分
    vfrmRecordEdit := GetPageRecordEdit(vPageIndex);

    for i := 0 to vfrmRecordEdit.EmrView.Sections.Count - 1 do
    begin
      vfrmRecordEdit.EmrView.Sections[i].Header.ReadOnly := True;
      vfrmRecordEdit.EmrView.Sections[i].Footer.ReadOnly := True;
      vfrmRecordEdit.EmrView.Sections[i].PageData.ReadOnly := False;
      //vfrmRecordEdit.OnItemMouseClick := DoRecordItemMouseClick;
    end;

    try
      vfrmRecordEdit.EmrView.Trace := GetInchRecordSignature(vRecordID);
      if vfrmRecordEdit.EmrView.Trace then
      begin
        //vfrmRecordEdit.EmrView.ShowAnnotation := True;
        ShowMessage('病历已经签名，后续的修改将留下修改痕迹！');
      end;
    except
      vfrmRecordEdit.EmrView.ReadOnly := True;  // 获取失败则切换为只读
    end;
  end;
end;

procedure TfrmPatientRecord.OpenPatientDeSet(const ADeSetID, ARecordID: Integer);
var
  vPageIndex: Integer;
begin
  if ARecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(-ADeSetID);
    if vPageIndex < 0 then
    begin
      LoadPatientDeSetContent(ADeSetID);
      //vPageIndex := GetRecordEditPageIndex(-ADeSetID);
    end
    else
      pgRecordEdit.ActivePageIndex := vPageIndex;
  end;
end;

function TfrmPatientRecord.GetPatientNode: TTreeNode;
begin
  Result := tvRecord.Items[0];
end;

procedure TfrmPatientRecord.mniN2Click(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // 不是病历节点

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    if SignatureInchRecord(vRecordID, UserInfo.ID) then
      ShowMessage(UserInfo.NameEx + '，签名成功！');

    vPageIndex := GetRecordEditPageIndex(vRecordID);
    if vPageIndex >= 0 then  // 打开了，则切换到留痕迹
    begin
      vfrmRecordEdit := GetPageRecordEdit(vPageIndex);
      vfrmRecordEdit.EmrView.Trace := True;
    end;
  end;
end;

procedure TfrmPatientRecord.mniNewClick(Sender: TObject);
var
  vPage: TTabSheet;
  vfrmRecordEdit: TfrmRecordEdit;
  //vOpenDlg: TOpenDialog;
  vFrmTempList: TfrmTemplateList;
  vTemplateID: Integer;
  vSM: TMemoryStream;
  vRecordInfo: TRecordInfo;
begin
  // 选择模板
  vTemplateID := -1;
  vFrmTempList := TfrmTemplateList.Create(nil);
  try
    vFrmTempList.Parent := Self;
    vFrmTempList.ShowModal;
    if vFrmTempList.ModalResult = mrOk then
    begin
      vTemplateID := vFrmTempList.TemplateID;
      // 病历信息对象
      vRecordInfo := TRecordInfo.Create;
      vRecordInfo.DesID := vFrmTempList.DesID;
      vRecordInfo.RecName := vFrmTempList.RecordName;   
    end
    else
      Exit;
  finally
    FreeAndNil(vFrmTempList);
  end;

  //if vTemplateID < 0 then Exit;  // 没有选择模板

  vSM := TMemoryStream.Create;
  try
    GetTemplateContent(vTemplateID, vSM);  // 取模板内容

    // 创建page页
    vPage := TTabSheet.Create(pgRecordEdit);
    vPage.PageControl := pgRecordEdit;
    vPage.Caption := vRecordInfo.RecName;
    // 创建病历窗体
    vfrmRecordEdit := TfrmRecordEdit.Create(nil);
    vfrmRecordEdit.ObjectData := vRecordInfo;
    vfrmRecordEdit.OnSave := DoSaveRecordContent;
    vfrmRecordEdit.OnChangedSwitch := DoRecordChangedSwitch;
    vfrmRecordEdit.OnReadOnlySwitch := DoRecordReadOnlySwitch;
    vfrmRecordEdit.Align := alClient;
    vfrmRecordEdit.Parent := vPage;

    try
      if vSM.Size > 0 then  // 有内容，创建病历
      begin
        vfrmRecordEdit.EmrView.LoadFromStream(vSM);  // 加载模板
        ReplaceTemplateElement(vfrmRecordEdit);  // 替换元素内容
      end;

      // 显示并激活
      vfrmRecordEdit.Show;
      pgRecordEdit.ActivePage := vPage;
    except
      On E: Exception do
      begin
        vPage.RemoveControl(vfrmRecordEdit);
        FreeAndNil(vfrmRecordEdit);

        pgRecordEdit.RemoveControl(vPage);
        FreeAndNil(vPage);
        FreeAndNil(vRecordInfo);

        ShowMessage('错误：新建病历时出错，事件：TfrmPatientRecord.mniNewClick，异常：' + E.Message);
      end;
    end;
  finally
    vSM.Free;
  end;
end;

procedure TfrmPatientRecord.mniPreviewClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // 不是病历节点

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vDeSetID = TDeSetInfo.Proc then  // 病程记录
  begin
    vPageIndex := GetRecordEditPageIndex(-vDeSetID);
    if vPageIndex < 0 then
    begin
      LoadPatientDeSetContent(vDeSetID);
      vPageIndex := GetRecordEditPageIndex(-vDeSetID);
      // 只读
      //GetPageRecordEdit(vPageIndex).EmrView.ReadOnly := True;
    end
    else
      pgRecordEdit.ActivePageIndex := vPageIndex;
  end
end;

procedure TfrmPatientRecord.mniViewClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // 不是病历节点

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(vRecordID);
    if vPageIndex < 0 then  // 没打开
    begin
      LoadPatientRecordContent(vRecordID);  // 加载内容
      vPageIndex := GetRecordEditPageIndex(vRecordID);
    end
    else  // 已经打开则切换到
      pgRecordEdit.ActivePageIndex := vPageIndex;

    try
      vfrmRecordEdit := GetPageRecordEdit(vPageIndex);
    finally
      vfrmRecordEdit.EmrView.ReadOnly := True;
    end;

    vfrmRecordEdit.EmrView.Trace := GetInchRecordSignature(vRecordID);
    //if vfrmRecordEdit.EmrView.Trace then  // 已经签名留痕模式
    //  vfrmRecordEdit.EmrView.ShowAnnotation := True;
  end;
end;

procedure TfrmPatientRecord.mniXMLClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
  vSaveDlg: TSaveDialog;
  vFileName: string;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // 不是病历节点

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    vSaveDlg := TSaveDialog.Create(nil);
    try
      vSaveDlg.Filter := 'XML|*.xml';
      if vSaveDlg.Execute then
      begin
        if vSaveDlg.FileName <> '' then
        begin
          HintFormShow('正在导出XML结构...', procedure(const AUpdateHint: TUpdateHint)
          begin
            vPageIndex := GetRecordEditPageIndex(vRecordID);
            if vPageIndex < 0 then  // 没打开
            begin
              LoadPatientRecordContent(vRecordID);  // 加载内容
              vPageIndex := GetRecordEditPageIndex(vRecordID);
            end
            else  // 已经打开则切换到
              pgRecordEdit.ActivePageIndex := vPageIndex;

            vfrmRecordEdit := GetPageRecordEdit(vPageIndex);


            vFileName := ExtractFileExt(vSaveDlg.FileName);
            if LowerCase(vFileName) <> '.xml' then
              vFileName := vSaveDlg.FileName + '.xml'
            else
              vFileName := vSaveDlg.FileName;

            SaveStructureToXml(vfrmRecordEdit, vFileName);
          end);
        end;
      end;
    finally
      FreeAndNil(vSaveDlg);
    end;
  end;
end;

procedure TfrmPatientRecord.pgRecordEditMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vTabIndex: Integer;
  vPt: TPoint;
begin
  if (Y < 20) and (Button = TMouseButton.mbRight) then  // 默认的 pgRecordEdit.TabHeight 可通过获取操作系统参数得到更精确的
  begin
    vTabIndex := pgRecordEdit.IndexOfTabAt(X, Y);

    //if pgRecordEdit.Pages[vTabIndex].Name = tsHelp then Exit; // 帮助

    if (vTabIndex >= 0) and (vTabIndex = pgRecordEdit.ActivePageIndex) then
    begin
      vPt := pgRecordEdit.ClientToScreen(Point(X, Y));
      pmpg.Popup(vPt.X, vPt.Y);
    end;
  end;
end;

procedure TfrmPatientRecord.pmRecordPopup(Sender: TObject);
var
  vDeSetID, vRecordID: Integer;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then  // 不是病历节点
  begin
    mniView.Visible := False;
    mniEdit.Visible := False;
    mniDelete.Visible := False;
    mniPreview.Visible := False;  // 病程记录
  end
  else
  begin
    GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

    mniView.Visible := vRecordID > 0;
    mniEdit.Visible := vRecordID > 0;
    mniDelete.Visible := vRecordID > 0;
    mniPreview.Visible := vDeSetID = 13;  // 病程记录
  end;
end;

procedure TfrmPatientRecord.RefreshRecordNode;
var
  vNode: TTreeNode;
begin
  ClearRecordNode;

  // 本次住院节点
  vNode := tvRecord.Items.AddObject(nil, FPatientInfo.BedNo + ' ' + FPatientInfo.Name
    + ' ' + FormatDateTime('YYYY-MM-DD HH:mm', FPatientInfo.InHospDateTime), nil);
  vNode.HasChildren := True;

  // 线程加载历次住院信息
end;

procedure TfrmPatientRecord.ReplaceTemplateElement(const ARecordEdit: TfrmRecordEdit);
var
  vItemTraverse: TItemTraverse;
begin
  vItemTraverse := TItemTraverse.Create;
  try
    vItemTraverse.Tag := TTraverse.ReplaceElement;
    vItemTraverse.Process := DoTraverseItem;
    ARecordEdit.EmrView.TraverseItem(vItemTraverse);
  finally
    vItemTraverse.Free;
  end;
  ARecordEdit.EmrView.FormatData;
  ARecordEdit.EmrView.IsChanged := True;
end;

procedure TfrmPatientRecord.SaveStructureToXml(
  const ARecordEdit: TfrmRecordEdit; const AFileName: string);
var
  vItemTraverse: TItemTraverse;
  vXmlStruct: TXmlStruct;
begin
  vItemTraverse := TItemTraverse.Create;
  try
    vItemTraverse.Tag := TTraverse.Normal;

    vXmlStruct := TXmlStruct.Create;
    try
      vItemTraverse.Process := vXmlStruct.TraverseItem;

      vXmlStruct.XmlDoc.DocumentElement.Attributes['DesID'] := TRecordInfo(ARecordEdit.ObjectData).DesID;
      vXmlStruct.XmlDoc.DocumentElement.Attributes['DocName'] := TRecordInfo(ARecordEdit.ObjectData).RecName;
       
      ARecordEdit.EmrView.TraverseItem(vItemTraverse);
      vXmlStruct.XmlDoc.SaveToFile(AFileName);
    finally
      vXmlStruct.Free;
    end;
  finally
    vItemTraverse.Free;
  end;
end;

procedure TfrmPatientRecord.tvRecordDblClick(Sender: TObject);
begin
  mniViewClick(Sender);
end;

procedure TfrmPatientRecord.tvRecordExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var
  vPatNode: TTreeNode;
begin
  if Node.Parent = nil then  // 本次住院信息根结点
  begin
    if Node.Count = 0 then  // 仅在无病历节点时才获取，屏蔽掉新建保存等由代码选中节点的触发
    begin
      GetPatientRecordListUI;  // 获取患者病历列表

      // 无病历时患者节点展开后去掉+号
      vPatNode := GetPatientNode;
      if vPatNode.Count = 0 then
        vPatNode.HasChildren := False;
    end;
  end;
end;

{ TXmlStruct }

constructor TXmlStruct.Create;
begin
  FDETable := TFDMemTable.Create(nil);
  FDETable.FilterOptions := [foCaseInsensitive{不区分大小写, foNoPartialCompare不支持通配符(*)所表示的部分匹配}];

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETDATAELEMENT;  // 获取数据元列表
      ABLLServerReady.BackDataSet := True;  // 告诉服务端要将查询数据集结果返回
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      if AMemTable <> nil then
        FDETable.CloneCursor(AMemTable);
    end);
  
  FDeGroupNodes := TList.Create;

  FXmlDoc := TXMLDocument.Create(nil);
  FXmlDoc.Active := True;
  FXmlDoc.DocumentElement := FXmlDoc.CreateNode('DocInfo', ntElement, '');
  FXmlDoc.DocumentElement.Attributes['SourceTool'] := 'HCView';
end;

destructor TXmlStruct.Destroy;
begin
  FreeAndNil(FDETable);
  inherited Destroy;
end;

procedure TXmlStruct.TraverseItem(const AData: THCCustomData;
  const AItemNo, ATag: Integer; var AStop: Boolean);
var
  vDeItem: TDeItem;
  vDeGroup: TDeGroup;
  vXmlNode: IXMLNode;
begin
  if (AData is THCHeaderData) or (AData is THCFooterData) then Exit;

  if AData.Items[AItemNo] is TDeGroup then  // 数据组
  begin
    vDeGroup := AData.Items[AItemNo] as TDeGroup;
    if vDeGroup.MarkType = TMarkType.cmtBeg then
    begin
      if FDeGroupNodes.Count > 0 then
        vXmlNode := IXMLNode(FDeGroupNodes[FDeGroupNodes.Count - 1]).AddChild('DeGroup', -1)
      else
        vXmlNode := FXmlDoc.DocumentElement.AddChild('DeGroup', -1);

      FDETable.Filtered := False;
      FDETable.Filter := 'DeID = ' + vDeGroup[TDeProp.Index];
      FDETable.Filtered := True;  
            
      vXmlNode.Attributes['Code'] := vDeGroup[TDeProp.Code];
      vXmlNode.Attributes['Name'] := vDeGroup[TDeProp.Name];
      
      FDeGroupNodes.Add(vXmlNode);
    end
    else
    begin
      if FDeGroupNodes.Count > 0 then
        FDeGroupNodes.Delete(FDeGroupNodes.Count - 1);
    end;
  end
  else
  if AData.Items[AItemNo] is TDeItem then  // 数据元
  begin
    vDeItem := AData.Items[AItemNo] as TDeItem;
    if vDeItem[TDeProp.Index] <> '' then
    begin
      if FDeGroupNodes.Count > 0 then
        vXmlNode := IXMLNode(FDeGroupNodes[FDeGroupNodes.Count - 1]).AddChild('DeItem', -1)
      else
        vXmlNode := FXmlDoc.DocumentElement.AddChild('DeItem', -1);

      FDETable.Filtered := False;
      FDETable.Filter := 'DeID = ' + vDeItem[TDeProp.Index];
      FDETable.Filtered := True;
        
      vXmlNode.Text := vDeItem.Text;
      vXmlNode.Attributes['Code'] := FDETable.FieldByName('DeCode').AsString;
      vXmlNode.Attributes['Name'] := FDETable.FieldByName('DeName').AsString;
    end;
  end;
end;

end.
