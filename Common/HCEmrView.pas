{*******************************************************}
{                                                       }
{         基于HCView的电子病历程序  作者：荆通          }
{                                                       }
{ 此代码仅做学习交流使用，不可用于商业目的，由此引发的  }
{ 后果请使用者承担，加入QQ群 649023932 来获取更多的技术 }
{ 交流。                                                }
{                                                       }
{*******************************************************}

unit HCEmrView;

interface

uses
  Windows, Classes, Controls, Vcl.Graphics, HCView, HCEmrViewIH, HCStyle, HCItem,
  HCTextItem, HCDrawItem, HCCustomData, HCRichData, HCViewData, HCSectionData,
  HCEmrElementItem, HCCommon, HCRectItem, HCEmrGroupItem, HCCustomFloatItem,
  Generics.Collections, Winapi.Messages;

type
  TSyncDeItemEvent = procedure(const Sender: TObject; const AData: THCCustomData; const AItem: THCCustomItem) of object;
  TSyncDeFloatItemEvent = procedure(const Sender: TObject; const AData: THCSectionData; const AItem: THCCustomFloatItem) of object;
  THCCopyPasteStreamEvent = function(const AStream: TStream): Boolean of object;

  THCEmrView = class(THCEmrViewIH)
  private
    FDesignMode,
    FHideTrace,  // 隐藏痕迹
    FTrace: Boolean;  // 是否处于留痕迹状态
    FTraceCount: Integer;  // 当前文档痕迹数量
    FDeDoneColor, FDeUnDoneColor: TColor;
    FPageBlankTip: string;
    FOnCanNotEdit: TNotifyEvent;
    FOnSyncDeItem: TSyncDeItemEvent;
    FOnSyncDeFloatItem: TSyncDeFloatItemEvent;
    // 复制粘贴相关事件
    FOnCopyRequest, FOnPasteRequest: THCCopyPasteEvent;
    FOnCopyAsStream, FOnPasteFromStream: THCCopyPasteStreamEvent;

    procedure SetPageBlankTip(const Value: string);

    procedure DoSyncDeItem(const Sender: TObject; const AData: THCCustomData; const AItem: THCCustomItem);
    procedure DoSyncDeFloatItem(const Sender: TObject; const AData: THCSectionData; const AItem: THCCustomFloatItem);
    procedure DoDeItemPaintBKG(const Sender: TObject; const ACanvas: TCanvas;
      const ADrawRect: TRect; const APaintInfo: TPaintInfo);
    procedure InsertEmrTraceItem(const AText: string);
    function CanNotEdit: Boolean;
  protected
    function DoSectionCreateFloatStyleItem(const AData: THCSectionData;
      const AStyleNo: Integer): THCCustomFloatItem; override;

    procedure DoSectionInsertFloatItem(const Sender: TObject;
      const AData: THCSectionData; const AItem: THCCustomFloatItem); override;

    /// <summary> 当有新Item创建完成后触发的事件 </summary>
    /// <param name="Sender">Item所属的文档节</param>
    procedure DoSectionCreateItem(Sender: TObject); override;

    /// <summary> 当有新Item创建时触发 </summary>
    /// <param name="AData">创建Item的Data</param>
    /// <param name="AStyleNo">要创建的Item样式</param>
    /// <returns>创建好的Item</returns>
    function DoSectionCreateStyleItem(const AData: THCCustomData;
      const AStyleNo: Integer): THCCustomItem; override;

    /// <summary> 当节某Data有Item插入后触发 </summary>
    /// <param name="Sender">在哪个文档节插入</param>
    /// <param name="AData">在哪个Data插入</param>
    /// <param name="AItem">已插入的Item</param>
    procedure DoSectionInsertItem(const Sender: TObject;
      const AData: THCCustomData; const AItem: THCCustomItem); override;

    /// <summary> 当节中某Data有Item删除后触发 </summary>
    /// <param name="Sender">在哪个文档节删除</param>
    /// <param name="AData">在哪个Data删除</param>
    /// <param name="AItem">已删除的Item</param>
    procedure DoSectionRemoveItem(const Sender: TObject;
      const AData: THCCustomData; const AItem: THCCustomItem); override;

    /// <summary> 指定的节当前是否可保存指定的Item </summary>
    function DoSectionSaveItem(const Sender: TObject;
      const AData: THCCustomData; const AItem: THCCustomItem): Boolean; override;

    /// <summary> 指定的节当前是否可编辑 </summary>
    /// <param name="Sender">文档节</param>
    /// <returns>True：可编辑，False：不可编辑</returns>
    function DoSectionCanEdit(const Sender: TObject): Boolean; override;

    /// <summary> 指定的节当前是否可删除指定的Item </summary>
    function DoSectionDeleteItem(const Sender: TObject; const AData: THCCustomData; const AItem: THCCustomItem): Boolean; override;

    /// <summary> 按键按下 </summary>
    /// <param name="Key">按键值</param>
    /// <param name="Shift">Shift状态</param>
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    /// <summary> 按键按压 </summary>
    /// <param name="Key">按键值</param>
    procedure KeyPress(var Key: Char); override;

    /// <summary> 在当前位置插入文本 </summary>
    /// <param name="AText">要插入的字符串(支持带#13#10的回车换行)</param>
    /// <returns>True：插入成功，False：插入失败</returns>
    function DoInsertText(const AText: string): Boolean; override;

    /// <summary> 复制前，便于控制是否允许复制 </summary>
    function DoCopyRequest(const AFormat: Word): Boolean; override;

    /// <summary> 粘贴前，便于控制是否允许粘贴 </summary>
    function DoPasteRequest(const AFormat: Word): Boolean; override;

    /// <summary> 复制前，便于订制特征数据如内容来源 </summary>
    procedure DoCopyAsStream(const AStream: TStream); override;

    /// <summary> 粘贴前，便于确认订制特征数据如内容来源 </summary>
    function DoPasteFromStream(const AStream: TStream): Boolean; override;

    /// <summary> 文档某节的Item绘制完成 </summary>
    /// <param name="AData">当前绘制的Data</param>
    /// <param name="ADrawItemIndex">Item对应的DrawItem序号</param>
    /// <param name="ADrawRect">Item对应的绘制区域</param>
    /// <param name="ADataDrawLeft">Data绘制时的Left</param>
    /// <param name="ADataDrawBottom">Data绘制时的Bottom</param>
    /// <param name="ADataScreenTop">绘制时呈现Data的Top位置</param>
    /// <param name="ADataScreenBottom">绘制时呈现Data的Bottom位置</param>
    /// <param name="ACanvas">画布</param>
    /// <param name="APaintInfo">绘制时的其它信息</param>
    procedure DoSectionDrawItemPaintAfter(const Sender: TObject;
      const AData: THCCustomData; const AItemNo, ADrawItemNo: Integer; const ADrawRect: TRect;
      const ADataDrawLeft, ADataDrawRight, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
      const ACanvas: TCanvas; const APaintInfo: TPaintInfo); override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary> 遍历Item </summary>
    /// <param name="ATraverse">遍历时信息</param>
    procedure TraverseItem(const ATraverse: THCItemTraverse);

    /// <summary> 插入数据组 </summary>
    /// <param name="ADeGroup">数据组信息</param>
    /// <returns>True：成功，False：失败</returns>
    function InsertDeGroup(const ADeGroup: TDeGroup): Boolean;

    /// <summary> 插入数据元 </summary>
    /// <param name="ADeItem">数据元信息</param>
    /// <returns>True：成功，False：失败</returns>
    function InsertDeItem(const ADeItem: TDeItem): Boolean;

    /// <summary> 新建数据元 </summary>
    /// <param name="AText">数据元文本</param>
    /// <returns>新建好的数据元</returns>
    function NewDeItem(const AText: string): TDeItem;

    /// <summary> 直接设置当前数据元的值为扩展内容 </summary>
  	/// <param name="AStream">扩展内容流</param>
    procedure SetActiveItemExtra(const AStream: TStream);

    /// <summary> 获取指定数据组中的文本内容 </summary>
    /// <param name="AData">指定从哪个Data里获取</param>
    /// <param name="ADeGroupStartNo">指定数据组的起始ItemNo</param>
    /// <param name="ADeGroupEndNo">指定数据组的结束ItemNo</param>
    /// <returns>数据组文本内容</returns>
    function GetDataDeGroupText(const AData: THCViewData;
      const ADeGroupStartNo, ADeGroupEndNo: Integer): string;

    /// <summary> 从当前数据组起始位置往前找相同数据组的内容 </summary>
    /// <param name="AData">指定从哪个Data里获取</param>
    /// <param name="ADeGroupStartNo">指定从哪个位置开始往前找</param>
    /// <returns>相同数据组文本形式的内容</returns>
    function GetDataForwardDeGroupText(const AData: THCViewData;
      const ADeGroupStartNo: Integer): string;

    /// <summary> 设置数据组的内容为指定的文本 </summary>
    /// <param name="AData">数据组所在的Data</param>
    /// <param name="ADeGroupNo">数据组的ItemNo</param>
    /// <param name="AText">文本内容</param>
    procedure SetDeGroupText(const AData: THCViewData; const ADeGroupNo: Integer; const AText: string);

    /// <summary> 是否是文档设计模式 </summary>
    property DesignMode: Boolean read FDesignMode write FDesignMode;

    /// <summary> 是否隐藏痕迹 </summary>
    property HideTrace: Boolean read FHideTrace write FHideTrace;

    /// <summary> 是否处于留痕状态 </summary>
    property Trace: Boolean read FTrace write FTrace;

    /// <summary> 文档中有几处痕迹 </summary>
    property TraceCount: Integer read FTraceCount;

    property PageBlankTip: string read FPageBlankTip write SetPageBlankTip;

    /// <summary> 当前文档名称 </summary>
    property FileName;

    /// <summary> 当前文档样式表 </summary>
    property Style;

    /// <summary> 是否对称边距 </summary>
    property SymmetryMargin;

    /// <summary> 当前光标所在页的序号 </summary>
    property ActivePageIndex;

    /// <summary> 当前预览的页序号 </summary>
    property PagePreviewFirst;

    /// <summary> 总页数 </summary>
    property PageCount;

    /// <summary> 当前光标所在节的序号 </summary>
    property ActiveSectionIndex;

    /// <summary> 水平滚动条 </summary>
    property HScrollBar;

    /// <summary> 垂直滚动条 </summary>
    property VScrollBar;

    /// <summary> 缩放值 </summary>
    property Zoom;

    /// <summary> 当前文档所有节 </summary>
    property Sections;

    /// <summary> 是否显示当前行指示符 </summary>
    property ShowLineActiveMark;

    /// <summary> 是否显示行号 </summary>
    property ShowLineNo;

    /// <summary> 是否显示下划线 </summary>
    property ShowUnderLine;

    /// <summary> 当前文档是否有变化 </summary>
    property IsChanged;

    /// <summary> 当编辑只读状态的Data时触发 </summary>
    property OnCanNotEdit: TNotifyEvent read FOnCanNotEdit write FOnCanNotEdit;

    /// <summary> 复制内容前触发 </summary>
    property OnCopyRequest: THCCopyPasteEvent read FOnCopyRequest write FOnCopyRequest;

    /// <summary> 粘贴内容前触发 </summary>
    property OnPasteRequest: THCCopyPasteEvent read FOnPasteRequest write FOnPasteRequest;

    property OnCopyAsStream: THCCopyPasteStreamEvent read FOnCopyAsStream write FOnCopyAsStream;

    property OnPasteFromStream: THCCopyPasteStreamEvent read FOnPasteFromStream write FOnPasteFromStream;

    /// <summary> 数据元需要同步内容时触发 </summary>
    property OnSyncDeItem: TSyncDeItemEvent read FOnSyncDeItem write FOnSyncDeItem;

    property OnSyncDeFloatItem: TSyncDeFloatItemEvent read FOnSyncDeFloatItem write FOnSyncDeFloatItem;
  published
    { Published declarations }

    /// <summary> 节有新的Item创建时触发 </summary>
    property OnSectionCreateItem;

    /// <summary> 节有新的Item插入时触发 </summary>
    property OnSectionItemInsert;

    /// <summary> Item绘制开始前触发 </summary>
    property OnSectionDrawItemPaintBefor;

    /// <summary> Item绘制完成后触发 </summary>
    property OnSectionDrawItemPaintAfter;

    /// <summary> 节页眉绘制时触发 </summary>
    property OnSectionPaintHeader;

    /// <summary> 节页脚绘制时触发 </summary>
    property OnSectionPaintFooter;

    /// <summary> 节页面绘制时触发 </summary>
    property OnSectionPaintPage;

    /// <summary> 节整页绘制前触发 </summary>
    property OnSectionPaintPaperBefor;

    /// <summary> 节整页绘制后触发 </summary>
    property OnSectionPaintPaperAfter;

    /// <summary> 节只读属性有变化时触发 </summary>
    property OnSectionReadOnlySwitch;

    /// <summary> 界面显示模式：页面、Web </summary>
    property ViewModel;

    /// <summary> 是否根据宽度自动计算缩放比例 </summary>
    property AutoZoom;

    /// <summary> 所有Section是否只读 </summary>
    property ReadOnly;

    /// <summary> 鼠标按下时触发 </summary>
    property OnMouseDown;

    /// <summary> 鼠标弹起时触发 </summary>
    property OnMouseUp;

    /// <summary> 光标位置改变时触发 </summary>
    property OnCaretChange;

    /// <summary> 垂直滚动条滚动时触发 </summary>
    property OnVerScroll;

    /// <summary> 文档内容变化时触发 </summary>
    property OnChange;

    /// <summary> 文档Change状态切换时触发 </summary>
    property OnChangedSwitch;

    /// <summary> 窗口重绘开始时触发 </summary>
    property OnPaintViewBefor;

    /// <summary> 窗口重绘结束后触发 </summary>
    property OnPaintViewAfter;

    property PopupMenu;

    property Align;
  end;

