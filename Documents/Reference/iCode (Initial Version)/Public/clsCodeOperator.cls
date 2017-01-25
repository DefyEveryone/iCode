VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsCodeOperator"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private Declare Function GetCaretPos Lib "user32" (lpPoint As POINTAPI) As Long
Private Declare Function ClientToScreen Lib "user32" (ByVal hWnd As Long, lpPoint As POINTAPI) As Long


Private m_SL As Long
Private m_SC As Long
Private m_EL As Long
Private m_EC As Long

Private m_TargetCodePane As CodePane

Public m As Variant

Public Property Get SL() As Long
    SL = m_SL
End Property

Public Property Let SL(ByVal Value As Long)
    m_SL = Value
End Property

Public Property Get SC() As Long
    SC = m_SC
End Property

Public Property Let SC(ByVal Value As Long)
    m_SC = Value
End Property

Public Property Get EL() As Long
    EL = m_EL
End Property

Public Property Let EL(ByVal Value As Long)
    m_EL = Value
End Property

Public Property Get EC() As Long
    EC = m_EC
End Property

Public Property Let EC(ByVal Value As Long)
    m_EC = Value
End Property

Public Sub UpdataSelectionInfo()
    VBIns.ActiveCodePane.GetSelection m_SL, m_SC, m_EL, m_EC
End Sub

Public Property Get Lines(ByVal StartLine As Long, Optional ByVal Count As Long = 1) As String
    Lines = TargetCodePane.CodeModule.Lines(StartLine, Count)
End Property

'�˹���δ������
Public Property Let Lines(ByVal StartLine As Long, Optional ByVal Count As Long = 1, ByVal Value As String)
    If Count = 1 Then
        TargetCodePane.CodeModule.ReplaceLine StartLine, Value
    Else
        TargetCodePane.CodeModule.DeleteLines StartLine, Count
        TargetCodePane.CodeModule.InsertLines StartLine, Value
    End If
End Property

Public Sub ReplaceLine(ByVal Line As Long, ByVal Code As String)
    TargetCodePane.CodeModule.ReplaceLine Line, Code
End Sub


'���������ֲ������
'����ֵ��������������
Public Function AddCodeToDeclaration(ByVal Code As String) As Long
    TargetCodePane.CodeModule.InsertLines TargetCodePane.CodeModule.CountOfDeclarationLines + 1, Code
    AddCodeToDeclaration = TargetCodePane.CodeModule.CountOfDeclarationLines
End Function

Public Property Get TargetCodePane() As CodePane
    If m_TargetCodePane Is Nothing Then
        Set TargetCodePane = VBIns.ActiveCodePane
    Else
        Set TargetCodePane = m_TargetCodePane
    End If
End Property

Public Property Set TargetCodePane(ByVal Value As CodePane)
    If Value Is Nothing Then
        Set m_TargetCodePane = Nothing
    Else
        Set m_TargetCodePane = Value
    End If
End Property

Public Sub SetCaret(Optional ByVal SL, Optional ByVal SC, Optional ByVal EL, Optional ByVal EC)
    If IsMissing(SL) Then SL = Me.SL
    If IsMissing(SC) Then SC = Me.SC
    If IsMissing(EL) Then EL = Me.EL
    If IsMissing(EC) Then EC = Me.EC
    TargetCodePane.SetSelection SL, SC, EL, EC
    Me.UpdataSelectionInfo
End Sub

Friend Function GetCaretPoint() As POINTAPI
    Dim tPoint As POINTAPI
    GetCaretPos tPoint
    ClientToScreen CodeOpe.TargetCodePane.Window.hWnd, tPoint
    GetCaretPoint = tPoint
End Function

Public Property Get bInDeclaration() As Boolean
    Me.UpdataSelectionInfo
    
    Dim k As Long
    
    k = VBIns.ActiveCodePane.CodeModule.CountOfDeclarationLines
    
    Do While Trim(VBIns.ActiveCodePane.CodeModule.Lines(k + 1, 1)) = "" And k <= VBIns.ActiveCodePane.CodeModule.CountOfLines
        k = k + 1
    Loop
    
    bInDeclaration = (Me.SL <= k)
End Property

Public Property Get Selection() As String
    Dim i As Long
    
    Me.UpdataSelectionInfo
    
    If SL = EL Then
        Selection = Mid(Me.Lines(SL), SC, EC - SC)
    Else
        Selection = Right(Me.Lines(SL), Len(Me.Lines(SL)) - SC + 1) & vbCrLf
        If EL - SL >= 2 Then Selection = Selection & Me.Lines(SL + 1, EL - SL - 1)
        'ע��EC��ָ����ڵ�EC���ַ�ǰ
        If EC = 1 Then
            If EL - SL >= 2 Then Selection = Selection & vbCrLf
        Else
            Selection = Selection & Left(Me.Lines(EL), EC - 1)
        End If
    End If
    