/// <summary> 注册HCEmrView控件到控件面板 </summary>
procedure Register;

implementation

uses
  SysUtils, Forms, HCPrinters, HCTextStyle, HCParaStyle, emr_Common, HCEmrViewLite;

procedure Register;
begin
  RegisterComponents('HCEmrViewVCL', [THCEmrView]);
end;

{ TEmrView }

function THCEmrView.CanNotEdit: Boolean;
begin
  Result := (not Self.ActiveSection.ActiveData.CanEdit) or (not (Self.ActiveSectionTopLevelData as THCRichData).CanEdit);
  if Result and Assigned(FOnCanNotEdit) then
    FOnCanNotEdit(Self);
end;

constructor THCEmrView.Create(AOwner: TComponent);
begin
  FHideTrace := False;
  FTrace := False;
  FTraceCount := 0;
  FDesignMode := False;
  HCDefaultTextItemClass := TDeItem;
  HCDefaultDomainItemClass := TDeGroup;
  inherited Create(AOwner);
  Self.Width := 100;
  Self.Height := 100;
  FDeDoneColor := clBtnFace;  // 元素填写后背景色
  FDeUnDoneColor := $0080DDFF;  // 元素未填写时背景色
  FPageBlankTip := '';  // '--------本页以下空白--------'
end;

destructor THCEmrView.Destroy;
begin
  inherited Destroy;
end;

procedure THCEmrView.DoCopyAsStream(const AStream: TStream);
begin
  if Assigned(FOnCopyAsStream) then
    FOnCopyAsStream(AStream)
  else
    inherited DoCopyAsStream(AStream);
end;

function THCEmrView.DoCopyRequest(const AFormat: Word): Boolean;
begin
  if Assigned(FOnCopyRequest) then
    Result := FOnCopyRequest(AFormat)
  else
    Result := inherited DoCopyRequest(AFormat);
end;

procedure THCEmrView.DoDeItemPaintBKG(const Sender: TObject; const ACanvas: TCanvas;
  const ADrawRect: TRect; const APaintInfo: TPaintInfo);
var
  vDeItem: TDeItem;
  vTop: Integer;
  vAlignVert, vTextHeight: Integer;
begin
  if APaintInfo.Print then Exit;

  vDeItem := Sender as TDeItem;
  if not vDeItem.Selected then
  begin
    if vDeItem.IsElement then  // 是数据元
    begin
      if vDeItem.OutOfRang then
      begin
        ACanvas.Brush.Color := clRed;
        ACanvas.FillRect(ADrawRect);
      end
      else
      if vDeItem.MouseIn or vDeItem.Active then  // 鼠标移入和光标在其中
      begin
        if vDeItem[TDeProp.Name] <> vDeItem.Text then  // 已经填写过了
          ACanvas.Brush.Color := FDeDoneColor
        else  // 没填写过
          ACanvas.Brush.Color := FDeUnDoneColor;

        ACanvas.FillRect(ADrawRect);
      end
      else  // 静态
      if FDesignMode then  // 设计模式
      begin
        ACanvas.Brush.Color := clBtnFace;
        ACanvas.FillRect(ADrawRect);
      end;
    end
    else  // 不是数据元
    if FDesignMode or vDeItem.MouseIn or vDeItem.Active then
    begin
      if vDeItem.EditProtect or vDeItem.CopyProtect then
      begin
        ACanvas.Brush.Color := clBtnFace;
        ACanvas.FillRect(ADrawRect);
      end;
    end;
  end;

  if not FHideTrace then  // 显示痕迹
  begin
    case vDeItem.StyleEx of  // 痕迹
      //cseNone: ;
      cseDel:
        begin
          // 垂直居中
          vTextHeight := Style.TextStyles[vDeItem.StyleNo].FontHeight;
          case Style.ParaStyles[vDeItem.ParaNo].AlignVert of
            pavCenter: vAlignVert := DT_CENTER;
            pavTop: vAlignVert := DT_TOP;
          else
            vAlignVert := DT_BOTTOM;
          end;

          case vAlignVert of
            DT_TOP: vTop := ADrawRect.Top;
            DT_CENTER: vTop := ADrawRect.Top + (ADrawRect.Bottom - ADrawRect.Top - vTextHeight) div 2;
          else
            vTop := ADrawRect.Bottom - vTextHeight;
          end;
          // 绘制删除线
          ACanvas.Pen.Style := psSolid;
          ACanvas.Pen.Color := clRed;
          vTop := vTop + (ADrawRect.Bottom - vTop) div 2;
          ACanvas.MoveTo(ADrawRect.Left, vTop - 1);
          ACanvas.LineTo(ADrawRect.Right, vTop - 1);
          ACanvas.MoveTo(ADrawRect.Left, vTop + 2);
          ACanvas.LineTo(ADrawRect.Right, vTop + 2);
        end;

      cseAdd:
        begin
          ACanvas.Pen.Style := psSolid;
          ACanvas.Pen.Color := clBlue;
          ACanvas.MoveTo(ADrawRect.Left, ADrawRect.Bottom);
          ACanvas.LineTo(ADrawRect.Right, ADrawRect.Bottom);
        end;
    end;
  end;