End Property

Public Property Let Selection(ByVal Value As String)
    Me.UpdataSelectionInfo
    
    If Me.SL = Me.EL Then
        Me.InsertCode Value
    Else
        
        Dim nS As Long, nE As Long, sF As String
        
        If SC = 1 Then
            nS = Me.SL
        Else
            '#�Դ˴�SC�Ƿ���Ҫ��һ��������#
            sF = Left(Me.Lines(Me.SL), Me.SC - 1)
            nS = Me.SL + 1
        End If
        
        If Me.EC = Len(Me.Lines(Me.EL)) - 1 Then
            nE = Me.EL
            '���ѡ��ĩ�˰�����EL���У�������ɾȥ
        ElseIf Me.EC = 1 Then
            nE = Me.EL - 1
            '���ѡ��ĩ�˰���EL-1�е���ĩ���У���ɾ����EL-1��
        Else
            
            If SC <> 1 Then
                sF = sF & Right(Me.Lines(Me.EL), Len(Me.Lines(Me.EL)) - (Me.EC - 1))
                nE = Me.EL
                '���ѡ����ʼǰ��ѡ��ĩ�˺󶼸���һ�Σ���ѡ��ĩ������ɾȥ����ѡ��ĩ����ѡ��ĩ���Ҳ࣬��ѡ����ʼ����ѡ����ʼ��˺ϲ����������м�������
            Else
                Me.Lines(Me.EL) = Right(Me.Lines(Me.EL), Len(Me.Lines(Me.EL)) - (Me.EC - 1))
                nE = Me.EL - 1
                '���ѡ����ʼ��������ɾȥ����ֻ��ֱ�Ӵ���ĩ�в���
                '����ɾ����EL-1�У�֮ǰ�л�Ϊ�ն����ᱣ������
            End If
        End If
        
        If sF <> "" Then
            TargetCodePane.CodeModule.ReplaceLine Me.SL, sF
            '����Ӧ��Me.SL������nS
        End If
        
        If nS <= nE Then
            TargetCodePane.CodeModule.DeleteLines nS, nE - nS + 1
            'nS�Ѿ����ǹ�sF�Ƿ���ڵ������
        End If
        
        'SL��SC��EL��EC��������ɾ��ǰ��״̬
        
        Dim OldEC As Long: OldEC = Me.EC
        
        TargetCodePane.SetSelection Me.SL, Me.SC, Me.SL, Me.SC
        '#������Դ���Bug#
        Me.UpdataSelectionInfo
        
        'SL��SC��EL��ECΪ��������״̬
        
        Me.InsertCode Value
        
        If InStr(1, Value, vbCrLf) = 0 Then
            TargetCodePane.SetSelection Me.SL, Me.SC, Me.SL, Me.SC + Len(Value)
        Else
            Dim a() As String, cL As Long
            a = Split(Value, vbCrLf)
            cL = UBound(a)
            '�����Ubound(a)���Ǵ����л��з��ĸ��������ǳ��˲�����������ӵ�����
            'If OldEC = 1 Then cL = cL - 1
            TargetCodePane.SetSelection Me.SL, Me.SC, Me.SL + cL, Len(a(UBound(a))) + 1
        End If
        
    End If
End Property



Public Sub InsertCode(ByVal sCode As String)
    UpdataSelectionInfo
    
    Dim s As String
    
    If SL = EL Then
        s = Me.Lines(SL)
        TargetCodePane.CodeModule.ReplaceLine SL, Left(s, SC - 1) & sCode & Right(s, Len(s) - EC + 1)
        TargetCodePane.SetSelection SL, SC, EL, SC + Len(sCode)
    Else
        
        Me.Selection = sCode
        
    End If
End Sub

Public Function GetProcByLine(ByVal n As Long, ByRef sProc As String, ByRef kProc As vbext_ProcKind) As Boolean
    Dim k As vbext_ProcKind: k = kProc
    sProc = TargetCodePane.CodeModule.ProcOfLine(n, k)
    GetProcByLine = True
End Function

Public Function GetActiveLine() As Long
    Me.UpdataSelectionInfo
    GetActiveLine = Me.SL
End Function

Public Sub ReplaceAll(ByVal Find As String, ByVal Replace As String)
    Dim i As Long
    For i = 1 To VBIns.CodePanes.Count
        Set TargetCodePane = VBIns.CodePanes(i)
        Dim j As Long
        For j = 1 To TargetCodePane.CodeModule.CountOfLines
            Dim s As String
            s = iReplaceAll(Me.Lines(j), Find, Replace)
            If s <> Me.Lines(j) Then TargetCodePane.CodeModule.ReplaceLine j, s
        Next
    Next
    Set TargetCodePane = Nothing '��TargetCodePane���Ĭ�ϣ��������CodePane
End Sub