end;

function THCEmrView.DoInsertText(const AText: string): Boolean;
begin
  Result := False;
  if CanNotEdit then Exit;

  if FTrace then
  begin
    InsertEmrTraceItem(AText);
    Result := True;
  end
  else
    Result := inherited DoInsertText(AText);
end;

function THCEmrView.DoPasteFromStream(const AStream: TStream): Boolean;
begin
  if Assigned(FOnPasteFromStream) then
    Result := FOnPasteFromStream(AStream)
  else
    Result := inherited DoPasteFromStream(AStream);
end;

function THCEmrView.DoPasteRequest(const AFormat: Word): Boolean;
begin
  if Assigned(FOnPasteRequest) then
    Result := FOnPasteRequest(AFormat)
  else
    Result := inherited DoPasteRequest(AFormat);
end;

function THCEmrView.DoSectionCanEdit(const Sender: TObject): Boolean;
var
  vViewData: THCViewData;
begin
  vViewData := Sender as THCViewData;
  if (vViewData.ActiveDomain <> nil) and (vViewData.ActiveDomain.BeginNo >= 0) then
    Result := not (vViewData.Items[vViewData.ActiveDomain.BeginNo] as TDeGroup).ReadOnly
  else
    Result := True;
end;

function THCEmrView.DoSectionCreateFloatStyleItem(const AData: THCSectionData;
  const AStyleNo: Integer): THCCustomFloatItem;
begin
  Result := THCEmrViewLite.CreateEmrFloatStyleItem(AData, AStyleNo);
end;

procedure THCEmrView.DoSectionCreateItem(Sender: TObject);
begin
  if (not Style.States.Contain(hosLoading)) and FTrace then
    (Sender as TDeItem).StyleEx := TStyleExtra.cseAdd;

  inherited DoSectionCreateItem(Sender);
end;

function THCEmrView.DoSectionCreateStyleItem(const AData: THCCustomData;
  const AStyleNo: Integer): THCCustomItem;
begin
  Result := THCEmrViewLite.CreateEmrStyleItem(AData, AStyleNo);
end;

function THCEmrView.DoSectionDeleteItem(const Sender: TObject;
  const AData: THCCustomData; const AItem: THCCustomItem): Boolean;
begin
  Result := inherited DoSectionDeleteItem(Sender, AData, AItem);
  if (AItem is TDeGroup) and (not FDesignMode) then  // 设计模式不允许删除数据组
    Result := False;
end;

procedure THCEmrView.DoSectionDrawItemPaintAfter(const Sender: TObject;
  const AData: THCCustomData; const AItemNo, ADrawItemNo: Integer; const ADrawRect: TRect;
  const ADataDrawLeft, ADataDrawRight, ADataDrawBottom, ADataScreenTop, ADataScreenBottom: Integer;
  const ACanvas: TCanvas; const APaintInfo: TPaintInfo);

  procedure DrawBlankTip_(const ALeft, ATop, ARight: Integer);
  begin
    if ATop + 14 <= ADataDrawBottom then
    begin
      ACanvas.Font.Size := 12;
      ACanvas.TextOut(ALeft + ((ARight - ALeft) - ACanvas.TextWidth(FPageBlankTip)) div 2,
        ATop, FPageBlankTip);
    end;
  end;

var
  vItem: THCCustomItem;
  vDeItem: TDeItem;
  vDrawAnnotate: THCDrawAnnotateDynamic;
begin
  if (not FHideTrace) and (FTraceCount > 0) then  // 显示痕迹且有痕迹
  begin
    vItem := AData.Items[AItemNo];
    if vItem.StyleNo > THCStyle.Null then
    begin
      vDeItem := vItem as TDeItem;
      if (vDeItem.StyleEx <> TStyleExtra.cseNone) then  // 添加批注
      begin
        vDrawAnnotate := THCDrawAnnotateDynamic.Create;
        vDrawAnnotate.DrawRect := ADrawRect;
        vDrawAnnotate.Title := vDeItem.GetHint;
        vDrawAnnotate.Text := AData.GetDrawItemText(ADrawItemNo);

        Self.AnnotatePre.AddDrawAnnotate(vDrawAnnotate);
        //Self.VScrollBar.AddAreaPos(AData.DrawItems[ADrawItemNo].Rect.Top, ADrawRect.Height);
      end;
    end;
  end;

  if (FPageBlankTip <> '') and (AData is THCPageData) then
  begin
    if ADrawItemNo < AData.DrawItems.Count - 1 then
    begin
      if AData.Items[AData.DrawItems[ADrawItemNo + 1].ItemNo].PageBreak then
        DrawBlankTip_(ADataDrawLeft, ADrawRect.Top + ADrawRect.Height + AData.GetLineBlankSpace(ADrawItemNo), ADataDrawRight);
    end
    else
      DrawBlankTip_(ADataDrawLeft, ADrawRect.Top + ADrawRect.Height + AData.GetLineBlankSpace(ADrawItemNo), ADataDrawRight);
  end;

  inherited DoSectionDrawItemPaintAfter(Sender, AData, AItemNo, ADrawItemNo, ADrawRect,
    ADataDrawLeft, ADataDrawRight, ADataDrawBottom, ADataScreenTop, ADataScreenBottom, ACanvas, APaintInfo);
end;

procedure THCEmrView.DoSectionInsertFloatItem(const Sender: TObject;
  const AData: THCSectionData; const AItem: THCCustomFloatItem);
begin
  if AItem is TDeFloatBarCodeItem then
    DoSyncDeFloatItem(Sender, AData, AItem);

  inherited DoSectionInsertFloatItem(Sender, AData, AItem);
end;

procedure THCEmrView.DoSectionInsertItem(const Sender: TObject;
  const AData: THCCustomData; const AItem: THCCustomItem);
var
  vDeItem: TDeItem;
begin
  if AItem is TDeItem then
  begin
    vDeItem := AItem as TDeItem;
    vDeItem.OnPaintBKG := DoDeItemPaintBKG;

    //if AData.Style.States.Contain(THCState.hosPasting) then
    //  DoPasteItem();

    if vDeItem.StyleEx <> TStyleExtra.cseNone then
    begin
      Inc(FTraceCount);

      if not Self.AnnotatePre.Visible then
        Self.AnnotatePre.Visible := True;
    end;

    DoSyncDeItem(Sender, AData, AItem);
  end
  else
  if AItem is TDeEdit then
    DoSyncDeItem(Sender, AData, AItem)
  else
  if AItem is TDeCombobox then
    DoSyncDeItem(Sender, AData, AItem);

  inherited DoSectionInsertItem(Sender, AData, AItem);
end;

procedure THCEmrView.DoSectionRemoveItem(const Sender: TObject;
  const AData: THCCustomData; const AItem: THCCustomItem);
var
  vDeItem: TDeItem;
begin
  if AItem is TDeItem then
  begin
    vDeItem := AItem as TDeItem;

    if vDeItem.StyleEx <> TStyleExtra.cseNone then
    begin
      Dec(FTraceCount);

      if (FTraceCount = 0) and Self.AnnotatePre.Visible and (Self.AnnotatePre.Count = 0) then
        Self.AnnotatePre.Visible := False;
    end;
  end;

  inherited DoSectionRemoveItem(Sender, AData, AItem);
end;

function THCEmrView.DoSectionSaveItem(const Sender: TObject;
  const AData: THCCustomData; const AItem: THCCustomItem): Boolean;
begin
  Result := inherited DoSectionSaveItem(Sender, AData, AItem);
  if Style.States.Contain(THCState.hosCopying) then  // 复制保存
  begin
    if (AItem is TDeGroup) and (not FDesignMode) then  // 非设计模式不复制数据组
      Result := False
    else
    if AItem is TDeItem then
      Result := not (AItem as TDeItem).CopyProtect;  // 是否禁止复制
  end;
end;

procedure THCEmrView.DoSyncDeFloatItem(const Sender: TObject;
  const AData: THCSectionData; const AItem: THCCustomFloatItem);
begin
  if Assigned(FOnSyncDeFloatItem) then
    FOnSyncDeFloatItem(Sender, AData, AItem);
end;

procedure THCEmrView.DoSyncDeItem(const Sender: TObject;
  const AData: THCCustomData; const AItem: THCCustomItem);
begin
  if Assigned(FOnSyncDeItem) then
    FOnSyncDeItem(Sender, AData, AItem);
end;

function THCEmrView.GetDataForwardDeGroupText(const AData: THCViewData;
  const ADeGroupStartNo: Integer): string;
var
  i, vBeginNo, vEndNo: Integer;
  vDeGroup: TDeGroup;
  vDeIndex: string;
begin
  Result := '';

  vBeginNo := -1;
  vEndNo := -1;
  vDeIndex := (AData.Items[ADeGroupStartNo] as TDeGroup)[TDeProp.Index];

  for i := 0 to ADeGroupStartNo - 1 do  // 找起始
  begin
    if AData.Items[i] is TDeGroup then
    begin
      vDeGroup := AData.Items[i] as TDeGroup;
      if vDeGroup.MarkType = TMarkType.cmtBeg then  // 是域起始
      begin
        if vDeGroup[TDeProp.Index] = vDeIndex then  // 是目标域起始
        begin
          vBeginNo := i;
          Break;
        end;
      end;
    end;
  end;

  if vBeginNo >= 0 then  // 找结束
  begin
    for i := vBeginNo + 1 to ADeGroupStartNo - 1 do
    begin
      if AData.Items[i] is TDeGroup then
      begin
        vDeGroup := AData.Items[i] as TDeGroup;
        if vDeGroup.MarkType = TMarkType.cmtEnd then  // 是域结束
        begin
          if vDeGroup[TDeProp.Index] = vDeIndex then  // 是目标域结束
          begin
            vEndNo := i;
            Break;
          end;
        end;
      end;
    end;

    if vEndNo > 0 then
      Result := GetDataDeGroupText(AData, vBeginNo, vEndNo);
  end;
end;

function THCEmrView.GetDataDeGroupText(const AData: THCViewData;
  const ADeGroupStartNo, ADeGroupEndNo: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := ADeGroupStartNo + 1 to ADeGroupEndNo - 1 do
    Result := Result + AData.Items[i].Text;
end;

function THCEmrView.InsertDeGroup(const ADeGroup: TDeGroup): Boolean;
begin
  Result := InsertDomain(ADeGroup);
end;

function THCEmrView.InsertDeItem(const ADeItem: TDeItem): Boolean;
begin
  Result := Self.InsertItem(ADeItem);
end;

procedure THCEmrView.InsertEmrTraceItem(const AText: string);
var
  vEmrTraceItem: TDeItem;
begin
  // 插入添加痕迹元素
  vEmrTraceItem := TDeItem.CreateByText(AText);
  if Self.CurStyleNo < THCStyle.Null then
    vEmrTraceItem.StyleNo := 0
  else
    vEmrTraceItem.StyleNo := Self.CurStyleNo;

  vEmrTraceItem.ParaNo := Self.CurParaNo;
  vEmrTraceItem.StyleEx := TStyleExtra.cseAdd;

  Self.InsertItem(vEmrTraceItem);
end;

procedure THCEmrView.KeyDown(var Key: Word; Shift: TShiftState);
var
  vData: THCRichData;
  vText, vCurTrace: string;
  vStyleNo, vParaNo: Integer;
  vDeItem: TDeItem;
  vCurItem: THCCustomItem;
  vCurStyleEx: TStyleExtra;
begin
  if FTrace then  // 留痕
  begin
    if IsKeyDownEdit(Key) then
    begin
      if CanNotEdit then Exit;

      vText := '';
      vCurTrace := '';
      vStyleNo := THCStyle.Null;
      vParaNo := THCStyle.Null;
      vCurStyleEx := TStyleExtra.cseNone;

      vData := Self.ActiveSectionTopLevelData as THCRichData;
      if vData.SelectExists then
      begin
        Self.DisSelect;
        Exit;
      end;

      if vData.SelectInfo.StartItemNo < 0 then Exit;

      if vData.Items[vData.SelectInfo.StartItemNo].StyleNo < THCStyle.Null then
      begin
        if vData.SelectInfo.StartItemOffset = OffsetBefor then  // 在最前面
        begin
          if Key = VK_BACK then  // 回删
          begin
            if vData.SelectInfo.StartItemNo = 0 then
              Exit  // 第一个最前面则不处理
            else  // 不是第一个最前面
            begin
              vData.SelectInfo.StartItemNo := vData.SelectInfo.StartItemNo - 1;
              vData.SelectInfo.StartItemOffset := vData.Items[vData.SelectInfo.StartItemNo].Length;
              Self.KeyDown(Key, Shift);
            end;
          end
          else
          if Key = VK_DELETE then  // 后删
          begin
            vData.SelectInfo.StartItemOffset := OffsetAfter;
            //Self.KeyDown(Key, Shift);
          end
          else
            inherited KeyDown(Key, Shift);
        end
        else
        if vData.SelectInfo.StartItemOffset = OffsetAfter then  // 在最后面
        begin
          if Key = VK_BACK then
          begin
            vData.SelectInfo.StartItemOffset := OffsetBefor;
            Self.KeyDown(Key, Shift);
          end
          else
          if Key = VK_DELETE then
          begin
            if vData.SelectInfo.StartItemNo = vData.Items.Count - 1 then
              Exit
            else
            begin
              vData.SelectInfo.StartItemNo := vData.SelectInfo.StartItemNo + 1;
              vData.SelectInfo.StartItemOffset := 0;
              Self.KeyDown(Key, Shift);
            end;
          end
          else
            inherited KeyDown(Key, Shift);
        end
        else
          inherited KeyDown(Key, Shift);

        Exit;
      end;

      // 取光标处的文本
      with vData do
      begin
        if Key = VK_BACK then  // 回删
        begin
          if (SelectInfo.StartItemNo = 0) and (SelectInfo.StartItemOffset = 0) then  // 第一个最前面则不处理
            Exit
          else  // 不是第一个最前面
          if SelectInfo.StartItemOffset = 0 then  // 最前面，移动到前一个最后面处理
          begin
            if Items[SelectInfo.StartItemNo].Text <> '' then  // 当前行不是空行
            begin
              SelectInfo.StartItemNo := SelectInfo.StartItemNo - 1;
              SelectInfo.StartItemOffset := Items[SelectInfo.StartItemNo].Length;
              Self.KeyDown(Key, Shift);
            end
            else  // 空行不留痕直接默认处理
              inherited KeyDown(Key, Shift);

            Exit;
          end
          else  // 不是第一个Item，也不是在Item最前面
          if Items[SelectInfo.StartItemNo] is TDeItem then  // 文本
          begin
            vDeItem := Items[SelectInfo.StartItemNo] as TDeItem;
            vText := vDeItem.SubString(SelectInfo.StartItemOffset, 1);
            vStyleNo := vDeItem.StyleNo;
            vParaNo := vDeItem.ParaNo;
            vCurStyleEx := vDeItem.StyleEx;
            vCurTrace := vDeItem[TDeProp.Trace];
          end;
        end
        else
        if Key = VK_DELETE then  // 后删
        begin
          if (SelectInfo.StartItemNo = Items.Count - 1)
            and (SelectInfo.StartItemOffset = Items[Items.Count - 1].Length)
          then  // 最后一个最后面则不处理
            Exit
          else  // 不是最后一个最后面
          if SelectInfo.StartItemOffset = Items[SelectInfo.StartItemNo].Length then  // 最后面，移动到后一个最前面处理
          begin
            SelectInfo.StartItemNo := SelectInfo.StartItemNo + 1;
            SelectInfo.StartItemOffset := 0;
            Self.KeyDown(Key, Shift);

            Exit;
          end
          else  // 不是最后一个Item，也不是在Item最后面
          if Items[SelectInfo.StartItemNo] is TDeItem then  // 文本
          begin
            vDeItem := Items[SelectInfo.StartItemNo] as TDeItem;
            vText := vDeItem.SubString(SelectInfo.StartItemOffset + 1, 1);
            vStyleNo := vDeItem.StyleNo;
            vParaNo := vDeItem.ParaNo;
            vCurStyleEx := vDeItem.StyleEx;
            vCurTrace := vDeItem[TDeProp.Trace];
          end;
        end;
      end;

      // 删除掉的内容以痕迹的形式插入
      Self.BeginUpdate;
      try
        inherited KeyDown(Key, Shift);

        if FTrace and (vText <> '') then  // 有删除的内容
        begin
          if (vCurStyleEx = TStyleExtra.cseAdd) and (vCurTrace = '') then Exit;  // 新添加未生效痕迹可以直接删除

          // 创建删除字符对应的Item
          vDeItem := TDeItem.CreateByText(vText);
          vDeItem.StyleNo := vStyleNo;  // Style.CurStyleNo;
          vDeItem.ParaNo := vParaNo;  // Style.CurParaNo;

          if (vCurStyleEx = TStyleExtra.cseDel) and (vCurTrace = '') then  // 原来是删除未生效痕迹
            vDeItem.StyleEx := TStyleExtra.cseNone  // 取消删除痕迹
          else  // 生成删除痕迹
            vDeItem.StyleEx := TStyleExtra.cseDel;

          // 插入删除痕迹Item
          vCurItem := vData.Items[vData.SelectInfo.StartItemNo];
          if vData.SelectInfo.StartItemOffset = 0 then  // 在Item最前面
          begin
            if vDeItem.CanConcatItems(vCurItem) then // 可以合并
            begin
              vCurItem.Text := vDeItem.Text + vCurItem.Text;

              if Key = VK_DELETE then  // 后删
                vData.SelectInfo.StartItemOffset := vData.SelectInfo.StartItemOffset + 1;

              Self.ActiveSection.ReFormatActiveItem;
            end
            else  // 不能合并
            begin
              vDeItem.ParaFirst := vCurItem.ParaFirst;
              vCurItem.ParaFirst := False;
              Self.InsertItem(vDeItem);
              if Key = VK_BACK then  // 回删
                vData.SelectInfo.StartItemOffset := vData.SelectInfo.StartItemOffset - 1;
            end;
          end
          else
          if vData.SelectInfo.StartItemOffset = vCurItem.Length then  // 在Item最后面
          begin
            if vCurItem.CanConcatItems(vDeItem) then // 可以合并
            begin
              vCurItem.Text := vCurItem.Text + vDeItem.Text;

              if Key = VK_DELETE then  // 后删
                vData.SelectInfo.StartItemOffset := vData.SelectInfo.StartItemOffset + 1;

              Self.ActiveSection.ReFormatActiveItem;
            end
            else  // 不可以合并
            begin
              Self.InsertItem(vDeItem);
              if Key = VK_BACK then  // 回删
                vData.SelectInfo.StartItemOffset := vData.SelectInfo.StartItemOffset - 1;
            end;
          end
          else  // 在Item中间
          begin
            Self.InsertItem(vDeItem);
            if Key = VK_BACK then  // 回删
              vData.SelectInfo.StartItemOffset := vData.SelectInfo.StartItemOffset - 1;
          end;
        end;
      finally
        Self.EndUpdate;
      end;
    end
    else
      inherited KeyDown(Key, Shift);
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure THCEmrView.KeyPress(var Key: Char);
var
  vData: THCCustomData;
begin
  if IsKeyPressWant(Key) then
  begin
    if CanNotEdit then Exit;

    if FTrace then
    begin
      vData := Self.ActiveSectionTopLevelData;

      if vData.SelectInfo.StartItemNo < 0 then Exit;

      if vData.SelectExists then
        Self.DisSelect
      else
        InsertEmrTraceItem(Key);

      Exit;
    end;

    inherited KeyPress(Key);
  end;
end;

function THCEmrView.NewDeItem(const AText: string): TDeItem;
begin
  Result := TDeItem.CreateByText(AText);
  if Self.CurStyleNo > THCStyle.Null then
    Result.StyleNo := Self.CurStyleNo
  else
    Result.StyleNo := 0;

  Result.ParaNo := Self.CurParaNo;
end;

procedure THCEmrView.SetActiveItemExtra(const AStream: TStream);
var
  vFileFormat: string;
  vFileVersion: Word;
  vLang: Byte;
  vStyle: THCStyle;
  vTopData: THCRichData;
begin
  _LoadFileFormatAndVersion(AStream, vFileFormat, vFileVersion, vLang);  // 文件格式和版本
  vStyle := THCStyle.Create;
  try
    vStyle.LoadFromStream(AStream, vFileVersion);
    Self.BeginUpdate;
    try
      Self.UndoGroupBegin;
      try
        vTopData := Self.ActiveSectionTopLevelData as THCRichData;
        Self.DeleteActiveDataItems(vTopData.SelectInfo.StartItemNo);
        ActiveSection.InsertStream(AStream, vStyle, vFileVersion);
      finally
        Self.UndoGroupEnd;
      end;
    finally
      Self.EndUpdate;
    end;
  finally
    FreeAndNil(vStyle);
  end;
end;

procedure THCEmrView.SetDeGroupText(const AData: THCViewData;
  const ADeGroupNo: Integer; const AText: string);
var
  vGroupBeg, vGroupEnd: Integer;
begin
  vGroupEnd := AData.GetDomainAnother(ADeGroupNo);

  if vGroupEnd > ADeGroupNo then
    vGroupBeg := ADeGroupNo
  else
  begin
    vGroupBeg := vGroupEnd;
    vGroupEnd := ADeGroupNo;
  end;

  // 选中，使用插入时删除当前数据组中的内容
  AData.SetSelectBound(vGroupBeg, OffsetAfter, vGroupEnd, OffsetBefor);
  AData.InsertText(AText);
end;

procedure THCEmrView.SetPageBlankTip(const Value: string);
begin
  if FPageBlankTip <> Value then
  begin
    FPageBlankTip := Value;
    Self.UpdateView;
  end;
end;

procedure THCEmrView.TraverseItem(const ATraverse: THCItemTraverse);
var
  i: Integer;
begin
  if ATraverse.Areas = [] then Exit;

  for i := 0 to Self.Sections.Count - 1 do
  begin
    if not ATraverse.Stop then
    begin
      with Self.Sections[i] do
      begin
        if saHeader in ATraverse.Areas then
          Header.TraverseItem(ATraverse);

        if (not ATraverse.Stop) and (saPage in ATraverse.Areas) then
          Page.TraverseItem(ATraverse);

        if (not ATraverse.Stop) and (saFooter in ATraverse.Areas) then
          Footer.TraverseItem(ATraverse);
      end;
    end;
  end;
end;

procedure THCEmrView.WndProc(var Message: TMessage);
var
  Form: TCustomForm;
  ShiftState: TShiftState;
begin
  if (Message.Msg = WM_KEYDOWN) or (Message.Msg = WM_KEYUP) then
  begin
    if message.WParam in [VK_LEFT..VK_DOWN, VK_RETURN, VK_TAB] then
    begin
      Form := GetParentForm(Self);
      if Form = nil then
      begin
        if Application.Handle <> 0 then  // 在exe中运行
        begin
          if Message.WParam <> VK_RETURN then
          begin
            ShiftState := KeyDataToShiftState(TWMKey(Message).KeyData);
            Self.KeyDown(TWMKey(Message).CharCode, ShiftState);
            Exit;
          end;
        end
        else  // 在浏览器中运行
        begin
          if Message.WParam = VK_RETURN then
          begin
            ShiftState := KeyDataToShiftState(TWMKey(Message).KeyData);
            Self.KeyDown(TWMKey(Message).CharCode, ShiftState);

            Exit;
          end;
        end;
      end;
    end;
  end;

  inherited WndProc(Message);
end;

end.
