/*
 * $Id$
 */

#ifdef VXH_ENTERPRISE
   #define VXH_PROFESSIONAL
#endif

STATIC lSplash := .F.

static aTargetTypes := {".exe", ".lib", ".dll", ".hrb", ".dll"}

//  Link ALL xHarbour functions!!!
#ifndef HB_CDP_SUPPORT_ON
   #define HB_CDP_SUPPORT_OFF
#endif
#include "hbextern.ch"

#include "vxh.ch"
#include "cstruct.ch"
#include "colors.ch"
#include "debug.ch"
#include "hbexcept.ch"
#include "error.ch"
#include "ole.ch"

#include "inkey.ch"
#include "commdlg.ch"
#include "winuser.ch"
#include "fileio.ch"

#define XFM_EOL Chr(13) + Chr(10)
#define HKEY_LOCAL_MACHINE           (0x80000002)

#define VXH_Version      "5"
#define VXH_BuildVersion "5.0.0"

#define MCS_ARROW    10
#define MCS_PASTE    11
#define MCS_DRAGGING 12

#define DG_ADDCONTROL      1
#define DG_DELCONTROL      2
#define DG_PROPERTYCHANGED 3
#define DG_MOVESELECTION   4
#define DG_FONTCHANGED     5
#define DG_DELCOMPONENT    6
#define DG_ALIGNSELECTION  7

#define __XHDN_URL__ "http://www.xHarbour.com/xHDN"
#define __NEWS_URL__ "http://www.xHarbour.com/News_VXH.asp"
#xtranslate NTRIM( < n > ) = > ALLTRIM( STR( < n > ) )

#define __GENVERSIONINFO__
INIT PROCEDURE __VXH_Start
   LOCAL hKey, cRunning, cIni, aRect

   IF RegCreateKey( HKEY_LOCAL_MACHINE, "Software\Visual xHarbour", @hKey ) == 0
      RegQueryValueEx( hKey, "Running",,,@cRunning )
      DEFAULT cRunning TO "0"
      IF cRunning == "0"
         RegSetValueEx( hKey, "Running",, 1, "1" )
         cIni     := GetModuleFileName()
         cIni     := STRTRAN( cIni, ".exe", ".ini" )
         IF FILE( cIni )
            aRect    := ARRAY(4)
            aRect[1] := GetPrivateProfileInt( "Position", "Left",   NIL, cIni )
            aRect[2] := GetPrivateProfileInt( "Position", "Top",    NIL, cIni )
            aRect[3] := GetPrivateProfileInt( "Position", "Width",  NIL, cIni )
            aRect[4] := GetPrivateProfileInt( "Position", "Height", NIL, cIni )
            IF aRect[3] == NIL .OR. aRect[3] == 0
               aRect := NIL
            ENDIF
         ENDIF
         Splash( GetModuleHandle( "vxh.exe" ), "SPLASH", "BMP",,  )
      ENDIF
      RegCloseKey( hKey )
   ENDIF
RETURN

PROCEDURE Main( cFile )
   //RegisterDotNetComponent( "c:\WINDOWS\Microsoft.NET\Framework\v2.0.50727\System.Windows.Forms.dll", "DotNet.Forms.1", @cError )

   AssociateWith( ".xfm", "vxh_project_component", "c:\windows\notepad.exe", "Visual xHarbour file", 1 )
   AssociateWith( ".vxh", "vxh_project_file", GetModuleFileName(), "Visual xHarbour Project", 0 )

   //AssociateWith( ".prg", "prg_file", "c:\Program Files\TextPad 5\TextPad.exe", "xHarbour file", 0 )

   IDE( cFile )
   QUIT
RETURN

//-------------------------------------------------------------------------------------------------------

CLASS IDE INHERIT Application
   DATA Props            EXPORTED INIT {=>}
   DATA EditorProps      EXPORTED INIT {=>}

   DATA ToolBox          EXPORTED
   DATA ObjectManager    EXPORTED
   DATA EventManager     EXPORTED

   DATA MainTab          EXPORTED
   DATA ObjectTree       EXPORTED
   DATA FileTree         EXPORTED

   DATA Project          EXPORTED
   DATA SourceEditor     EXPORTED
   DATA DebugWindow      EXPORTED

   DATA DebuggerPanel    EXPORTED

   DATA Components       EXPORTED
   DATA ShowGrid         EXPORTED
   DATA ShowRulers       EXPORTED INIT .T.
   DATA ShowDocking      EXPORTED INIT .F.

   DATA RulerType        EXPORTED INIT 1
   DATA ShowTip          EXPORTED
   DATA DefaultFolder    EXPORTED
   DATA EditorPage       EXPORTED
   DATA DesignPage       EXPORTED
   DATA ErrorView        EXPORTED
   DATA BuildLog         EXPORTED

   DATA FileMenu         EXPORTED
   DATA SearchMenu       EXPORTED
   DATA ProjectMenu      EXPORTED
   DATA EditMenu         EXPORTED
   DATA ViewMenu         EXPORTED
   DATA HelpMenu         EXPORTED

   DATA SourceTabs       EXPORTED
   DATA FormsTabs        EXPORTED
   DATA ProjectPrgEditor EXPORTED

   DATA QuickForm        EXPORTED
   DATA CloseMenu        EXPORTED
   DATA SaveMenu         EXPORTED
   DATA SaveAsMenu       EXPORTED

   DATA AddToProjectMenu EXPORTED
   DATA AddSourceMenu    EXPORTED
   DATA AddLibraryMenu   EXPORTED
   DATA RemoveSourceMenu EXPORTED

   DATA ObjectTab        EXPORTED
   DATA Sizes            EXPORTED
   DATA RunMode          EXPORTED

   DATA CurCursor        EXPORTED
   DATA ToolBoxBar       EXPORTED

   DATA StartPageBrushes EXPORTED
   DATA aoLinks          EXPORTED INIT {}

   DATA AddOnPath        EXPORTED

   DATA CControls        EXPORTED INIT {}
   DATA DisableWhenRunning EXPORTED INIT .F.

   METHOD Init() CONSTRUCTOR
   METHOD SetEditorPos()
   METHOD EnableBars()
ENDCLASS

METHOD SetEditorPos( nLine, nColumn ) CLASS IDE
   LOCAL cCol, cLine
   cLine := STR( nLine )
   cCol  := STR( nColumn )

   WITH OBJECT ::Application:MainForm
      :StatusBarPanel3:Width   := :Drawing:GetTextExtentPoint32( cLine )[1] + 10
      :StatusBarPanel3:Caption := cLine
      :StatusBarPanel4:Width   := :Drawing:GetTextExtentPoint32( cCol )[1] + 10
      :StatusBarPanel4:Caption := cCol
   END
RETURN Self

METHOD Init( ... ) CLASS IDE
   LOCAL aEntries, n, cFile
   PUBLIC aChangedProps

   m->aChangedProps := {}

   HSetCaseMatch( ::Props, .F. )
   HSetCaseMatch( ::EditorProps, .F. )

   ::__Vxh := .T.
   ::StartPageBrushes := StartPageBrushes( NIL )

   REQUEST DBFNTX, DBFDBT, DBFCDX, DBFFPT, ADS, RMDBFCDX, SQLRDD, SR_ODBC, SR_MYSQL, SR_FIREBIRD, SQLEX

   RddRegister( "ADS", 1 )

   ::Super:Init( NIL )

   ::IdeActive := TRUE
   
   IF HB_ArgC() > 0
      cFile := ""
      FOR n := 1 TO HB_ArgC()
          cFile += HB_ArgV(n) + " "
      NEXT
      cFile := ALLTRIM( cFile )
   ENDIF

   IF ::Running
      IF cFile != NIL
         aEntries := ::IniFile:GetEntries( "Recent" )
         AEVAL( aEntries, {|c| ::Application:IniFile:DelEntry( "Recent", c ) } )
         IF ( n := ASCAN( aEntries, {|c| c == cFile } ) ) > 0
            ADEL( aEntries, n, .T. )
         ENDIF
         aIns( aEntries, 1, cFile, .T. )
         IF LEN( aEntries )>=20
            ASIZE( aEntries, 20 )
         ENDIF
         AEVAL( aEntries, {|c| ::Application:IniFile:WriteString( "Recent", c, "" ) } )

         // RestorePrevInstance parameter is a message to be posted to the main window
         // of the previous instance. I pass WM_USER + 3003 to compare previous attempt
         // to open "cFile" since Entries have changed, the current open project will be
         // replaced by "cFile"

         ::RestorePrevInstance( WM_USER + 3003 )
       ELSE
         ::RestorePrevInstance()
      ENDIF

      RETURN NIL
   ENDIF

   ::ShowTip     := .T.
   ::ShowRulers  := .T.
   ::ShowDocking := .F.
   ::Sizes       := Hash()
   ::Sizes["ObjectManagerWidth"] := 23
   ::Sizes["ToolBoxWidth"]       := 18

   IF( n := ::IniFile:ReadInteger( "General", "ShowRulers", 1 ) ) == 0
      ::ShowRulers := .F.
   ENDIF

   IF( n := ::IniFile:ReadInteger( "General", "ShowDocking", 0 ) ) == 1
      ::ShowDocking := .T.
   ENDIF

   ::EditorProps[ "WrapSearch" ] := ::IniFile:ReadInteger( "Settings", "WrapSearch", 0 )
   ::EditorProps[ "SaveBAK" ]    := ::IniFile:ReadInteger( "Settings", "SaveBAK", 1 )

   ::ShowGrid   := ::IniFile:ReadInteger( "General", "ShowGrid", 0 )
   ::RulerType  := ::IniFile:ReadInteger( "General", "RulerType", 1 )
   ::DisableWhenRunning := ::IniFile:ReadLogical( "General", "DisableWhenRunning", .F. )

   ::Application:LoadCustomColors( HKEY_LOCAL_MACHINE, "Software\Visual xHarbour", "CustomColors" )

   IF( n := ::IniFile:ReadInteger( "General", "ShowTip", 1 ) ) == 0
      ::ShowTip := .F.
   ENDIF
   ::RunMode := ::IniFile:ReadInteger( "General", "RunMode", 1 )
   IF ::RunMode == 2
      ::RunMode := 1
   ENDIF
   ::AddOnPath := ::IniFile:ReadString( "General", "AddOnPath", "c:\xHB\VXH-Add-On" )

   ::CControls := {}

   #ifdef VXH_ENTERPRISE
      ::CControls := ::IniFile:GetEntries( "CustomControls" )
      FOR n := 1 TO LEN( ::CControls )
          IF !FILE( ::CControls[n] )
             ADEL( ::CControls, n, .T. )
             n--
          ENDIF
      NEXT
   #endif

   SHGetFolderPath( NIL, CSIDL_PERSONAL, NIL, 0, @::DefaultFolder )
   IF ::DefaultFolder[-1] == "\"
      ::DefaultFolder += "Visual xHarbour Projects"
    ELSE
      ::DefaultFolder += "\Visual xHarbour Projects"
   ENDIF

   IF ! IsDirectory( ::DefaultFolder )
      MakeDir( ::DefaultFolder )
   ENDIF
   ::Project := Project( NIL )
   ::MainForm := IDE_MainForm( NIL )

   IF cFile != NIL
      ::Project:StartFile := cFile
      ::MainForm:PostMessage( WM_USER + 3002 )
   ENDIF

   ::Run()

   //::StartPageBrushes:Destroy()
RETURN Self

METHOD EnableBars( lEnabled, lOrder ) CLASS IDE
   LOCAL n
   DEFAULT lOrder TO .F.
   WITH OBJECT ::MainForm
      :ToolStrip1:Enabled := lEnabled
      :ToolStrip2:Enabled := lEnabled
      :ToolStrip3:Enabled := lEnabled
      :ToolStrip4:Enabled := lEnabled

      IF lOrder
         FOR n := 1 TO LEN( :ToolStrip5:Children )-1
             :ToolStrip5:Children[n]:Enabled := lEnabled
         NEXT
       ELSE
         :ToolStrip5:Enabled := lEnabled
      ENDIF

      :MenuStrip1:Enabled := lEnabled

      :ToolStripComboBox1:Enabled := lEnabled
   END
   IF lEnabled .AND. ::Project != NIL
      ::Project:EditReset()
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

CLASS IDE_MainForm FROM WinForm
   DATA SelImgList
   DATA SelImgIndex
   DATA ProjectFile
   DATA hHook

   METHOD Init() CONSTRUCTOR
   METHOD OnClose()
   METHOD OnUserMsg()
   METHOD OnTimer()
   METHOD SetKeyStatus()
   METHOD KeyHook()
   METHOD OnSetFocus()
   METHOD OnNCActivate(n) INLINE IIF( ::Application:Project:CurrentForm != NIL, (::CallWindowProc(), ::Application:Project:CurrentForm:InActive := n==0, IIF( n <> 0, ::Application:Project:CurrentForm:UpdateSelection(),), ::Application:Project:CurrentForm:RedrawWindow(,, RDW_FRAME|RDW_INVALIDATE|RDW_UPDATENOW ) ), ),  ::SetKeyStatus( VK_CAPITAL ), NIL
   METHOD OnNavigateError()
   METHOD EnableSearchMenu()
ENDCLASS

METHOD OnNavigateError( Sender /*, pDisp, URL, Frame, StatusCode, Cancel*/ ) CLASS IDE_MainForm
   LOCAL cBuffer := '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' + CRLF +;
                    '<body scroll="no">'  + CRLF +;
                    '<html>' + CRLF +;
                    '<head>' + CRLF +;
                    '<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">' + CRLF +;
                    '<title>Visual xHarbour</title>' + CRLF +;
                    '</head>' + CRLF +;
                    '<body>' + CRLF +;
                    '<basefont FACE="Courier New" SIZE="2">' + CRLF +;
                    '<p ALIGN="CENTER"><font FACE="Arial" SIZE="5">' + CRLF +;
                    '<b>Visual xHarbour</b></font><br>' + CRLF +;
                    '<font FACE="Arial" SIZE="1">' + CRLF +;
                    '&copy; '+Str(Year(Date()))+' xHarbour.com, Inc.<br>' + CRLF +;
                    'All Rights Reserved' + CRLF +;
                    '</font></p>' + CRLF +;
                    '</body>' + CRLF +;
                    '</html>' + CRLF
   Sender:Navigate( "About:blank" )
   Sender:Document:Write( cBuffer )
RETURN NIL


METHOD OnSetFocus() CLASS IDE_MainForm
   IF ::Application:SourceEditor != NIL .AND. ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:SetFocus()
    ELSE
      TRY
         IF ::Application:MainForm:FormEditor1:CtrlMask != NIL
            ::Application:MainForm:FormEditor1:CtrlMask:SetFocus()
         ENDIF
      CATCH
      END
   ENDIF
RETURN NIL

METHOD OnTimer( nId ) CLASS IDE_MainForm
   SWITCH nId
      CASE 1
         ::ToolTip:Title := NIL
         ::ToolTip:Text := NIL
         ::KillTimer( 1 )
         RETURN 0
   END
RETURN NIL

METHOD OnClose() CLASS IDE_MainForm
   LOCAL aSize, pWp, hKey, cName, cType, xData, n, aVal, hSub
   ::Application:Yield()
   IF ! ::Application:Project:Close(,.T.)
      RETURN 0
   ENDIF

   pWp := ::GetWindowPlacement()
   IF pWp:rcNormalPosition:Right == NIL
      RETURN NIL
   ENDIF
   aSize := {pWp:rcNormalPosition:Left,;
             pWp:rcNormalPosition:Top,;
             pWp:rcNormalPosition:Right - pWp:rcNormalPosition:Left,;
             pWp:rcNormalPosition:Bottom - pWp:rcNormalPosition:Top,;
             pWp:rcNormalPosition:Right - pWp:rcNormalPosition:Left,;
             pWp:rcNormalPosition:Bottom - pWp:rcNormalPosition:Top }

   TRY
      ::Application:IniFile:WriteNumber( "Position", "Left",   aSize[1] )
      ::Application:IniFile:WriteNumber( "Position", "Top",    aSize[2] )
      ::Application:IniFile:WriteNumber( "Position", "Width",  aSize[3] )
      ::Application:IniFile:WriteNumber( "Position", "Height", aSize[4] )

      IF pWp:showCmd != 2
         ::Application:IniFile:WriteNumber( "Position", "Show", pWp:showCmd )
      ENDIF

      ::Application:IniFile:WriteNumber( "ObjectTab",     "Height", Round( ( ::Application:ObjectTab:Height / aSize[4] ) * 100, 0 ) )
      ::Application:IniFile:WriteNumber( "ObjectManager", "Width",  Round( ( ::Panel1:Width / aSize[5] ) * 100, 0 ) )
      ::Application:IniFile:WriteNumber( "ToolBox",       "Width",  Round( ( ::ToolBox1:Width / aSize[5] ) * 100, 0 ) )

      ::Application:IniFile:WriteNumber( "General", "RunMode", ::Application:RunMode )

      ::Application:IniFile:WriteNumber( "General", "DisableWhenRunning", IIF( ::Application:DisableWhenRunning, 1, 0 ) )

      ::Application:IniFile:DelSection( "CustomControls" )
      FOR n := 1 TO LEN( ::Application:CControls )
          ::Application:IniFile:WriteString( "CustomControls", ::Application:CControls[n], "" )
      NEXT
   CATCH
   END

   UnhookWindowsHookEx( ::hHook )

   IF RegCreateKey( HKEY_LOCAL_MACHINE, "Software\Visual xHarbour", @hKey ) == 0
      RegSetValueEx( hKey, "Running",, 1, "0" )
      RegCloseKey( hKey )
   ENDIF

   ::Application:SaveCustomColors( HKEY_LOCAL_MACHINE, "Software\Visual xHarbour", "CustomColors" )

   IF RegCreateKey( HKEY_LOCAL_MACHINE, "Software\Visual xHarbour\ComObjects", @hKey ) == 0
      aVal := {}
      n := 0
      WHILE RegEnumKey( hKey, n, @cName, @cType, @xData ) == 0
         AADD( aVal, cName )
         n++
      ENDDO
      AEVAL( aVal, {|c| RegDeleteKey( hKey, c )} )

      FOR n := 1 TO LEN( ::ToolBox1:ComObjects )
          IF RegCreateKey( hKey, ::ToolBox1:ComObjects[n][2], @hSub ) == 0
             RegSetValueEx( hSub, "ProgID",, 1, ::ToolBox1:ComObjects[n][3] )
             RegSetValueEx( hSub, "ClsID",, 1, ::ToolBox1:ComObjects[n][4] )
             RegCloseKey( hSub )
          ENDIF
      NEXT
      RegCloseKey( hKey )
   ENDIF

RETURN NIL

METHOD OnUserMsg( hWnd, nMsg, nwParam ) CLASS IDE_MainForm
   LOCAL nNext, aEntries
   ( hWnd )
   DO CASE
      CASE nMsg == WM_USER + 3000
           nNext := MIN( nwParam + 1, LEN( ::Application:Project:Forms ) )

           IF LEN( ::Application:Project:Forms ) > 0
              ::Application:Project:CurrentForm := ::Application:Project:Forms[ nNext ]
              ::Application:Project:CurrentForm:Show()
              ::Application:FormsTabs:SetCurSel( nNext )
              ::PostMessage( WM_USER + 3001, 0 )
           ENDIF
           RETURN 0

      CASE nMsg == WM_USER + 3001
           IF ::Application:Project:CurrentForm != NIL
              ::Application:Project:SelectBuffer()

              ::Application:Project:CurrentForm:UpdateSelection()

              ::Application:Components:Reset( ::Application:Project:CurrentForm )
              ::Application:ObjectManager:ResetProperties( IIF( EMPTY( ::Application:Project:CurrentForm:Selected ), {{::Application:Project:CurrentForm}}, ::Application:Project:CurrentForm:Selected ) )
              ::Application:EventManager:ResetEvents( IIF( EMPTY( ::Application:Project:CurrentForm:Selected ), {{::Application:Project:CurrentForm}}, ::Application:Project:CurrentForm:Selected ) )
              ::Application:Props[ "ComboSelect" ]:Reset()
            ENDIF

      CASE nMsg == WM_USER + 3002
           IF ::Application:Project:StartFile != NIL
              ::Application:Project:Open( ::Application:Project:StartFile )
              ::SetFocus()
           ENDIF

      CASE nMsg == WM_USER + 3003
           // From BROADCAST message in ::Application:RestorePrevInstance()
           aEntries := ::Application:IniFile:GetEntries( "Recent" )
           IF LEN( aEntries ) > 0
              ::Application:Project:Open( aEntries[1] )
           ENDIF
           //::SetActiveWindow()
   ENDCASE
RETURN NIL


METHOD Init() CLASS IDE_MainForm
   LOCAL cVersion, rc//, aFonts, n

   ::Super:Init()
   #ifdef VXH_DEMO
    ::Caption := "Visual xHarbour Demo " + VXH_Version
   #else
    ::Caption := "Visual xHarbour " + VXH_Version
   #endif

   ::BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd
   ::OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd }

   rc := (struct RECT)
   SystemParametersInfo( SPI_GETWORKAREA, , @rc )

   ::Left    := ::Application:IniFile:ReadNumber( "Position", "Left", 0 )+rc:Left
   ::Top     := ::Application:IniFile:ReadNumber( "Position", "Top", 0 )
   ::Width   := ::Application:IniFile:ReadNumber( "Position", "Width", 800 )
   ::Height  := ::Application:IniFile:ReadNumber( "Position", "Height", 600 )
   ::Icon    := {, "AMAIN" }

   WITH OBJECT ::ToolTip
      :Track       := .T.
      :Absolute    := .F.
      :Icon        := 1
      :Balloon     := .T.
      :CloseButton := .T.
   END

   ::Create()

   WITH OBJECT ::Application
      :Sizes["ObjectManagerWidth"] := MAX( MIN( :IniFile:ReadInteger( "ObjectManager",   "Width",  :Sizes["ObjectManagerWidth"] ), 90 ), 10 )
      :Sizes["ToolBoxWidth"]       := MAX( MIN( :IniFile:ReadInteger( "ToolBox",         "Width",  :Sizes["ToolBoxWidth"] ),       90 ), 10 )
   END

   // StatusBar section ----------------------
   WITH OBJECT StatusBar( Self )
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddIcon( "AMAIN" )
      :Create()


      WITH OBJECT StatusBarPanel( :this )//::StatusBarPanel1
         :ImageIndex := 1

         cVersion := "Demo"
         #ifdef VXH_PROFESSIONAL
            cVersion := "Professional"
         #endif
         #ifdef VXH_ENTERPRISE
            cVersion := "Enterprise"
         #endif
         #ifdef VXH_PERSONAL
            cVersion := "Personal"
         #endif

         :Caption  := "Visual xHarbour " + cVersion + ". Copyright "+CHR(169)+" 2003-"+Str(Year(Date()))+" xHarbour.com Inc. All rights reserved"

         :Width    := :Parent:Drawing:GetTextExtentPoint32( :Caption )[1] + 40
         :Create()
      END

      WITH OBJECT StatusBarPanel( :this )
         :Width      := -1
         :Create()
      END
      WITH OBJECT StatusBarPanel( :this )
         :Width      := 60
         :Create()
      END
      WITH OBJECT StatusBarPanel( :this )
         :Width      := 60
         :Create()
      END
      WITH OBJECT StatusBarPanel( :this )
         IF GetKeyState( VK_CAPITAL ) == 1
            :Caption := PADC( "Caps", 6 )
         ENDIF
         :Width      := 40
         :Create()
      END
      WITH OBJECT StatusBarPanel( :this )
         :Caption := PADC( IIF( ::Application:InsKey, "Ins", "Ovr" ), 5 )
         :Width   := 30
         :Create()
      END
      WITH OBJECT StatusBarPanel( :this )
         :Width      := 140
         :Create()
      END
   END

   ::Application:Props[ "MainToolBar" ] := ToolStripContainer( Self ):Create()

   //--------------------------------------
   WITH OBJECT MenuStrip( ::ToolStripContainer1 )

      :Row := 1
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )
      :ImageList:MaskColor := C_LIGHTCYAN
      :ImageList:AddBitmap( "TBEXTRA" )
      :ImageList:AddBitmap( "TREE" )
      :ImageList:AddIcon( "ICO_COMOBJECT" )
      :Create()

      WITH OBJECT ::Application:FileMenu := MenuStripItem( :this )
         :ImageList := :Parent:ImageList
         :Caption := "&File"
         :Create()

         WITH OBJECT MenuStripItem( :this )
            :Caption    := "&New"
            :ImageList := :Parent:ImageList
            :ImageIndex := 26
            :Create()

            WITH OBJECT MenuStripItem( :this )
               :Caption           := "&Project"
               :ImageIndex        := 21
               :ShortCutText      := "Ctrl+Shift+N"
               :ShortCutKey:Ctrl  := .T.
               :ShortCutKey:Shift := .T.
               :ShortCutKey:Key   := ASC( "N" )
               :Action            := {|| ::Application:Project:NewProject() }
               :Create()
            END

            WITH OBJECT MenuStripItem( :this )
               :Caption           := "&File"
               :ImageIndex        := 22
               :ShortCutText      := "Ctrl+N"
               :ShortCutKey:Ctrl  := .T.
               :ShortCutKey:Key   := ASC( "N" )
               :Action            := {||::Application:Project:NewSource() }
               :Create()
            END

            WITH OBJECT ::Application:Props[ "NewFormItem" ] := MenuStripItem( :this )
               :Caption           := "F&orm"
               :ImageIndex        := 27
               :ShortCutText      := "Ctrl+Shift+F"
               :ShortCutKey:Ctrl  := .T.
               :ShortCutKey:Shift := .T.
               :ShortCutKey:Key   := ASC( "F" )
               :Action            := {|o| IIF( o:Enabled, ::Application:Project:AddWindow(),) }
               :Enabled           := .F.
               :Create()
            END

            WITH OBJECT ::Application:Props[ "CustomControl" ] := MenuStripItem( :this )
               :Caption           := "&Custom Control"
               :ImageIndex        := 28
               :BeginGroup        := .T.
               :ShortCutText      := "Ctrl+Shift+C"
               :ShortCutKey:Ctrl  := .T.
               :ShortCutKey:Shift := .T.
               :ShortCutKey:Key   := ASC( "C" )
               #ifdef VXH_ENTERPRISE
                :Action           := {|o| IIF( o:Enabled, ::Application:Project:AddWindow(,,.T.),) }
               #else
                :Action           := {|| MessageBox( , "Sorry, Custom Controls are available in the Enterprise edition only.", "Visual xHarbour", MB_OK | MB_ICONEXCLAMATION ) }
               #endif
               :Enabled           := .F.
               :Create()
            END
         END

         WITH OBJECT MenuStripItem( :this )
            :Caption    := "&Open"
            :ImageList  := :Parent:ImageList
            :ImageIndex := ::System:StdIcons:FileOpen
            :Create()

            WITH OBJECT MenuStripItem( :this )
               :Caption           := "&Project"
               :ImageIndex        := 23
               :ShortCutText      := "Ctrl+Shift+O"
               :ShortCutKey:Ctrl  := .T.
               :ShortCutKey:Shift := .T.
               :ShortCutKey:Key   := ASC( "O" )
               :Action            := {||::Application:Project:Open() }
               :Create()
            END
            WITH OBJECT ::Application:Props[ "FileOpenItem" ] := MenuStripItem( :this )
               :Caption           := "&File"
               :ImageIndex        := ::System:StdIcons:FileOpen
               :ShortCutText      := "Ctrl+O"
               :ShortCutKey:Ctrl  := .T.
               :ShortCutKey:Key   := ASC( "O" )
               :Action            := {||::Application:Project:OpenSource() }
               :Create()
            END
         END

         WITH OBJECT ::Application:CloseMenu := MenuStripItem( :this )
            :Caption    := "&Close Project"
            :ImageIndex := 16
            :Enabled    := .F.
            :Create()
         END

         WITH OBJECT ::Application:SaveMenu := MenuStripItem( :this )
            :Caption    := "&Save Project"
            :ImageIndex := ::System:StdIcons:FileSave
            :Enabled    := .F.
            :BeginGroup := .T.
            :Create()
         END

         WITH OBJECT ::Application:SaveAsMenu := MenuStripItem( :this )
            :Caption    := "Save Project &As ... "
            :ImageIndex := 0
            :Enabled    := .F.
            :Create()
         END

         WITH OBJECT ::Application:AddToProjectMenu := MenuStripItem( :this )
            :Caption    := "&Add to project"
            :Enabled    := .f.
            :ImageList  := :Parent:ImageList
            :BeginGroup := .T.
            :Create()

            WITH OBJECT ::Application:AddSourceMenu := MenuStripItem( :this )
               :Caption    := "&Selected Program"
               :ImageIndex := 0
               :Action := {||::Application:Project:AddSource() }
               :Enabled    := .F.
               :Create()
            END

            WITH OBJECT ::Application:AddLibraryMenu := MenuStripItem( :this )
               :Caption    := "&Binary Files (*.lib, *.obj)"
               :ImageIndex := 0
               :BeginGroup := .T.
               :Action     := {||::Application:Project:AddBinary() }
               :Create()
            END

            WITH OBJECT ::Application:Props[ "ImportResource" ] := MenuStripItem( :this )
               :BeginGroup := .T.
               :ImageIndex := 0
               :Caption    := "&Project Resources"
               :Action     := {|| ::Application:Project:ImportImages() }
               :Create()
            END

         END

         WITH OBJECT ::Application:RemoveSourceMenu := MenuStripItem( :this )
            :Caption    := "&Remove from project"
            :ImageIndex := 0
            :Action     := {||::Application:Project:RemoveSource() }
            :Enabled    := .F.
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Begingroup := .T.
            :Caption    := "&Settings"
            :Action     := {|| Settings( Self ) }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Begingroup := .T.
            :Caption    := "&Exit"
            :ImageIndex := 0
            :Action     := {||::Application:MainForm:PostMessage( WM_CLOSE ) }
            :Create()
         END

      END

      //------------------------------------------------------------------
      WITH OBJECT ::Application:EditMenu := MenuStripItem( :this )
         :ImageList := :Parent:ImageList
         :Caption := "&Edit"
         :Create()

         WITH OBJECT ::Application:Props[ "EditCopyItem" ] := MenuStripItem( :this )
            :Caption          := "&Copy"
            :ImageIndex       := ::System:StdIcons:Copy
            :ShortCutText     := "Ctrl+C"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "C" )
            :Action           := {|o| IIF( o:Enabled .OR. UPPER( GetClassName( GetFocus() ) ) == "EDIT", ::Application:Project:EditCopy(), ) }
            :Enabled          := .F.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "EditCutItem" ] := MenuStripItem( :this )
            :Caption          := "C&ut"
            :ImageIndex       := ::System:StdIcons:Cut
            :ShortCutText     := "Ctrl+X"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "X" )
            :Action           := {|o| IIF( o:Enabled .OR. UPPER( GetClassName( GetFocus() ) ) == "EDIT", ::Application:Project:EditCut(), ) }
            :Enabled          := .F.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "EditPasteItem" ] := MenuStripItem( :this )
            :Caption          := "&Paste"
            :ImageIndex       := ::System:StdIcons:Paste
            :ShortCutText     := "Ctrl+V"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "V" )
            :Action           := {|o| IIF( o:Enabled .OR. UPPER( GetClassName( GetFocus() ) ) == "EDIT", ::Application:Project:EditPaste(), ) }
            :Enabled          := .F.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "EditUndoItem" ] := MenuStripItem( :this )
            :Caption          := "&Undo"
            :ImageIndex       := ::System:StdIcons:Undo
            :ShortCutText     := "Ctrl+Z"
            :ShortCutKey:Alt  := .T.
            :ShortCutKey:Key  := VK_BACK
            :Enabled          := .F.
            :Action           := {|o| IIF( o:Enabled .OR. UPPER( GetClassName( GetFocus() ) ) == "EDIT", ::Application:Project:Undo(), ) }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "EditRedoItem" ] := MenuStripItem( :this )
            :Caption          := "&Redo"
            :ImageIndex       := ::System:StdIcons:Redo
            :ShortCutText     := "Ctrl+Y"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "Y" )
            :Enabled          := .F.
            :Action           := {|o| IIF( o:Enabled .OR. UPPER( GetClassName( GetFocus() ) ) == "EDIT", ::Application:Project:Redo(), ) }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "RectSelect" ] := MenuStripItem( :this )
            :Caption           := "&Toggle Rectangle Selection"
            :BeginGroup        := .T.
            :ImageIndex        := 0
            :ShortCutText      := "Ctrl+Shift+F8"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := VK_F8
            :Enabled           := .T.
            :Action            := {|| ::Application:SourceEditor:ToggleRectSel() }
            :Create()
         END
         WITH OBJECT MenuStripItem( :this )
            :Caption           := "&Change Case"
            :BeginGroup        := .T.
            :ImageIndex        := 0
            :Create()
            WITH OBJECT ::Application:Props[ "EditUpperCase" ] := MenuStripItem( :this )
               :Caption          := "&Upper Case"
               :ImageIndex       := 0
               :ShortCutText     := "Ctrl+U"
               :ShortCutKey:Ctrl := .T.
               :ShortCutKey:Key  := ASC( "U" )
               :Action           := {|| ::Application:SourceEditor:UpperCase() }
               :Create()
            END
            WITH OBJECT ::Application:Props[ "EditLowerCase" ] := MenuStripItem( :this )
               :Caption          := "&Lower Case"
               :ImageIndex       := 0
               :ShortCutText     := "Ctrl+L"
               :ShortCutKey:Ctrl := .T.
               :ShortCutKey:Key  := ASC( "L" )
               :Action           := {|| ::Application:SourceEditor:LowerCase() }
               :Create()
            END
            WITH OBJECT ::Application:Props[ "EditInvCase" ] := MenuStripItem( :this )
               :Caption          := "&Invert Case"
               :ImageIndex       := 0
               :ShortCutText     := "Ctrl+K"
               :ShortCutKey:Ctrl := .T.
               :ShortCutKey:Key  := ASC( "K" )
               :Action           := {|| ::Application:SourceEditor:InvertCase() }
               :Create()
            END
            WITH OBJECT ::Application:Props[ "EditCapitalize" ] := MenuStripItem( :this )
               :Caption          := "&Capitalize"
               :ImageIndex       := 0
               :ShortCutText     := "Ctrl+Shift+U"
               :ShortCutKey:Ctrl := .T.
               :ShortCutKey:Shift:= .T.
               :ShortCutKey:Key  := ASC( "U" )
               :Action           := {|| ::Application:SourceEditor:Capitalize() }
               :Create()
            END
         END

      END
      //------------------------------------------------------------------
      WITH OBJECT ::Application:SearchMenu := MenuStripItem( :this )
         :ImageList := ImageList( :this, 16, 16 ):Create()
         :ImageList:AddImage( IDB_STD_SMALL_COLOR )
         :ImageList:AddIcon( "ICO_TOGGBM" )
         :ImageList:AddIcon( "ICO_NEXTBM" )
         :ImageList:AddIcon( "ICO_PREVBM" )
         :Caption := "Search"
         :Create()
         WITH OBJECT ::Application:Props[ "SearchFindItem" ] := MenuStripItem( :this )
            :Caption          := "&Find"
            :ImageIndex       := ::System:StdIcons:Find
            :ShortCutText     := "Ctrl+F"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "F" )
            :Enabled          := .T.
            :Action           := {|o| IIF( o:Enabled, ::Application:Project:Find(), ) }
            :Create()
         END
         WITH OBJECT ::Application:Props[ "SearchReplaceItem" ] := MenuStripItem( :this )
            :Caption          := "&Replace"
            :ImageIndex       := ::System:StdIcons:Replace
            :ShortCutText     := "Ctrl+H"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "H" )
            :Enabled          := .T.
            :Action           := {|o| IIF( o:Enabled, ::Application:Project:Replace(), ) }
            :Create()
         END
         WITH OBJECT ::Application:Props[ "WrapSearchItem" ] := MenuStripItem( :this )
            :Caption    := "&Wrap Searches"
            :BeginGroup := .T.
            :Checked    := ( ::Application:EditorProps:WrapSearch == 1 )
            :Action     := <|o|
                             o:Checked := ! o:Checked
                             ::Application:EditorProps:WrapSearch := IIF( o:Checked, 1, 0 )
                             ::Application:IniFile:WriteInteger( "Settings", "WrapSearch", ::Application:EditorProps:WrapSearch )
                           >
            :Create()
         END
         WITH OBJECT ::Application:Props[ "TogBookmark" ] := MenuStripItem( :this )
            :Caption           := "&Toggle Bookmark"
            :ImageIndex        := 16
            :ShortCutText      := "Ctrl+F2"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Key   := VK_F2
            :Enabled           := .T.
            :Action            := {|| ::Application:SourceEditor:ToggleBookmark() }
            :Create()
         END
         WITH OBJECT ::Application:Props[ "NextBookmark" ] := MenuStripItem( :this )
            :Caption           := "&Next Bookmark"
            :ImageIndex        := 17
            :ShortCutText      := "F2"
            :ShortCutKey:Key   := VK_F2
            :Enabled           := .T.
            :Action            := <|n|
                                    IF ( n := ::Application:SourceEditor:BookmarkNext() ) >= 0
                                       ::Application:SourceEditor:Source:GoToLine(n)
                                    ENDIF
                                  >
            :Create()
         END
         WITH OBJECT ::Application:Props[ "PrevBookmark" ] := MenuStripItem( :this )
            :Caption           := "&Previous Bookmark"
            :ImageIndex        := 18
            :ShortCutText      := "Shift+F2"
            :ShortCutKey:Key   := VK_F2
            :ShortCutKey:Shift := .T.
            :Enabled           := .T.
            :Action            := <|n|
                                    IF ( n := ::Application:SourceEditor:BookmarkPrev() ) >= 0
                                       ::Application:SourceEditor:Source:GoToLine(n)
                                    ENDIF
                                  >
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ClearBookmark" ] := MenuStripItem( :this )
            :Caption           := "&Clear All Bookmarks"
            :ImageIndex        := 0
            :ShortCutText      := "Ctrl+Shift+F2"
            :ShortCutKey:Key   := VK_F2
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Ctrl  := .T.
            :Enabled           := .T.
            :Action            := {|| ::Application:SourceEditor:BookmarkDelAll()}
            :Create()
         END

         WITH OBJECT ::Application:Props[ "SearchGoto" ] := MenuStripItem( :this )
            :Caption           := "&Go To"
            :BeginGroup        := .T.
            :ShortCutText      := "Ctrl+G"
            :ShortCutKey:Key   := ASC("G")
            :ShortCutKey:Ctrl  := .T.
            :Enabled           := .F.
            :Action            := {|o| IIF( o:Enabled, ::Application:SourceEditor:GotoDialog(), ) }
            :Create()
         END
         ::AddAccelerator( FVIRTKEY | FCONTROL, 66, 0 )

      END

      //------------------------------------------------------------------
      WITH OBJECT ::Application:ViewMenu := MenuStripItem( :this )
         :Caption := "&View"
         :ImageList := :Parent:ImageList
         :Create()

         WITH OBJECT MenuStripItem( :this )
            :Caption := "Control Alignment"
            :Create()

            WITH OBJECT ::Application:Props[ "AlignGrid" ] := MenuStripItem( :this )
               :Caption    := "Align Controls to &Grid"
               :RadioCheck := .T.
               :Checked    := ( ::Application:ShowGrid == 1 )
               :Action := {|o| o:Checked := .T.,;
                          ::Application:Props[ "AlignNo" ]:Checked := .F.,;
                          ::Application:Props[ "AlignSticky" ]:Checked := .F.,;
                          ::Application:IniFile:WriteInteger( "General", "ShowGrid", ::Application:ShowGrid := 1 ),;
                          IIF( ::Application:Project:CurrentForm != NIL, ( ::Application:Project:CurrentForm:InvalidateRect(),;
                                                                        ::Application:Project:CurrentForm:UpdateSelection() ), ) }
               :Create()
            END

            WITH OBJECT ::Application:Props[ "AlignSticky" ] := MenuStripItem( :this )
               :Caption    := "&Sticky Alignment"
               :RadioCheck := .T.
               :Checked    := ( ::Application:ShowGrid == 2 )
               :Action := {|o| o:Checked := .T.,;
                          ::Application:Props[ "AlignNo" ]:Checked := .F.,;
                          ::Application:Props[ "AlignGrid" ]:Checked := .F.,;
                          ::Application:IniFile:WriteInteger( "General", "ShowGrid", ::Application:ShowGrid := 2 ),;
                          IIF( ::Application:Project:CurrentForm != NIL, ( ::Application:Project:CurrentForm:InvalidateRect(),;
                                                                        ::Application:Project:CurrentForm:UpdateSelection() ), ) }
               :Create()
            END

            WITH OBJECT ::Application:Props[ "AlignNo" ] := MenuStripItem( :this )
               :Caption    := "&No Alignment"
               :RadioCheck := .T.
               :Checked    := ( ::Application:ShowGrid == 0 )
               :Action := {|o| o:Checked := .T.,;
                          ::Application:Props[ "AlignGrid" ]:Checked := .F.,;
                          ::Application:Props[ "AlignSticky" ]:Checked := .F.,;
                          ::Application:IniFile:WriteInteger( "General", "ShowGrid", ::Application:ShowGrid := 0 ),;
                          IIF( ::Application:Project:CurrentForm != NIL, ( ::Application:Project:CurrentForm:InvalidateRect(),;
                                                                           ::Application:Project:CurrentForm:UpdateSelection() ), ) }
               :Create()
            END
         END

         WITH OBJECT ::Application:Props[ "ViewToolBoxItem" ] := MenuStripItem( :this )
            :Caption    := "&ToolBox"
            :BeginGroup := .T.
            :Checked    := .T.
            :Action     := {|o| IIF( o:Checked,;
                                   ( o:Checked := .F., ::Application:MainForm:ToolBox1:Hide() ),;
                                   ( o:Checked := .T., ::Application:MainForm:ToolBox1:Show() ) ) }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewDebugBuildItem" ] := MenuStripItem( :this )
            :Caption    := "&Build Panel"
            :Checked    := .F.
            :Action     := {|o| o:Checked := ! o:Checked, ::Application:DebugWindow:Visible := o:Checked }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewObjectManagerItem" ] := MenuStripItem( :this )
            :Caption    := "&Object Manager"
            :Checked    := .T.
            :Action     := {|o| o:Checked := ! o:Checked, ::Application:Props[ "ObjectManagerPanel" ]:Visible := o:Checked }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewRulersItem" ] := MenuStripItem( :this )
            :Checked      := ( ::Application:ShowRulers )
            :BeginGroup   := .T.
            :ImageIndex   := 0
            :Caption      := "Rulers"
            :ShortCutText := "Ctrl+Shift+R"
            :Action       := {|o| o:Checked := ( ::Application:ShowRulers := !::Application:ShowRulers ),;
                                                 ::Application:MainForm:FormEditor1:Refresh(),;
                                                 ::Application:IniFile:WriteInteger( "General", "ShowRulers", IIF( ::Application:ShowRulers, 1, 0 ) ) }
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "R" )
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewDocking" ] := MenuStripItem( :this )
            :Checked      := ::Application:ShowDocking
            :Caption      := "Show Docking"
            :ShortCutText := "Ctrl+Shift+D"
            :Action       := {|o| o:Checked := ( ::Application:ShowDocking := !::Application:ShowDocking ),;
                                                 IIF( ::Application:Project:CurrentForm != NIL, ::Application:Project:CurrentForm:UpdateLayout(),),;
                                                 ::Application:IniFile:WriteInteger( "General", "ShowDocking", IIF( ::Application:ShowDocking, 1, 0 ) ) }
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "D" )
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :ImageIndex   := IIF( :Parent:ImageList != NIL, :Parent:ImageList:Count, 0 )
            :BeginGroup   := .T.
            :Caption      := "Registered COM Objects"
            :Action       := {|| ::Application:Project:AddActiveX() }
            :ShortCutText := "F11"
            :ShortCutKey:Key := VK_F11
            #ifndef VXH_PROFESSIONAL
             :Enabled     := .F.
            #endif
            :Create()
         END
      END

      WITH OBJECT ::Application:ProjectMenu := MenuStripItem( :this )
         :Caption := "&Project"
         :ImageList := :Parent:ImageList
         :Create()

         WITH OBJECT ::Application:Props[ "NewFormProjItem" ] := MenuStripItem( :this )
            :Caption      := "Add &Form"
            :ImageIndex   := 27
            :ShortCutText := "Ctrl+Shift+F"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "F" )
            :Action       := {|o| IIF( o:Enabled, ::Application:Project:AddWindow(),) }
            :Enabled      := .F.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "SaveItem" ] := MenuStripItem( :this )
            :ImageIndex   := ::System:StdIcons:FileSave
            :BeginGroup   := .T.
            :Caption      := "Save"
            :ShortCutText := "Ctrl+S"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "S" )
            :Action       := {|| ::Application:Project:Save(.T.) }
            :Enabled      := .F.
            :Create()
         END
         WITH OBJECT ::Application:Props[ "ForceBuildItem" ] := MenuStripItem( :this )
            :ImageIndex        := 25
            :Caption           := "Force Build"
            :ShortCutText      := "Ctrl+Shift+B"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "B" )
            :Action            := {|| ::Application:Project:Build( .T. ) }
            :Enabled           := .F.
            :Create()
         END
         WITH OBJECT ::Application:Props[ "RunItem" ] := MenuStripItem( :this )
            :ImageIndex := 18
            :Caption    := "Run"
            :Action     := {|| ::Application:Project:Run( .T. ) }
            :Enabled    := .F.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ResourceManager" ] := MenuStripItem( :this )
            :BeginGroup := .T.
            :ImageIndex := 0
            :Caption    := "&Resource Manager"
            :Action     := {|| ResourceManager( NIL ) }
            :Enabled    := .F.
            :Create()
         END

      END

      WITH OBJECT ::Application:HelpMenu := MenuStripItem( :this )
         :Caption := "&Help"
         :ImageList := :Parent:ImageList
         :Create()

         WITH OBJECT MenuStripItem( :this )
            :Caption := "&Help"
            :Action  := {|| IIF( FILE( ::Application:Path + "\Visual xHarbour.chm" ),;
                                 HTMLHelp( GetDesktopWindow(), ::Application:Path + "\Visual xHarbour.chm", 0, 0 ),;
                                 MessageBox( , "Sorry, no help available yet.", "Visual xHarbour", MB_OK | MB_ICONEXCLAMATION ) ) }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Caption := "&About"
            :Action  := {|| AboutVXH( NIL ) }
            :Create()
         END
      END
   END

   WITH OBJECT ToolStrip( ::ToolStripContainer1 )
      //:ShowChevron := .F.
      :Caption := "Standard"
      :Row     := 2
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )
      :ImageList:MaskColor := C_LIGHTCYAN
      :ImageList:AddBitmap( "TBEXTRA" )
      :ImageList:AddBitmap( "TREE" )
      :Create()

      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 26
         :ToolTip:Text := "New"
         :DropDown     := 2
         :Action       := {|| ::Application:Project:NewProject() }
         :ImageList    := :Parent:ImageList
         :Create()

         WITH OBJECT MenuStripItem( :this )
            :Caption           := "&Project"
            :ImageIndex        := 21
            :ShortCutText      := "Ctrl+Shift+N"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "N" )
            :Action            := {|| ::Application:Project:NewProject() }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Caption           := "&File"
            :ImageIndex        := 22
            :ShortCutText      := "Ctrl+N"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Key   := ASC( "N" )
            :Action            := {||::Application:Project:NewSource() }
            :Create()
         END

         WITH OBJECT ::Application:QuickForm := MenuStripItem( :this )
            :Caption           := "F&orm"
            :ImageIndex        := 27
            :ShortCutText      := "Ctrl+Shift+F"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "F" )
            :Action            := {|o| IIF( o:Enabled, ::Application:Project:AddWindow(),) }
            :Enabled           := .F.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "BttnCustomControl" ] := MenuStripItem( :this )
            :Caption           := "&Custom Control"
            :ImageIndex        := 28
            :BeginGroup        := .T.
            :ShortCutText      := "Ctrl+Shift+C"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Shift := .T.
            :ShortCutKey:Key   := ASC( "C" )
            #ifdef VXH_ENTERPRISE
             :Action            := {|o| IIF( o:Enabled, ::Application:Project:AddWindow(,,.T.),) }
            #else
             :Action            := {|| MessageBox( , "Sorry, Custom Controls are available in the Enterprise edition only.", "Visual xHarbour", MB_OK | MB_ICONEXCLAMATION ) }
            #endif
            :Enabled            := .F.
            :Create()
         END

      END

      WITH OBJECT ::Application:Props[ "OpenBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:FileOpen
         :ToolTip:Text := "Open"
         :Action       := {||::Application:Project:Open() }
         :DropDown     := 2
         :Create()
      END

      WITH OBJECT ::Application:Props[ "CloseBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 16
         :ToolTip:Text := "Close"
         :Action       := {||::Application:Project:Close() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "SaveBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:FileSave
         :ToolTip:Text := "Save"
         :Action       := {||::Application:Project:Save(.T.) }
         :Enabled      := .F.
         :Create()
      END
   END

   WITH OBJECT ToolStrip( ::ToolStripContainer1 )
      //:ShowChevron := .F.
      :Caption := "Edit"
      :Row     := 2
      :Create()
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )

      WITH OBJECT ::Application:Props[ "EditCopyBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Copy
         :ToolTip:Text := "Copy"
         :Action       := {|| ::Application:Project:EditCopy() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditCutBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Cut
         :ToolTip:Text := "Cut"
         :Action       := {||::Application:Project:EditCut() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditPasteBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Paste
         :ToolTip:Text := "Paste"
         :Action       := {|| ::Application:Project:EditPaste() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditDelBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Delete
         :ToolTip:Text := "Delete"
         :Action       := {|| ::Application:Project:EditDelete() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditUndoBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Undo
         :ToolTip:Text := "Undo"
         :BeginGroup   := .T.
         :Action       := {|| ::Application:Project:UnDo() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditRedoBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Redo
         :ToolTip:Text := "Redo"
         :Action       := {|| ::Application:Project:ReDo() }
         :Enabled      := .F.
         :Create()
      END
   END

   WITH OBJECT ToolStrip( ::ToolStripContainer1 )
      //:ShowChevron := .F.
      :Row := 2
      :Caption := "Build"
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )
      :ImageList:MaskColor := C_LIGHTCYAN
      :ImageList:AddBitmap( "TBEXTRA" )
      :Create()

      WITH OBJECT ::Application:Props[ "RunBttn" ] := ToolStripButton( :this )
         :ImageIndex      := 18
         :ToolTip:Text    := "Save / Build & Run (F5)"
         :ShortCutKey:Key := VK_F5
         :Action          := {||::Application:Project:Run() }
         :DropDown        := 2
         :Enabled         := .F.
         :ImageList       := :Parent:ImageList
         :Create()

         WITH OBJECT ::Application:Props[ "ProjSaveItem" ] := MenuStripItem( :this )
            :ImageIndex   := ::System:StdIcons:FileSave
            :ShortCutText := "Ctrl+S"
            :Caption      := "Save"
            :Action       := {|| ::Application:Project:Save() }
            :Create()
         END
         WITH OBJECT ::Application:Props[ "ProjBuildItem" ] := MenuStripItem( :this )
            :ImageIndex   := 25
            :Caption      := "Build"
            :Action       := {|| ::Application:Project:Build() }
            :Enabled      := .F.
            :Create()
         END
         WITH OBJECT ::Application:Props[ "ProjRunItem" ] := MenuStripItem( :this )
            :ImageIndex := 18
            :Caption := "Run"
            :Action  := {|| ::Application:Project:Run( .T. ) }
            :Create()
         END

      END

      WITH OBJECT ToolStripComboBox( :this )
         :Action := {|o|::Application:RunMode := o:GetCurSel()-1 }
         :Create()
         :AddItem( "Debug" )
         :AddItem( "Release" )
         :SetCurSel( ::Application:RunMode+1 )
      END

   END

   WITH OBJECT ::Application:ToolBoxBar := ToolStrip( ::ToolStripContainer1 )
      //:ShowChevron := .F.
      :Row       := 3
      :Caption   := ""
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:MaskColor := C_LIGHTCYAN
      :ImageList:AddIcon( "ICO_POINTER" )
      :ImageList:AddBitmap( "TREE" )
      :Create()

      WITH OBJECT ::Application:Props[ "PointerBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 1
         :ToolTip:Text := "ToolBox Pointer Auto Selection"
         :Checked      := .T.
         :Role         := 2
         :Create()
      END
      WITH OBJECT ::Application:Props[ "NewFormBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 2
         :ToolTip:Text := "New Form"
         :Action       := {|| ::Application:Project:AddWindow() }
         :Enabled      := .F.
         :Create()
      END

   END


   WITH OBJECT ::Application:Props[ "AlignBar" ] := ToolStrip( ::ToolStripContainer1 )
      //:ShowChevron := .F.
      :Row       := 3
      :Caption   := "Alignment"
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:MaskColor := C_MAGENTA
      :ImageList:AddBitmap( "ALIGNBAR" )
      :ImageList:AddIcon( "ICO_POINTER" )
      :Create()

      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 5
         :ToolTip:Text := "Align Lefts"
         :Action       := {||::Application:Project:AlignLefts() }
         :Enabled      := .F.
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 3
         :ToolTip:Text := "Align Centers"
         :Action       := {||::Application:Project:AlignCenters() }
         :Enabled      := .F.
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 6
         :ToolTip:Text := "Align Rights"
         :Action       := {||::Application:Project:AlignRights() }
         :Enabled      := .F.
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :BeginGroup   := .T.
         :ImageIndex   := 2
         :ToolTip:Text := "Align Tops"
         :Action       := {||::Application:Project:AlignTops() }
         :Enabled      := .F.
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 4
         :ToolTip:Text := "Align Middles"
         :Action       := {||::Application:Project:AlignMiddles() }
         :Enabled      := .F.
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 1
         :ToolTip:Text := "Align Bottoms"
         :Action       := {||::Application:Project:AlignBottom() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ToolStripButton( :this )
         :BeginGroup   := .T.
         :ImageIndex   := 7
         :ToolTip:Text := "Make Same Width"
         :Action       := {||::Application:Project:SameWidth() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 8
         :ToolTip:Text := "Make Same Height"
         :Action       := {||::Application:Project:SameHeight() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ToolStripButton( :this )
         :ImageIndex   := 9
         :ToolTip:Text := "Make Same Size"
         :Action       := {||::Application:Project:SameSize() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "CenterHorBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 11
         :BeginGroup   := .T.
         :ToolTip:Text := "Center Horizontally"
         :Action       := {||::Application:Project:CenterHorizontally() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "CenterVerBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 10
         :ToolTip:Text := "Center Vertically"
         :Action       := {||::Application:Project:CenterVertically() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "TabOrderBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 12
         :BeginGroup   := .T.
         :ToolTip:Text := "Tab Order"
         :Action       := {|o|::Application:Project:TabOrder(o) }
         :Role         := 2
         :Enabled      := .F.
         :Create()
      END
   END

/*
   WITH OBJECT ::Application:Props[ "FontBar" ] := ToolStrip( ::ToolStripContainer1 )
      //:ShowChevron := .F.
      :Row       := 3
      :Caption   := "Alignment"
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddIcon( "ICO_BOLD" )
      :ImageList:AddIcon( "ICO_ITALIC" )
      :ImageList:AddIcon( "ICO_UNDERLINE" )
      :Enabled := .F.
      :Create()

      WITH OBJECT ::Application:Props[ "FontList" ] := ToolStripComboBox( :this )
         :Action  := <|o,cText,n|
                       DEFAULT cText TO o:GetSelString()
                       IF !EMPTY(cText)
                          WITH OBJECT ::Application:SourceEditor
                             :StyleSetFont( cText )
                             :StyleClearAll()
                             :InitLexer()
                             IF ( n := o:FindString(, cText ) ) > 0
                                o:SetCurSel(n)
                             ENDIF
                          END
                       ENDIF
                     >
         :DropDownStyle := ::System:DropDownStyle:DropDown
         :ComboBox:VertScroll := .T.
         :Height  := 336
         :Width   := 217
         :Create()
         aFonts := ::Drawing:EnumFonts()
         ASORT( aFonts,,, {|a,b| a[1]:lfFaceName:AsString() <  b[1]:lfFaceName:AsString() } )
         FOR n := 1 TO LEN( aFonts )
             :AddItem( aFonts[n][1]:lfFaceName:AsString() )
         NEXT
      END

      WITH OBJECT ::Application:Props[ "FontSize" ] := ToolStripComboBox( :this )
         :Action  := <|o,cText|
                       DEFAULT cText TO o:GetSelString()
                       IF !EMPTY(cText)
                          WITH OBJECT ::Application:SourceEditor
                             :StyleSetSize( VAL(cText) )
                             :StyleClearAll()
                             :InitLexer()
                             IF ( n := o:FindString(, cText ) ) > 0
                                o:SetCurSel(n)
                             ENDIF
                          END
                       ENDIF
                     >

         :DropDownStyle := ::System:DropDownStyle:DropDown
         :ComboBox:VertScroll := .T.
         :Height  := 336
         :Width   := 50
         :Create()
         aFonts := {8,9,10,11,12,14,16,18,20,22,24,26,28,36,48,72}
         FOR n := 1 TO LEN( aFonts )
             :AddItem( AllTrim( Str(aFonts[n]) ) )
         NEXT
      END


      WITH OBJECT ::Application:Props[ "FontBold" ] := ToolStripButton( :this )
         :ImageIndex   := 1
         :BeginGroup   := .T.
         :ToolTip:Text := "Bold"
         :Action       := {||::Application:Project:CenterHorizontally() }
         :Create()
      END

      WITH OBJECT ::Application:Props[ "FontItalic" ] := ToolStripButton( :this )
         :ImageIndex   := 2
         :ToolTip:Text := "Italic"
         :Action       := {||::Application:Project:CenterVertically() }
         :Create()
      END

      WITH OBJECT ::Application:Props[ "FontUnderline" ] := ToolStripButton( :this )
         :ImageIndex   := 3
         :ToolTip:Text := "Underline"
         :Action       := {|o|::Application:Project:TabOrder(o) }
         :Create()
      END

   END
*/
   WITH OBJECT ::Application:ToolBox := ToolBox( Self )
      :Caption          := "ToolBox"

      :StaticEdge       := .F.
      :Flat             := .T.
      :AllowUndock      := .T.
      :AllowClose       := .T.
      :OnWMClose        := {|o| o:Redock() }
      :OnWMClose        := {|o| IIF( o:IsDocked, (o:Hide(), ::Application:Props[ "ViewToolBoxItem" ]:Checked := .F. ), o:Redock() ) }

      :Width            := Round( ( :Parent:ClientWidth*::Application:Sizes["ToolBoxWidth"])/100,0)
      :Left             := 149
      :Dock:Margin      := 2
      :Dock:Left        := :Parent
      :Dock:Top         := ::Application:Props[ "MainToolBar" ]
      :Dock:Bottom      := ::StatusBar1

      :FullRowSelect    := .T.

      :NoHScroll        := .T.
      :HasButtons       := .T.
      :LinesAtRoot      := .T.
      :ShowSelAlways    := .T.
      :HasLines         := .F.
      :DisableDragDrop  := .T.

      :Create()
   END

   WITH OBJECT Splitter( Self )
      :Owner := ::ToolBox1
      :Create()
   END

   // Panel
   WITH OBJECT ::Application:Props[ "ObjectManagerPanel" ] := Panel( Self )
      :Caption          := "Object Manager"
      :AllowUndock      := .T.
      :AllowClose       := .T.
      :OnWMClose        := {|o| IIF( o:IsDocked, (o:Hide(), ::Application:Props[ "ViewObjectManagerItem" ]:Checked := .F. ), o:Redock() ) }
      :Width            := Round( ( :Parent:ClientWidth*::Application:Sizes["ObjectManagerWidth"])/100,0)
      :Height           := 300
      :Dock:Margin      := 2
      :Dock:Top         := ::Application:Props[ "MainToolBar" ]
      :Dock:Bottom      := ::StatusBar1
      :Dock:Right       := :Parent

      :Create()

      WITH OBJECT ::Application:Props[ "ComboSelect" ] := FormComboBox( :this )
         :ItemToolTips:= .T.
         :Dock:Left   := :Parent
         :Dock:Top    := :Parent
         :Dock:Right  := :Parent
         :Height      := 500
         :Sort        := .T.
         :Create()
      END

      WITH OBJECT ::Application:ObjectTab := TabStrip( :this )
         :Multiline   := .F.
         :Dock:Margin := 1
         :Dock:Left   := :Parent
         :Dock:Top    := ::Application:Props[ "ComboSelect" ]
         :Dock:Right  := :Parent
         :Dock:Bottom := :Parent
         :BackColor        := ::System:CurrentScheme:ToolStripPanelGradientEnd
         :OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd }
         :Create()

         WITH OBJECT TabPage( :this )
            :Caption   := "Properties"
            :Create()

            WITH OBJECT ::Application:Props[ "ObjectProps" ] := Panel( :this )
               :Height        := 50 //70
               :MinHeight     := 50
               :MaxHeight     := 150
               :Dock:Margin   := 0
               :Dock:Left     := :Parent
               :Dock:Bottom   := :Parent
               :Dock:Right    := :Parent

               :BackColor        := ::System:CurrentScheme:ToolStripPanelGradientEnd
               :OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd }
               
               :Create()

               WITH OBJECT Label( :this )
                  :Left       := 5
                  :Top        := 5
                  :Width      := 70
                  :RightAlign := .T.
                  :Caption    := "Control Name"
                  :Create()
               END

               WITH OBJECT Label( :this )
                  :Left       := 90
                  :Top        := 5
                  :Width      := :Parent:ClientWidth - ::Label1:Width //- :Parent:LinkLabel1:Width
                  :Font:Bold  := .T.
                  :Create()
               END

               WITH OBJECT Label( :this )
                  :Left       := 5
                  :Top        := 25
                  :Width      := 70
                  :RightAlign := .T.
                  :Caption    := "Object Type"
                  :Create()
               END

               WITH OBJECT Label( :this )
                  :Left       := 90
                  :Top        := 25
                  :Width      := :Parent:ClientWidth - ::Label1:Width //- :Parent:LinkLabel1:Width
                  :Font:Bold  := .T.
                  :Create()
               END

               WITH OBJECT Label( :this )
                  :Width      := :Parent:ClientWidth - ::Label1:Width //- :Parent:LinkLabel1:Width
                  :Dock:Left  := :Parent
                  :Dock:Top   := :Parent
                  :Font:Bold  := .T.
                  :Visible    := .F.
                  :Create()
               END

               WITH OBJECT Label( :this )
                  :Dock:Left  := :Parent
                  :Dock:Top   := ::Label5
                  :Dock:Right := :Parent//:LinkLabel1
                  :Dock:Bottom:= :Parent
                  :Font:Bold  := .F.
                  :Visible    := .F.
                  :Create()
               END
            END

            WITH OBJECT Splitter( :this )
               :Owner    := ::Panel2
               :ShowDragging := .T.
               :Position := 2
               :Create()
            END

            // Object manager -------------
            WITH OBJECT ::Application:ObjectManager := ObjManager( :this )
               :Width             := 200
               :Height            := 300
               :Dock:Top          := :Parent
               :Dock:Left         := :Parent
               :Dock:Bottom       := ::Panel2
               :Dock:Right        := :Parent

               :FullRowSelect     := .T.

               :NoHScroll         := .T.
               :HasButtons        := .T.
               :LinesAtRoot       := .T.
               :ShowSelAlways     := .T.

               :Columns := { {120,C_WHITE}, {120,C_WHITE} }
               :Create()
               :SetFocus()
               :BackColor := GetSysColor( COLOR_BTNFACE )
               :ExpandAll()
            END

         END

         WITH OBJECT TabPage( :this )
            :Caption   := "Events"
            :Create()

            // Object manager -------------
            WITH OBJECT ::Application:EventManager := EventManager( :this )
               :Width         := 200
               :Height        := 300
               :Dock:Top      := :Parent
               :Dock:Left     := :Parent
               :Dock:Bottom   := :Parent
               :Dock:Right    := :Parent
               //:Dock:Margin   := 2

               :FullRowSelect := .T.

               :NoHScroll     := .T.
               :HasButtons    := .T.
               :LinesAtRoot   := .T.
               :ShowSelAlways := .T.

               :Columns := { {120,C_WHITE}, {100,C_WHITE} }
               :Create()
               :ExpandAll()
            END
         END


         WITH OBJECT TabPage( :this )
            :Caption   := "Object View"
            :Create()


            WITH OBJECT ::Application:ObjectTree := ObjectTreeView( :this )
               :Left          := 500
               :Width         := 200
               :Height        := 300
               :Dock:Top      := :Parent
               :Dock:Left     := :Parent
               :Dock:Bottom   := :Parent
               :Dock:Right    := :Parent
               :ExStyle       := 0
               //:Dock:Margin   := 2
               :HasButtons    := .T.
               :ShowSelAlways := .T.
               :Create()
            END

         END

         WITH OBJECT TabPage( :this )
            :Caption   := "File View"
            :Create()
            WITH OBJECT ::Application:FileTree := FileTreeView( :this )
               :ExStyle     := 0
               :AcceptFiles := .T.
               :Left        := 500
               :Width       := 200
               :Height      := 300
               :Dock:Top    := :Parent
               :Dock:Left   := :Parent
               :Dock:Bottom := :Parent
               :Dock:Right  := :Parent
               :Dock:Margin := 0
               :HasButtons  := .T.
               :ImageList   := ImageList( :this, 16, 16 ):Create()
               :ImageList:MaskColor := C_LIGHTCYAN
               :ImageList:AddBitmap( "TREE" )
               :ImageList:AddBitmap( "TBEXTRA" )
               :Create()
            END
         END

      END

   END

   WITH OBJECT Splitter( Self )
      :Owner := ::Panel1
      :Create()
   END

   WITH OBJECT ::Application:DebugWindow := DebugTab( Self )
      :AllowClose    := .T.
      :Width         := 680
      :Height        := ( 200 * 4 ) / LOWORD( GetDialogBaseUnits() )
      :Multiline     := .T.
      :TabPosition   := 4
      :AllowUndock   := .T.
      :Dock:Left     := ::ToolBox1
      :Dock:Bottom   := ::StatusBar1
      :Dock:Right    := ::Panel1
      :TabStop       := .F.
      :Visible       := .F.
      :Create()

      WITH OBJECT TabPage( :this )
         //:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd
         //:OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd}
         :Caption := "Build"
         :Create()

         DebugBuild( :this )

         WITH OBJECT ::DebugBuild1
            :Height      := 150
            :ForeColor   := C_BLACK
            :BackColor   := C_WHITE
            :Dock:Margin := 0
            :Dock:Left   := :Parent
            :Dock:Top    := :Parent
            :Dock:Bottom := :Parent
            :Dock:Right  := :Parent
            :ExStyle     := 0
            :Create()
         END

      END

      WITH OBJECT TabPage( :this )
         //:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd
         //:OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd}
         :Caption := "Errors"
         :Create()
         WITH OBJECT ::Application:ErrorView := ErrorListView( :this )
            :ClientEdge    := .F.
            :StaticEdge    := .f.
            :Dock:Left     := :Parent
            :Dock:Top      := :Parent
            :Dock:Right    := :Parent
            :Dock:Bottom   := :Parent
            :Dock:Margin   := 0
            :ExStyle       := 0
            :ViewStyle     := 1
            :FullRowSelect := .T.
            :Create()
            ListViewColumn( :this, "Source File", 150,, .T. )
            ListViewColumn( :this, "Line",         70,, .T. )
            ListViewColumn( :this, "Type",         70,, .T. )
            ListViewColumn( :this, "Description", 350,, .T. )
         END
      END

      WITH OBJECT TabPage( :this )
         :Caption := "Log"
         :Create()
         WITH OBJECT ::Application:BuildLog := EditBox( :this )
            :ClientEdge     := .F.
            :StaticEdge     := .f.
            :Dock:Margin    := 0
            :Dock:Left      := :Parent
            :Dock:Top       := :Parent
            :Dock:Right     := :Parent
            :Dock:Bottom    := :Parent
            :MultiLine      := .T.
            :ReadOnly       := .T.
            :HorzScroll     := .T.
            :VertScroll     := .T.
            :Create()
         END
      END
      :Visible := .F.
   END

   WITH OBJECT Splitter( Self )
      :Owner := ::Application:DebugWindow//::TabControl1
      :Create()
   END

   // Panel EXCLUSIVE for vxh-debugger
   WITH OBJECT ::Application:DebuggerPanel := Panel( Self )
      :Width          := 680
      :Height         := 200
      :StaticEdge     := .T.
      :Dock:Left      := ::ToolBox1
      :Dock:Bottom    := ::Application:DebugWindow //::TabControl1
      :Dock:Right     := ::Panel1
      :AllowClose     := .T.
      :AllowUndock    := .T.
      //:OnWMSysCommand := {|o,n| If( n == SC_CLOSE, ( o:Hide(), 0 ), ) }
      //:BackColor      := ::System:CurrentScheme:ToolStripPanelGradientEnd
      :OnWMClose      := {|o| o:Hide() }
      :Visible        := .F.
      :Create()
   END

   WITH OBJECT Splitter( Self )
      :Owner := ::Application:DebuggerPanel
      :Create()
   END

   // TabControl
   WITH OBJECT ::Application:MainTab := TabStrip( Self )
      :Width     := 680
      :Height    := 300
      :Multiline := .F.
      
      :Dock:Margin := 0
      :Dock:Left   := ::ToolBox1
      :Dock:Top    := ::Application:Props[ "MainToolBar" ]
      :Dock:Right  := ::Panel1
      :Dock:Bottom := ::Application:DebuggerPanel//::Panel2

      :OnSelChanged := <|n,x,y|
                        (n,x)
                        ::Application:Project:EditReset( IIF( y > 3, 1, 0 ) )
                        ::Application:MainForm:ToolBox1:Enabled       := y > 3
                        IF y > 3
                           ::Application:Project:CurrentForm:Redraw()
                        ENDIF
                        ::Application:ObjectTree:Enabled              := y > 3
                        ::EnableSearchMenu( y == 3 )
                       >
      :Create()

      WITH OBJECT ::Application:Props[ "StartTabPage" ] := StartTabPage( :this )
         :Caption      := "Start Page"
         :Create()

         WITH OBJECT StartPagePanel( :this )
            :ImageList  := ::Application:MainForm:ToolStrip1:ImageList
            //:StaticEdge := .T.
            :BackColor  := C_WHITE
            :Left   := 10
            :Top    := ::Application:StartPageBrushes:HeaderBkGnd[3]+10
            :Width  := ::Application:StartPageBrushes:RecentBk[2]
            :Height := ::Application:StartPageBrushes:RecentBk[3]

            :Cursor     := IDC_HAND
            :HorzScroll := .T.
            :VertScroll := .T.
            :Create()

            WITH OBJECT LinkLabel( :this )
               :ImageIndex  := 23
               :Caption     := "Open a Project"
               :Left        := 30
               :Top         := :Parent:Height - 45
               :Action      := {|| ::Application:Project:Open() }
               :Font:Bold   := .F.
               :Create()
            END

            WITH OBJECT LinkLabel( :this )
               :ImageIndex  := 21
               :Caption     := "Create a New Project"
               :Left        := 30
               :Top         := :Parent:Height - 25
               :Transparent := .T.
               :Action      := {|| ::Application:Project:NewProject() }
               :Font:Bold   := .F.
               :Create()
            END
         END

         WITH OBJECT StartPagePanel( :this )
            :nPanel     := 1

            :ImageList   := ::ToolStrip1:ImageList

            //:StaticEdge := .T.
            :BackColor  := C_WHITE

            :Left   := 300
            :Top    := ::Application:StartPageBrushes:HeaderBkGnd[3]+10
            :Width  := ::Application:StartPageBrushes:NewsBk[2]
            :Height := ::Application:StartPageBrushes:NewsBk[3]

            :Cursor     := IDC_HAND
            :HorzScroll := .T.
            :VertScroll := .T.
            :Create()
            WITH OBJECT WebBrowser( :this )
               :ControlParent := .T.
               :Left   := 6
               :Top    := 28
               :Width  := :Parent:Width - 12
               :height := :Parent:height - 76
               :Url    := __NEWS_URL__
               :EventHandler[ "NavigateError" ] := "OnNavigateError"
               :Create()
            END
         END
      END

      WITH OBJECT XHDN_Page( :this )
         :Caption   := "xHarbour Developers Network"
         :Create()
         :ActiveX := WebBrowser( :this )
         :ActiveX:Url := __XHDN_URL__
         :ActiveX:ControlParent := .T.
         :ActiveX:DockToParent()
         :ActiveX:EventHandler[ "NavigateError" ] := "OnNavigateError"
         :ActiveX:Create()
      END

      WITH OBJECT ::Application:EditorPage := TabPage( :this )
         :Caption          := "Source Code Editor"
         :BackColor        := ::System:Color:White

         :OnWMShowWindow   := {|| OnShowEditors() }
         :OnWMSetFocus     := {|| ::Application:SourceEditor:SetFocus() }

         :Create()

         WITH OBJECT ::Application:SourceTabs := TabStrip( :this )
            :Height           := :ItemHeight + 3
            :Dock:Left        := :Parent
            :Dock:Bottom      := :Parent
            :Dock:Right       := :Parent
            :OnSelChanged     := {|,x,y| ::Application:Project:SourceTabChanged( x,y ) }
            :OnWMSetFocus     := {|| ::Application:SourceEditor:SetFocus() }
            :TabStop          := .F.
            :TabPosition      := 4
            :Visible          := .F.
            :BackColor        := ::System:CurrentScheme:ToolStripPanelGradientEnd
            :OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd }
            :Create()
         END

         WITH OBJECT ::Application:SourceEditor := SourceEditor( :this )
            :Left             := 400
            :Top              := 100
            :Width            := 200
            :Height           := 250
            :Dock:Left        := :Parent
            :Dock:Bottom      := ::Application:SourceTabs
            :Dock:Right       := :Parent
            :Dock:Top         := :Parent
            :Create()
            :Disable()
         END

      END

      WITH OBJECT ::Application:DesignPage := TabPage( :this )
         :Caption   := "Form Designer"
         :BackColor := ::System:Color:White 
         :Enabled   := .F.
         :Create()
         :OnWMShowWindow := {|o| OnShowDesigner(o) }

         WITH OBJECT ::Application:FormsTabs := TabStrip( :this )
            :Height           := :ItemHeight + 3
            :Dock:Left        := :Parent
            :Dock:Bottom      := :Parent
            :Dock:Right       := :Parent
            :TabStop          := .F.
            :Visible          := .T.
            :OnSelChanged     := {|,,y| ::Application:Project:SelectWindow( ::Application:Project:Forms[y],, .T. ) }
            :TabPosition      := 4
            :BackColor        := ::System:CurrentScheme:ToolStripPanelGradientEnd
            :OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd }
            :Create()
         END

         WITH OBJECT ::Application:Components := ComponentPanel( :this )
            :Dock:Left      := :Parent
            :Dock:Right     := :Parent
            :Dock:Bottom    := ::Application:FormsTabs //:Parent
            //:MinHeight      := 65
            //:MaxHeight      := 140
            :Top            := 300
            :Height         := 50
            :StaticEdge     := .F.
            :Flat           := .T.
            :GenerateMember := .F.
            :BackColor        := ::System:CurrentScheme:ToolStripGradientBegin
            :OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripGradientBegin }
            :Visible := .F.
            :Create()
         END

         //WITH OBJECT Splitter( :this )
         //   :Owner := ::Application:Components
         //   :ShowDragging := .T.
         //   :Create()
         //END

         WITH OBJECT FormEditor( :this )
            :Dock:Left   := :Parent
            :Dock:Top    := :Parent//::Application:FormsTabs
            :Dock:Right  := :Parent
            :Dock:Bottom := ::Application:Components //{|| IIF( IsWindowVisible( ::Application:Components:hWnd ), ::Application:Components, ::Application:FormsTabs ) }
            :Create()
         END
      END

   END

   ::ShowMode:= ::Application:IniFile:ReadNumber( "Position", "Show", SW_SHOWMAXIMIZED )
   ::Application:Project:ResetQuickOpen()
   ::Show()

//   EVAL( ::TabControl4:OnSelChanged, NIL, NIL, 1)

   ::hHook := SetWindowsHookEx( WH_KEYBOARD, HB_ObjMsgPtr( Self, "KeyHook" ), NIL, GetCurrentThreadId(), Self )

   #ifdef VXH_DEMO

    MessageBox( GetActiveWindow(), "Thank you for evaluating Visual xHarbour." + CRLF + CRLF + ;
                                   "Copyright (c) 2003-"+Str(Year(Date()))+" xHarbour.com Inc." + CRLF + ;
                                   "http://www.xHarbour.com" + CRLF ;
                                  ,"Visual xHarbour Demo", MB_OK | MB_ICONINFORMATION )
   #endif

RETURN Self

METHOD EnableSearchMenu( lEnabled ) CLASS IDE_MainForm
   ::Application:Props:SearchGoto:Enabled        := lEnabled
   ::Application:Props:TogBookmark:Enabled       := lEnabled
   ::Application:Props:NextBookmark:Enabled      := lEnabled
   ::Application:Props:PrevBookmark:Enabled      := lEnabled
   ::Application:Props:ClearBookmark:Enabled     := lEnabled
   ::Application:Props:WrapSearchItem:Enabled    := lEnabled
   ::Application:Props:SearchReplaceItem:Enabled := lEnabled
   ::Application:Props:SearchFindItem:Enabled    := lEnabled
   ::Application:Props:EditUpperCase:Enabled     := lEnabled
   ::Application:Props:EditLowerCase:Enabled     := lEnabled
   ::Application:Props:EditInvCase:Enabled       := lEnabled
   ::Application:Props:EditCapitalize:Enabled    := lEnabled
   ::Application:Props:RectSelect:Enabled        := lEnabled
RETURN Self

METHOD KeyHook( nCode, nwParam, nlParam ) CLASS IDE_MainForm
   ( nwParam )
   IF HiWord( nlParam ) & KF_UP == 0
      IF nwParam == VK_INSERT
         ::Application:InsKey := !::Application:InsKey
         ::SetKeyStatus( nwParam )
       ELSEIF nwParam == VK_CAPITAL .AND. HiWord( nlParam ) & KF_REPEAT == 0
         ::SetKeyStatus( nwParam )
      ENDIF
   ENDIF
RETURN CallNextHookEx( ::hHook, nCode, nwParam, nlParam)


METHOD SetKeyStatus( nKey ) CLASS IDE_MainForm
   LOCAL cText := ""
   IF nKey == VK_CAPITAL
      IF GetKeyState( nKey ) + 128 == 1 .OR. GetKeyState( nKey ) == 1
         cText := PADC( "Caps", 6 )
      ENDIF
      ::StatusBarPanel5:Caption := cText
    ELSEIF nKey == VK_INSERT
      ::StatusBarPanel6:Caption := PADC( IIF( ::Application:InsKey, "Ins", "Ovr" ), 5 )
   ENDIF
RETURN NIL

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

CLASS StartTabPage INHERIT TabPage
   METHOD OnEraseBkGnd()
   METHOD OnPaint()
   METHOD OnSize(w,l)  INLINE ::Super:OnSize( w, l ), ::InvalidateRect(), NIL
   METHOD Create()  INLINE    ::Super:Create(), ::__lOnPaint := .F., Self
   //METHOD __OnParentSize( x, y, hDef ) INLINE ::Super:__OnParentSize( x, y, @hDef ), ::InvalidateRect(), NIL
ENDCLASS

METHOD OnPaint( hDC, hMemDC ) CLASS StartTabPage
   ( hDC )
   ::OnEraseBkGnd(, hMemDC )
RETURN 0

METHOD OnEraseBkGnd( hDC, hMemDC ) CLASS StartTabPage
   LOCAL hMemBitmap, hOldBitmap
   ( hDC )

   IF hDC != NIL
      hMemDC     := CreateCompatibleDC( hDC )
      hMemBitmap := CreateCompatibleBitmap( hDC, ::ClientWidth, ::ClientHeight )
      hOldBitmap := SelectObject( hMemDC, hMemBitmap)
   ENDIF

   _FillRect( hMemDC, { -::HorzScrollPos, 0, ::ClientWidth, ::ClientHeight}, GetStockObject( WHITE_BRUSH ) )
   _FillRect( hMemDC, { -::HorzScrollPos, 0, MAX(::ClientWidth,::OriginalRect[3]), ::Application:StartPageBrushes:HeaderBkGnd[3]}, ::Application:StartPageBrushes:HeaderBkGnd[1] )

   PicturePaint( ::Application:StartPageBrushes:HeaderLogo[1], hMemDC, -::HorzScrollPos, 0 )
   PicturePaint( ::Application:StartPageBrushes:BodyBkGnd[1], hMemDC,;
                                                            MAX(::ClientWidth,::OriginalRect[3])-::Application:StartPageBrushes:BodyBkGnd[2] - ::HorzScrollPos,;
                                                            MAX(::ClientHeight,::OriginalRect[4])-::Application:StartPageBrushes:BodyBkGnd[3] - ::VertScrollPos )

//   PicturePaint( ::Application:StartPageBrushes:RecentBk[1], hMemDC, -::HorzScrollPos, ::Application:StartPageBrushes:HeaderBkGnd[3]+10 )

   IF hDC != NIL
      BitBlt( hDC, 0, 0, ::ClientWidth, ::ClientHeight, hMemDC, 0, 0, SRCCOPY )

      SelectObject( hMemDC,  hOldBitmap )
      DeleteObject( hMemBitmap )
      DeleteDC( hMemDC )
   ENDIF
RETURN 1

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

CLASS StartPagePanel INHERIT Panel
   DATA nPanel INIT 0
   METHOD OnEraseBkGnd()
   METHOD OnPaint()
   METHOD OnSize(w,l)  INLINE Super:OnSize( w, l ), ::InvalidateRect(,.F.), NIL
   METHOD Create()  INLINE ::Super:Create(), ::__lOnPaint := .F., Self
ENDCLASS

METHOD OnPaint( hDC, hMemDC ) CLASS StartPagePanel
   ( hDC )
   ::OnEraseBkGnd(, hMemDC )
RETURN 0

METHOD OnEraseBkGnd( hDC, hMemDC ) CLASS StartPagePanel
   LOCAL oChild, hOldBitmap1, hMemDC1
   LOCAL hMemBitmap, hOldBitmap
   IF !::IsWindow()
      RETURN 0
   ENDIF
   IF hDC != NIL
      hMemDC     := CreateCompatibleDC( hDC )
      hMemBitmap := CreateCompatibleBitmap( hDC, ::ClientWidth, ::ClientHeight )
      hOldBitmap := SelectObject( hMemDC, hMemBitmap)
   ENDIF

   IF ::nPanel == 0
      PicturePaint( ::Application:StartPageBrushes:RecentBk[1], hMemDC, 0, 0 )
    ELSE
      PicturePaint( ::Application:StartPageBrushes:NewsBk[1], hMemDC, 0, 0 )
   ENDIF

   IF hMemBitmap != NIL

      FOR EACH oChild IN ::Children
          IF oChild:__lReqBrush
             oChild:__lReqBrush :=.F.

             IF oChild:__hBrush != NIL
                DeleteObject( oChild:__hBrush )
             ENDIF

             DEFAULT oChild:__hMemBitmap TO CreateCompatibleBitmap( hDC, oChild:Width+oChild:__BackMargin, oChild:Height+oChild:__BackMargin )

             hMemDC1      := CreateCompatibleDC( hDC )
             hOldBitmap1  := SelectObject( hMemDC1, oChild:__hMemBitmap )

             BitBlt( hMemDC1, 0, 0, oChild:Width, oChild:Height, hMemDC, oChild:Left+oChild:__BackMargin, oChild:Top+oChild:__BackMargin, SRCCOPY )

             oChild:__hBrush := CreatePatternBrush( oChild:__hMemBitmap )

             SelectObject( hMemDC1,  hOldBitmap1 )
             DeleteDC( hMemDC1 )
          ENDIF
      NEXT
   ENDIF

   IF hDC != NIL
      BitBlt( hDC, 0, 0, ::ClientWidth, ::ClientHeight, hMemDC, 0, 0, SRCCOPY )

      SelectObject( hMemDC,  hOldBitmap )
      DeleteObject( hMemBitmap )
      DeleteDC( hMemDC )
   ENDIF
RETURN 1

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

FUNCTION OnShowDesigner()
   LOCAL oApp := __GetApplication()
   IF oApp:Project:CurrentForm != NIL
      oApp:Project:EditReset(0)
   ENDIF
   oApp:CloseMenu:Action  := {||oApp:Project:Close() }
   oApp:CloseMenu:Caption := "&Close Project"
   oApp:CloseMenu:Enable()

   oApp:SaveMenu:Action  := {||oApp:Project:Save() }
   oApp:SaveMenu:Caption := "Save Project"
//   oApp:SaveMenu:Enable()

   oApp:SaveAsMenu:Action  := {||oApp:Project:SaveAs() }
   oApp:SaveAsMenu:Caption := "Save Project &As ..."
   oApp:SaveAsMenu:Enable()
RETURN NIL

FUNCTION OnShowEditors()
   LOCAL cFile
   LOCAL oApp := __GetApplication()

   IF oApp:SourceEditor != NIL .AND. oApp:SourceEditor:DocCount > 0
      IF oApp:SourceEditor:Source == oApp:ProjectPrgEditor .OR. ASCAN( oApp:Project:Forms, {|o| o:Editor == oApp:SourceEditor:Source} ) > 0
         OnShowDesigner( oApp:DesignPage )
         RETURN NIL
      ENDIF

      oApp:Project:EditReset(0)

      cFile := oApp:Project:CheckValidProgram()

      oApp:CloseMenu:Action   := {||oApp:Project:CloseSource() }
      oApp:CloseMenu:Caption  := "Close " + cFile + " Source File"

      oApp:SaveMenu:Action    := {||oApp:Project:SaveSource() }
      oApp:SaveMenu:Caption   := "Save " + cFile + " Source File"

      oApp:SaveAsMenu:Action  := {||oApp:Project:SaveSourceAs(,.T.) }
      oApp:SaveAsMenu:Caption := "Save " + cFile + " Source File &As ..."
   ENDIF
RETURN NIL

FUNCTION SetControlCursor( oItem )
   LOCAL cClass, n
   LOCAL oApp := __GetApplication()

   oApp:MainForm:ToolBox1:ActiveItem := oItem
   oApp:MainForm:SelImgList  := oItem:Parent:ImageList
   oApp:MainForm:SelImgIndex := oItem:ImageIndex

   cClass := oItem:Caption
   oApp:CurCursor := IIF( cClass != "Pointer", cClass, NIL )

   IF oItem:Owner:Caption == "COM Objects"
      IF ( n := ASCAN( oApp:MainForm:ToolBox1:ComObjects, {|a| a[2] == cClass } ) ) > 0
         oApp:CurCursor := oApp:MainForm:ToolBox1:ComObjects[n]
      ENDIF

    ELSEIF oItem:Owner:Caption == "Custom Controls"
      FOR n := 2 TO LEN( oItem:Owner:Items )
          IF oItem:Owner:Items[n]==oItem
             oApp:CurCursor := oApp:CControls[n-1]
             EXIT
          ENDIF
      NEXT

   ENDIF

   IF oApp:Project:CurrentForm != NIL
      oApp:Project:CurrentForm:CtrlMask:SetMouseShape( IIF( cClass != "Pointer", MCS_DRAGGING, MCS_ARROW ) )
   ENDIF
RETURN NIL

//-------------------------------------------------------------------------------------------------------

#xtranslate Ceil( <x> ) => ( Iif( <x> - Int( <x> ) > 0, Int( <x> ) + 1, <x> ) )

FUNCTION MakeGridTile( nxGrid, nyGrid, Width, Height)

   LOCAL nWidth   := 256 - 256 % nxGrid
   LOCAL nHeight  := 256 - 256 % nyGrid
   LOCAL cBits    := ""
   LOCAL nByte    := 1
   LOCAL nVal     := 0
   LOCAL cDotted
   LOCAL cEmpty
   LOCAL nBits
   LOCAL i

   Width   := nWidth
   Height  := nHeight
   nWidth  := Ceil( nWidth/8 )
   nWidth  := If( nWidth%2==0, nWidth, nWidth+1 )
   cDotted := Replicate( Chr(255), nWidth )
   cEmpty  := cDotted
   nBits   := ( 8*nWidth ) - 1

   FOR i:=0 TO nBits STEP nxGrid
      IF i >= nByte*8
         cDotted[ nByte ] := 255-nVal
         nVal  := 2^( 7-(i%8) )
         nByte := Int(i/8) + 1
      ELSE
         nVal += 2^( 7-(i%8) )
      ENDIF
   NEXT
   cDotted[nByte] := 255-nVal

   nHeight--
   FOR i:= 0 TO nHeight
      IF i % nyGrid == 0
         cBits += cDotted
      ELSE
         cBits += cEmpty
      ENDIF
   NEXT
RETURN cBits

//-----------------------------------------------------------------------------
FUNCTION GetCurrentForm( oCombo )
   LOCAL n, cText, oApp := __GetApplication()
   cText := oCombo:GetSelString()
   IF !EMPTY( cText )
      n := AT( CHR(9), cText )
      cText := SUBSTR( cText, n+1, LEN( cText )-n+1 )
      RETURN __objSendMsg( oApp:MainForm:Property[ cText ] )
   ENDIF
RETURN oApp:Project:CurrentForm

//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------

CLASS XHDN_Page INHERIT TabPage
   DATA ActiveX
   METHOD OnSize(w,l) INLINE Super:OnSize( w, l ), IIF( ::ActiveX != NIL, (::ActiveX:Left   := 2,;
                                                  ::ActiveX:Top    := 2,;
                                                  ::ActiveX:Width  := ::ClientWidth - 4,;
                                                  ::ActiveX:Height := ::ClientHeight - 4 ),), 0
ENDCLASS

CLASS Project
   ACCESS Application    INLINE __GetApplication()
   ACCESS System         INLINE __GetSystem()

   DATA Forms            EXPORTED INIT {}
   DATA CustomControls   EXPORTED INIT {}
   DATA DesignPage       EXPORTED INIT .F.
   DATA CurrentForm      EXPORTED
   DATA ProjectFile      EXPORTED

   DATA StartFile        EXPORTED
   DATA Properties       EXPORTED
   DATA CopyBuffer       EXPORTED INIT {}
   DATA aUndo            EXPORTED INIT {}
   DATA aRedo            EXPORTED INIT {}
   DATA PasteOn          EXPORTED INIT .F.
   DATA Built            EXPORTED INIT .F.
   DATA lDebugging       EXPORTED INIT .F.
   DATA Debugger         EXPORTED
   DATA AppObject        EXPORTED

   DATA lModified        PROTECTED INIT .F.
   DATA aImages          EXPORTED INIT {}
   DATA aRealSelection   EXPORTED

   DATA cFileRemove      EXPORTED
   DATA cSourceRemove    EXPORTED

   DATA __CustomOwner    EXPORTED INIT .F.
   DATA __ExtraLibs      EXPORTED INIT {}
   
   DATA FindDialog       EXPORTED
   DATA ReplaceDialog    EXPORTED
   
   ASSIGN Modified(lMod) INLINE ::SetCaption( lMod )
   ACCESS Modified       INLINE ::lModified

   METHOD AddWindow()
   METHOD Init() CONSTRUCTOR
   METHOD Save()
   METHOD SaveAs()
   METHOD Close()
   METHOD Open()
   METHOD GenerateControl()
   METHOD GenerateProperties()
   METHOD GenerateChild()
   METHOD Build()
   METHOD Run()
   METHOD Debug()
   METHOD DebugStop()
   METHOD ParseXFM()
   METHOD LoadForm()
   METHOD LoadUnloadedImages()
   METHOD ParseRC()
   METHOD NewProject()
   METHOD OpenDesigner()
   METHOD SetCaption( lMod )
   METHOD SelectWindow()
   METHOD SelectBuffer()
   METHOD ResetQuickOpen()
   METHOD EditCopy()
   METHOD EditCut()
   METHOD EditPaste()
   METHOD EditReset()
   METHOD EditDelete()

   METHOD NewSource()
   METHOD OpenSource()
   METHOD CloseSource()
   METHOD SaveSource()
   METHOD SaveSourceAs()
   METHOD AddSource()
   METHOD RemoveSource()
   METHOD AddBinary()
   METHOD SourceTabChanged()
   METHOD CheckValidProgram()

   METHOD AlignRights()
   METHOD AlignLefts()
   METHOD AlignMiddles()
   METHOD AlignCenters()
   METHOD AlignTops()
   METHOD AlignBottom()

   METHOD SameWidth()
   METHOD SameHeight()
   METHOD SameSize()

   METHOD CenterHorizontally()
   METHOD CenterVertically()
   METHOD TabOrder()

   METHOD Undo()
   METHOD ReDo()
   METHOD Find()
   METHOD Replace()

   METHOD SetAction()
#ifdef VXH_PROFESSIONAL
   METHOD AddActiveX()
#endif
   METHOD ImportRes()
   METHOD ImportImages()

   METHOD AddImage()
   METHOD RemoveImage()
   METHOD AddControl()
   METHOD FixPath( cPath, cSubDir ) INLINE IIF( AT(":",cSubDir)>0 .OR. AT("\\",cSubDir)>0, cSubDir, cPath + "\" + cSubDir )
   METHOD SetEditMenuItems()
ENDCLASS

//-------------------------------------------------------------------------------------------------------
METHOD Init() CLASS Project
RETURN Self

METHOD AddControl( cCtrl, oParent ) CLASS Project
   LOCAL oCtrl := &cCtrl( oParent ):Create()
   IF cCtrl == "TabPage"
      oCtrl:BackgroundImage := FreeImageRenderer( oCtrl ):Create()
      oCtrl:Caption := "Page &"+LTRIM( STR( oCtrl:Index ) )
      oParent:Left ++
      ::CurrentForm:__lModified := .T.
   ENDIF
   ::Modified := .T.
RETURN oCtrl

METHOD EditReset(n) CLASS Project
   LOCAL lCopied, lSelected, lEnabled, i
   DEFAULT n TO IIF( ::Application:SourceEditor:Parent:Hidden, 1, 0 )

   IF n == 1
      IF ::CurrentForm != NIL
         lCopied   := LEN( ::CopyBuffer ) > 0
         lSelected := LEN( ::CurrentForm:Selected ) > 0 .AND. ::CurrentForm:Selected[1][1]:__lCopyCut
       ELSE
         lCopied   := .F.
         lSelected := .F.
      ENDIF
    ELSE
      lCopied   := IsClipboardFormatAvailable( CF_TEXT )
      lSelected := ::Application:SourceEditor:Source != NIL .AND. ::Application:SourceEditor:Source:GetSelLen() > 0
   ENDIF
   ::Application:Props[ "EditPasteItem" ]:Enabled := lCopied
   ::Application:Props[ "EditPasteBttn" ]:Enabled := lCopied
   ::Application:Props[ "EditCopyItem"  ]:Enabled := lSelected
   ::Application:Props[ "EditCopyBttn"  ]:Enabled := lSelected
   ::Application:Props[ "EditCutItem"   ]:Enabled := lSelected
   ::Application:Props[ "EditCutBttn"   ]:Enabled := lSelected
   ::Application:Props[ "EditDelBttn"   ]:Enabled := lSelected .OR. ( n == 1 .AND. ::CurrentForm != NIL )

   lEnabled := n == 1 .AND. ::CurrentForm != NIL .AND. LEN( ::CurrentForm:Selected ) > 1

   FOR i := 1 TO LEN( ::Application:Props[ "AlignBar" ]:Children )-2
      ::Application:Props[ "AlignBar" ]:Children[i]:Enabled := lEnabled
   NEXT

   ::Application:Props[ "TabOrderBttn"  ]:Enabled := n == 1 .AND. ::CurrentForm != NIL .AND. CntChildren( ::CurrentForm ) > 1 .AND. LEN( ::CurrentForm:Selected ) == 1
   ::Application:Props[ "CenterHorBttn" ]:Enabled := lSelected .AND. n == 1
   ::Application:Props[ "CenterVerBttn" ]:Enabled := ::Application:Props[ "CenterHorBttn" ]:Enabled

RETURN NIL

//-------------------------------------------------------------------------------------------------------

METHOD NewProject() CLASS Project
   LOCAL cProject, cPath, cPro, cName, nPro

//   n := 1 - b

   IF ::Properties != NIL .AND. ( ::Properties:Path != NIL .OR. LEN( ::Forms ) > 0 )
      IF ! ::Close()
         RETURN Self
      ENDIF
   ELSEIF ::ProjectFile != NIL
      RETURN Self
   ENDIF
   ::aImages := {}

   ::AppObject := Application():Init( .T. )
   ::AppObject:__ClassInst := __ClsInst( ::AppObject:ClassH )

   ::Application:Props[ "CloseBttn" ]:Enable()   // Close Button
   ::Application:Props[ "RunBttn"   ]:Enable()   // Run Button
   ::Application:AddToProjectMenu:Enabled := .T.

   ::ProjectFile := CFile( "" )
   ::Properties := ProjProp()

   //-----------------------------------------------------
   cPath := ::Application:DefaultFolder

   cPro := "Project"
   nPro := 1
   WHILE FILE( cPath + "\" + cPro + ALLTRIM( STR( nPro ) ) + "\" + cPro + ALLTRIM( STR( nPro ) )+ ".vxh" )
      nPro ++
   ENDDO
   cName := cPro + ALLTRIM( STR( nPro ) )

   ::Properties:Path := cPath + "\" + cName
   ::Properties:Name := cName

   ::Application:ObjectTree:InitProject()

   //-----------------------------------------------------

   ::OpenDesigner(.F.)

   // Code Generation
   cProject := "FUNCTION Main( ... )" + CRLF + CRLF
   cProject += "RETURN NIL" + CRLF

   ::Application:ProjectPrgEditor := Source( ::Application:SourceEditor )
   ::Application:ProjectPrgEditor:SetText( cProject )
   ::Application:ProjectPrgEditor:EmptyUndoBuffer()
   ::Application:ProjectPrgEditor:Modified := .T.

   ::Application:SourceTabs:Visible := .T.
   ::Application:SourceTabs:InsertTab( "  " + ::Properties:Name +"_Main.prg * ",,, .T. )


   ::Application:Props[ "NewFormProjItem"   ]:Enabled := .T.
   ::Application:Props[ "NewFormBttn"       ]:Enabled := .T.
   ::Application:Props[ "NewFormItem"       ]:Enabled := .T.
   ::Application:Props[ "FileOpenItem"      ]:Enabled := .T.
   ::Application:Props[ "CustomControl"     ]:Enabled := .T.
   ::Application:Props[ "BttnCustomControl" ]:Enabled := .T.
   ::Application:Props[ "ResourceManager"   ]:Enabled := .T.

   ::Application:QuickForm:Enable()
   ::Application:FileTree:UpdateView()

   ::Modified := .T.

   ::Application:EditorPage:Select()
   ::Application:SourceEditor:SetFocus()
   ::EditReset(1)
   EVAL( ::Application:MainTab:OnSelChanged, NIL, NIL, 3)

   ::Application:Props[ "ComboSelect" ]:Reset()

   ::Application:ObjectManager:ResetProperties( {{::AppObject}} )
   ::Application:EventManager:ResetEvents( {{::AppObject}} )

RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD SourceTabChanged( nPrev, nCur ) CLASS Project
   ( nPrev )
   IF nCur <= ::Application:SourceEditor:DocCount
      ::Application:SourceEditor:Source := ::Application:SourceEditor:aDocs[ nCur ]
      ::Application:Project:EditReset()
   ENDIF
   OnShowEditors()
RETURN Self

METHOD CheckValidProgram() CLASS Project
   //::Application:SaveMenu:Enable()
   ::Application:SaveAsMenu:Enable()
   ::cFileRemove := NIL
   IF EMPTY( ::Application:SourceEditor:Source:File )
      ::Application:AddSourceMenu:Disable()
      RETURN "Untitled"
    ELSE
      ::Application:CloseMenu:Enable()
      IF ::Properties != NIL
         IF ASCAN( ::Properties:Sources, ::Application:SourceEditor:Source:File ) > 0
            ::Application:AddSourceMenu:Disable()
            ::cSourceRemove := ::Application:SourceEditor:Source:File
            ::Application:RemoveSourceMenu:Enable()
          ELSEIF ASCAN( ::Forms, {|o| o:Editor:File == ::Application:SourceEditor:Source:File } ) > 0 .OR.;
                 ::Application:SourceEditor:Source:File == ::Application:ProjectPrgEditor:File
            ::Application:AddSourceMenu:Disable()
            ::Application:RemoveSourceMenu:Disable()
            ::cSourceRemove := NIL
            ::Application:CloseMenu:Disable()
          ELSE
            ::Application:AddSourceMenu:Enable()
            ::Application:RemoveSourceMenu:Disable()
         ENDIF
      ENDIF
      RETURN ::Application:SourceEditor:Source:FileName
   ENDIF
RETURN ""

//-------------------------------------------------------------------------------------------------------

METHOD AlignRights() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Left := oCtrl:Left + ( oCtrl:Width - ::CurrentForm:Selected[n][1]:Width )
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD AlignLefts() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Left := oCtrl:Left
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem"  ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem"  ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD AlignMiddles() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Top := oCtrl:Top + ( ( oCtrl:Height - ::CurrentForm:Selected[n][1]:Height ) / 2 )
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD AlignCenters() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Left := oCtrl:Left + ( ( oCtrl:Width - ::CurrentForm:Selected[n][1]:Width ) / 2 )
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD AlignTops() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Top := oCtrl:Top
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD AlignBottom() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Top := oCtrl:Top + ( oCtrl:Height - ::CurrentForm:Selected[n][1]:Height )
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD SameWidth() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Width := oCtrl:Width
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD SameHeight() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Height := oCtrl:Height
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD SameSize() CLASS Project
   LOCAL n, oCtrl := ::CurrentForm:Selected[1][1]
   LOCAL aRect := {}, aControls := {}

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 2 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Width  := oCtrl:Width
       ::CurrentForm:Selected[n][1]:Height := oCtrl:Height
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD CenterHorizontally() CLASS Project
   LOCAL x, n, aRect, nDiff, aCurRect := {}, aControls := {}
   aRect := ::CurrentForm:GetSelRect(.T.,.F.,.F.)
   x := aRect[1]
   aRect[1] := ( ::CurrentForm:Selected[1][1]:Parent:ClientWidth / 2 ) - ( ( aRect[3]-aRect[1] ) / 2 )
   nDiff := Int( aRect[1]-x )

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 1 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Left += nDiff
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

METHOD CenterVertically() CLASS Project
   LOCAL x, n, aRect, nDiff, aCurRect := {}, aControls := {}, nTop

   aRect := ::CurrentForm:GetSelRect(.T.,.F.,.F.)
   x := aRect[2]
   nTop := aRect[4]-aRect[2]
   aRect[2] := ( ::CurrentForm:Selected[1][1]:Parent:ClientHeight / 2 ) - ( ( aRect[4]-aRect[2] ) / 2 )
   nDiff := Int( aRect[2]-x )

   ::CurrentForm:__PrevSelRect := {}

   FOR n := 1 TO LEN( ::CurrentForm:Selected )
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( ::CurrentForm:__PrevSelRect, { :Left, :Top, :Width, :Height } )
       END
       ::CurrentForm:Selected[n][1]:Top += nDiff
       ::CurrentForm:Selected[n][1]:MoveWindow()
       WITH OBJECT ::CurrentForm:Selected[n][1]
          AADD( aRect, { :Left, :Top, :Width, :Height } )
       END
       AADD( aControls, ::CurrentForm:Selected[n][1] )
   NEXT
   ::CurrentForm:UpdateSelection()
   AADD( ::aUndo, { DG_MOVESELECTION, aControls, ::CurrentForm:__PrevSelRect, aRect, 1, } )
   ::Application:Props[ "EditUndoItem" ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem" ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self


METHOD TabOrder( oBtn ) CLASS Project
   ::CurrentForm:CtrlMask:lOrderMode       := oBtn:Checked
   ::Application:MainForm:ToolBox1:Enabled := !oBtn:Checked
   ::Application:ObjectTab:Enabled         := !oBtn:Checked
   ::Application:EventManager:Enabled      := !oBtn:Checked
   ::Application:ObjectTree:Enabled        := !oBtn:Checked
   ::Application:FileTree:Enabled          := !oBtn:Checked
   ::Application:FileTree:InvalidateRect()
   ::Application:EnableBars( !oBtn:Checked, .T. )

   IF ::CurrentForm:CtrlMask:lOrderMode
      ::aRealSelection := ACLONE( ::CurrentForm:Selected )
    ELSEIF ::CurrentForm:CurObj != NIL
      ::CurrentForm:Refresh()
      ::CurrentForm:Selected := ACLONE( ::aRealSelection )
      ::aRealSelection := NIL
      IF ::CurrentForm:CurObj != NIL
         ::CurrentForm:CurObj:Parent:__CurrentPos := 1
         ::CurrentForm:CurObj := NIL
      ENDIF
   ENDIF
   WITH OBJECT ::CurrentForm
      :CtrlOldPt := NIL
      IF ::CurrentForm:CtrlMask:lOrderMode
         :InvalidateRect()
       ELSE
         :Refresh()
      ENDIF
      :InRect    := -1
      :CtrlMask:InvalidateRect()
      :CtrlMask:UpdateWindow()
      :UpdateSelection()
   END
RETURN Self

METHOD ImportImages() CLASS Project
   LOCAL oFile, cFile
   oFile := CFile( "" )
   oFile:AddFilter( "Visual xHarbour Project (*.vxh)", "*.vxh" )
   oFile:Flags := OFN_EXPLORER | OFN_FILEMUSTEXIST
   oFile:Path  := ::Application:DefaultFolder
   oFile:OpenDialog()
   IF oFile:Result == IDCANCEL
      RETURN Self
   ENDIF
   IF oFile:Exists
      cFile := oFile:Path + "\" + oFile:Name
      IF ASCAN( ::Properties:ExtImages, {|c| UPPER(c) == UPPER(cFile) } ) == 0
         AADD( ::Properties:ExtImages, cFile )
         ::Modified := .T.
      ENDIF
   ENDIF
RETURN Self

METHOD ImportRes( cSource ) CLASS Project
   LOCAL oFile, cFile
   DEFAULT cSource TO ""
   oFile := CFile( cSource )
   oFile:AddFilter( "Resource File (*.rc)", "*.rc" )
   oFile:Flags := OFN_EXPLORER | OFN_FILEMUSTEXIST
   oFile:Path  := ::Application:DefaultFolder
   oFile:OpenDialog()
   IF oFile:Result == IDCANCEL
      RETURN Self
   ENDIF
   IF oFile:Exists
      cFile := STRTRAN( LOWER( oFile:Name ), ".rc", ".res")
      CreateProcessWait( NIL, "\xHb\bin\xrc.exe " + oFile:Path + "\" + oFile:Name, "rc.log", "" + Chr(0) )
      CreateProcessWait( NIL, "\xHb\bin\xlink.exe " + oFile:Path + "\" + cFile, "rc.log", "" + Chr(0) )
   ENDIF
RETURN Self

METHOD ParseRC( cLine, aUnits ) CLASS Project
   LOCAL n, cName, aRect, cText

   IF ( n := AT( "DIALOG", cLine ) ) > 0
      cName := ALLTRIM( LEFT( cLine, n-1 ) )
      IF cName[1] != "#"
         cText := "{" + SUBSTR( cLine, n + 6 ) + "}"
         aRect := &cText
         WITH OBJECT ::CurrentForm
            :Name    := cName

            :xLeft   := ( aRect[1] * aUnits[1] ) / 4
            :xWidth  := ( aRect[3] * aUnits[2] ) / 8
            :xTop    := ( aRect[2] * aUnits[1] ) / 4
            :xHeight := ( aRect[4] * aUnits[2] ) / 8
            :MoveWindow()

         END
      ENDIF

    ELSEIF ( n := AT( "CAPTION", cLine ) ) > 0
      cText := ALLTRIM( SUBSTR( cLine, n + 7 ) )
      cText := STRTRAN( cText, '"' )
      cText := STRTRAN( cText, "'" )
      ::CurrentForm:Caption := cText

    ELSEIF ( n := AT( "EDITTEXT", cLine ) ) > 0
      aRect := __str2a( cLine, "," )

      ::Application:MainForm:ToolBox1:SetControl( "Edit", , ( VAL(aRect[2])* aUnits[1] ) / 4,;
                                                          ( VAL(aRect[3])* aUnits[2] ) / 8,;
                                                          ::CurrentForm,;
                                                          ( VAL(aRect[4])* aUnits[1] ) / 4,;
                                                          ( VAL(aRect[5])* aUnits[2] ) / 8,;
                                                          .F., , {} )

   ENDIF
RETURN .T.

//-------------------------------------------------------------------------------------------------------

METHOD EditCopy() CLASS Project
   LOCAL aSelection, oCtrl, aCtrlProps
   IF UPPER( GetClassName( GetFocus() ) ) == "EDIT"
      SendMessage( GetFocus(), WM_COPY, 0, 0 )
      RETURN NIL
   ENDIF
   IF ::Application:DesignPage:IsWindowVisible()
      ::CopyBuffer := {}
      FOR EACH aSelection IN ::CurrentForm:Selected
          IF aSelection[1]:__lAllowCopy
             oCtrl      := aSelection[1]
             aCtrlProps := GetCtrlProps( oCtrl, { "LEFT", "TOP", "NAME", "ANCHOR", "DOCK" } )
             AADD( ::CopyBuffer, { oCtrl:__xCtrlName, oCtrl:Left, oCtrl:Top, aCtrlProps, LEN( ::CurrentForm:Selected ), 0 } )
          ENDIF
      NEXT
      ::EditReset(1)
    ELSEIF ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:Source:Copy()
   ENDIF
RETURN 0

STATIC FUNCTION GetCtrlProps( oCtrl, aExclude )
   LOCAL aProps, aProperties, cProp, xValue1, xValue2, aProperty, aSub

   aProps := {}

   aProperties := __ClsGetPropertiesAndValues( oCtrl )
   DEFAULT aExclude TO {}
   FOR EACH aProperty IN aProperties
       cProp := aProperty[1]
       IF cProp != "PARENT" .AND. cProp != "OWNER" .AND. ASCAN( aExclude, cProp ) == 0
          TRY
             xValue1 := __objSendMsg( oCtrl, UPPER( cProp ) )
             xValue2 := __objSendMsg( oCtrl:__ClassInst, UPPER( cProp ) )

             IF !( xValue1 == xValue2 )
                IF ( cProp == "DATASOURCE" .OR. cProp == "IMAGELIST" .OR. cProp == "HOTIMAGELIST" .OR. cProp == "IMAGELISTSMALL" .OR. cProp == "CONTEXTMENU" .OR. cProp == "SOCKET" ) .AND. xValue1 != NIL .AND. xValue1:Name != "CommonImageList" .AND. xValue1:Name != "CommonImageListSmall"
                   AADD( aProps, { cProp, xValue1 } )
                 ELSE
                   IF VALTYPE( xValue1 ) == "O" .AND. cProp != "DOCK"
                      aSub := GetCtrlProps( xValue1 )
                      AADD( aProps, { cProp, aSub } )
                    ELSE
                      AADD( aProps, { cProp, xValue1 } )
                   ENDIF
                ENDIF
             ENDIF
          CATCH
          END
       ENDIF
   NEXT
   TRY
      IF oCtrl:__xCtrlName == "CMenuItem"
         oCtrl:Position := ASCAN( oCtrl:Parent:Children, {|o| o == oCtrl} )
         AADD( aProps, { "POSITION", oCtrl:Position } )
      ENDIF
   CATCH
   END
RETURN aProps

FUNCTION SetCtrlProps( oObj, aProperties )
   LOCAL cProp, aProperty, xValue1
   IF VALTYPE( oObj ) == "O"
      FOR EACH aProperty IN aProperties
         cProp := aProperty[1]
         IF VALTYPE( aProperty[2] ) != "A"
            __objSendMsg( oObj, "_" + aProperty[1], aProperty[2] )
          ELSE
            xValue1 := __objSendMsg( oObj, cProp )
            SetCtrlProps( xValue1, aProperty[2] )
         ENDIF
      NEXT
   ENDIF
RETURN NIL

METHOD EditCut() CLASS Project
   LOCAL aSelection, oCtrl, aCtrlProps

   IF UPPER( GetClassName( GetFocus() ) ) == "EDIT"
      SendMessage( GetFocus(), WM_CUT, 0, 0 )
      RETURN 0
   ENDIF
   IF ::Application:DesignPage:IsWindowVisible()
      ::CopyBuffer := {}
      FOR EACH aSelection IN ::CurrentForm:Selected
          IF aSelection[1]:__lAllowCopy

             oCtrl       := aSelection[1]
             aCtrlProps := GetCtrlProps( oCtrl )

             AADD( ::CopyBuffer, { oCtrl:__xCtrlName, oCtrl:Left, oCtrl:Top, aCtrlProps, LEN( ::CurrentForm:Selected ), 1 } )
             ::SetAction( { { DG_DELCONTROL, NIL, aSelection[1]:Left,;
                                                  aSelection[1]:Top,;
                                                  ::CurrentForm,;
                                                  aSelection[1]:Parent,; //oParent,;
                                                  aSelection[1]:__xCtrlName,;
                                                  aSelection[1],,;
                                                  ::CopyBuffer[-1][5],,, } }, ::aUndo )
          ENDIF
      NEXT

      ::EditReset(1)
    ELSEIF ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:Source:Cut()
      ::Application:SourceEditor:Source:Modified := .T.

      ::Modified := .T.
      ::SetEditMenuItems()
   ENDIF
RETURN 0

METHOD EditPaste() CLASS Project
   IF UPPER( GetClassName( GetFocus() ) ) == "EDIT"
      SendMessage( GetFocus(), WM_PASTE, 0, 0 )
      RETURN 0
   ENDIF
   IF ::Application:DesignPage:IsWindowVisible()
      IF !EMPTY( ::CopyBuffer )
         IF !::PasteOn
            ::PasteOn := .T.
            ::CurrentForm:CtrlMask:SetMouseShape( MCS_PASTE )
         ENDIF
      ENDIF
      ::EditReset(1)
    ELSEIF ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:Source:Paste()
      ::Application:SourceEditor:Source:Modified := .T.

      ::Modified := .T.
      ::SetEditMenuItems()
   ENDIF
RETURN 0

METHOD EditDelete() CLASS Project
   IF UPPER( GetClassName( GetFocus() ) ) == "EDIT"
      SendMessage( GetFocus(), WM_CLEAR, 0, 0 )
      RETURN 0
   ENDIF
   IF ::Application:DesignPage:IsWindowVisible()
      ::CurrentForm:MaskKeyDown(, VK_DELETE )
    ELSEIF ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:SendMessage( WM_KEYDOWN, VK_DELETE )
      ::Application:SourceEditor:Source:Modified := .T.

      ::Modified := .T.
      ::SetEditMenuItems()
   ENDIF
RETURN 0

METHOD Undo() CLASS Project
   IF UPPER( GetClassName( GetFocus() ) ) == "EDIT"
      SendMessage( GetFocus(), WM_UNDO, 0, 0 )
      RETURN 0
   ENDIF

   IF ::Application:DesignPage:IsWindowVisible()
      ::SetAction( ::aUndo, ::aRedo )
    ELSEIF ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:Source:Undo()
   ENDIF
RETURN NIL

METHOD ReDo() CLASS Project
   IF UPPER( GetClassName( GetFocus() ) ) == "EDIT"
      SendMessage( GetFocus(), WM_UNDO, 0, 0 )
      RETURN 0
   ENDIF
   IF ::Application:DesignPage:IsWindowVisible()
      ::SetAction( ::aRedo, ::aUnDo )
    ELSEIF ::Application:SourceEditor:IsWindowVisible()
      ::Application:SourceEditor:Source:Redo()
   ENDIF
RETURN NIL

METHOD SetEditMenuItems() CLASS Project
   ::Application:Props:EditUndoItem:Enabled := ::Application:Props:EditUndoBttn:Enabled := ::Application:SourceEditor:Source:CanUndo()
   ::Application:Props:EditRedoItem:Enabled := ::Application:Props:EditRedoBttn:Enabled := ::Application:SourceEditor:Source:CanRedo()
RETURN Self

METHOD Find() CLASS Project
   IF ::Application:SourceEditor:IsWindowVisible()
      IF ::ReplaceDialog != NIL
         ::ReplaceDialog:Close()
      ENDIF
      ::FindDialog := FindTextDialog( ::Application:SourceEditor )
      ::FindDialog:Owner := ::Application:SourceEditor
      ::FindDialog:Show(, ::Application:SourceEditor:Source:GetSelText() )
   ENDIF
RETURN 0

METHOD Replace() CLASS Project
   IF ::Application:SourceEditor:IsWindowVisible()
      IF ::FindDialog != NIL
         ::FindDialog:Close()
      ENDIF
      IF ::ReplaceDialog != NIL .AND. ::ReplaceDialog:IsWindowVisible()
         ::ReplaceDialog:FindWhat:Caption := ::Application:SourceEditor:Source:GetSelText()
         ::ReplaceDialog:FindWhat:SetFocus()
       ELSE
         ::ReplaceDialog := FindReplace( ::Application:SourceEditor )
      ENDIF
   ENDIF
RETURN 0

//-------------------------------------------------------------------------------------------------------

METHOD SetCaption( lMod ) CLASS Project
   LOCAL cCaption
   ::lModified := lMod

   IF lMod .AND. ::CurrentForm != NIL .AND. procname(3) IN {"PROJECT:SETACTION", "EVENTMANAGER:SETVALUE", "EVENTMANAGER:GENERATEEVENT" }
      ::CurrentForm:__lModified := .T.
   ENDIF

   IF ::Properties == NIL
      #ifdef VXH_DEMO
       cCaption := "Visual xHarbour Demo " + VXH_Version
      #else
       cCaption := "Visual xHarbour " + VXH_Version
      #endif
     ELSE
      #ifdef VXH_DEMO
       IF ::Properties:Name == NIL
          cCaption := "Visual xHarbour Demo [Untitled"
       ELSE
         IF ::Application:IniFile:ReadInteger( "General", "ShowPathInCaption", 1 )==1
            cCaption := "Visual xHarbour Demo [" + ::Properties:Path + "\" + ::Properties:Name + ".vxh"
         ELSE
            cCaption := "Visual xHarbour Demo [" + ::Properties:Name + ".vxh"
         ENDIF
       ENDIF
      #else
       IF ::Properties:Name == NIL
          cCaption := "Visual xHarbour [Untitled"
       ELSE
          IF ::Application:IniFile:ReadInteger( "General", "ShowPathInCaption", 1 )==1
             cCaption := "Visual xHarbour [" + ::Properties:Path + "\" + ::Properties:Name + ".vxh"
          ELSE
             cCaption := "Visual xHarbour [" + ::Properties:Name + ".vxh"
          ENDIF
       ENDIF
      #endif

      cCaption += IIF( lMod," * ]","]" )

      ::Application:Props[ "SaveBttn" ]:Enabled     := lMod
      ::Application:Props[ "SaveItem" ]:Enabled     := lMod
      ::Application:SaveMenu:Enabled                := lMod
      ::Application:Props[ "ProjSaveItem" ]:Enabled := lMod

   ENDIF
   ::Application:MainForm:Caption := cCaption

RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD SelectWindow( oWin, hTree, lFromTab ) CLASS Project
   LOCAL n, oWnd := ::CurrentForm
   DEFAULT hTree TO 0
   DEFAULT lFromTab TO .F.

   IF oWin:Cargo != NIL
      ::LoadForm( oWin:Cargo,,, .T., oWin )
      oWin:Cargo := NIL
      oWin:MoveWindow()
   ENDIF
   ::CurrentForm := oWin

   IF !lFromTab
      n := ASCAN( ::Application:Project:Forms, ::CurrentForm,,, .T. )
      ::Application:FormsTabs:SetCurSel( n )
      ::Application:FormsTabs:InvalidateRect(,.F.)
   ENDIF

   IF oWnd:hWnd != ::CurrentForm:hWnd
      oWnd:Hide()
      ::Application:MainForm:PostMessage( WM_USER + 3001, hTree )
   ENDIF

   ::CurrentForm:Show()
   ::CurrentForm:Validaterect()
   ::CurrentForm:UpdateWindow()
   ::CurrentForm:Redraw()
   ::Application:DoEvents()

   ::CurrentForm:Parent:UpdateScroll()
RETURN 0

//-------------------------------------------------------------------------------------------------------

METHOD SelectBuffer() CLASS Project
   LOCAL n
   ::CurrentForm:Editor:Select()
   IF ( n := aScan( ::Application:SourceEditor:aDocs, {|o| o==::CurrentForm:Editor} ) ) > 0
      ::Application:SourceTabs:SetCurSel( n )
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD OpenDesigner( lSelect ) CLASS Project
   DEFAULT lSelect TO .F.
   ::Application:SourceEditor:Enable()
   ::Application:SourceEditor:Show()
   IF lSelect
      ::Application:DesignPage:Select()
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD AddWindow( lReset, cFileName, lCustom, nPos ) CLASS Project
   LOCAL oWin
   DEFAULT lCustom TO .F.
   oWin := WindowEdit( ::Application:MainForm:FormEditor1, cFileName, lReset, lCustom )

   ::Properties:GUI := .T. // Force GUI so vxh.lib gets linked in

   DEFAULT lReset TO .T.
   
   IF nPos != NIL
      AINS( ::Forms, nPos, oWin, .T. )
    ELSE
      AADD( ::Forms, oWin )
   ENDIF

   WITH OBJECT oWin
      :__ClassInst:Caption := ""
      :Caption     := :Name

      IF lReset // New Window button
         IF ::CurrentForm != NIL
            ::CurrentForm:Hide()
         ENDIF

         :Left        := 10
         :Top         := 10
         :Width       := 300
         :Height      := 300
         :Create()

         ::CurrentForm := oWin

         :Parent:InvalidateRect()

         ::Application:Props[ "ComboSelect" ]:Reset()

         :Parent:RedrawWindow( , , RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW | RDW_INTERNALPAINT | RDW_ALLCHILDREN )
         :UpdateWindow()

         IF !::Application:DesignPage:IsWindowVisible()
            ::Application:DesignPage:Select()
            EVAL( ::Application:MainTab:OnSelChanged, NIL, NIL, 4)
         ENDIF

         ::SelectBuffer()
         ::Modified := .T.
         ::Application:Components:Reset( :this )
         ::Application:ObjectManager:ResetProperties( IIF( EMPTY( :Selected ), {{:this}}, :Selected ) )
         ::Application:EventManager:ResetEvents( IIF( EMPTY( :Selected ), {{:this}}, :Selected ) )
      ENDIF
   END
   IF lReset // New Window button
      ::Application:FileTree:UpdateView()
   ENDIF
RETURN oWin

//-------------------------------------------------------------------------------------------------------

METHOD Close( lCloseErrors, lClosing ) CLASS Project
   LOCAL nRes, n, oMsg, lRem
   DEFAULT lCloseErrors TO .T.
   DEFAULT lClosing TO .F.

   IF ::Modified .AND. !EMPTY( ::Properties ) .AND. lCloseErrors
      nRes := ::Application:MainForm:MessageBox( "Save changes before closing?", IIF( EMPTY(::Properties:Name), "Untitled", ::Properties:Name ), MB_YESNOCANCEL | MB_ICONQUESTION )
      SWITCH nRes
         CASE IDYES
              ::Save(.T.)
              EXIT

         CASE IDCANCEL
              RETURN .F.
      END
   ENDIF

   IF ::lDebugging
      ::DebugStop()
   ENDIF

   lRem := .F.

   ::Application:MainForm:FormEditor1:ResetScroll()

   FOR n := 1 TO ::Application:SourceEditor:DocCount
       IF lCloseErrors
          IF ( ( ::Application:ProjectPrgEditor == NIL .OR. !( ::Application:ProjectPrgEditor == ::Application:SourceEditor:aDocs[n] ) ) .AND. ASCAN( ::Forms, {|o| o:Editor == ::Application:SourceEditor:aDocs[n] } ) == 0 ) .AND.;
               ( EMPTY( ::Application:SourceEditor:aDocs[n]:File ) .OR. ( ::Properties != NIL .AND. ASCAN( ::Properties:Sources, ::Application:SourceEditor:aDocs[n]:File ) == 0 ) )

             IF ::Application:SourceEditor:aDocs[n]:Modified
                IF nRes == NIL .AND. !EMPTY( ::Application:SourceEditor:aDocs[n]:FileName )
                   oMsg := MsgBoxEx( ::Application:MainForm, "Save changes to "+::Application:SourceEditor:aDocs[n]:FileName+" before closing?", "Source File", IDI_QUESTION )
                   nRes := oMsg:Result
                   IF nRes == 4002 // No to All
                      lRem := .T.
                    ELSEIF nRes == 4001 // Yes to All
                      nRes := IDYES
                      lRem := .T.
                   ENDIF
                ENDIF
                SWITCH nRes
                   CASE IDYES
                        IF EMPTY( ::Application:SourceEditor:aDocs[n]:File )
                           ::SaveSourceAs( ::Application:SourceEditor:aDocs[n] )
                         ELSE
                           ::Application:SourceEditor:aDocs[n]:Save()
                        ENDIF
                        EXIT

                   CASE IDCANCEL
                        RETURN .F.
                END
                IF !lRem
                   nRes := NIL
                ENDIF
             ENDIF
             ::Application:SourceEditor:aDocs[n]:Modified := .F.
          ENDIF
       ENDIF
       ::Application:SourceEditor:aDocs[n]:Close()
       ::Application:SourceTabs:DeleteTab(n)
       n--
   NEXT
   ::Application:SourceTabs:Visible := .F.

   FOR n := 1 TO LEN( ::Forms )
       IF ::Forms[n]:Editor != NIL
          ::Forms[n]:Editor:Close()
          ::Forms[n]:Editor := NIL
          ::Forms[n]:Destroy()
       ENDIF
   NEXT
   ::Forms := {}
   ::Application:FormsTabs:DeleteAllTabs()

   IF ::DesignPage == NIL .OR. lClosing
      RETURN .T.
   ENDIF

   ::Application:MainForm:ToolBox1:Disable()

   ::Application:ObjectManager:SetRedraw( .F. )
   ::Application:ObjectManager:ResetContent()
   ::Application:ObjectManager:SetRedraw( .T. )

   WITH OBJECT ::Application:MainForm
      :Label2:Caption := ""
      :Label4:Caption := ""
   END

   ::Application:EventManager:SetRedraw( .F. )
   ::Application:EventManager:ResetContent()
   ::Application:EventManager:SetRedraw( .T. )

   ::Application:ObjectTree:ResetContent()
   ::Application:FileTree:ResetContent()

   ::Application:Props[ "CloseBttn"         ]:Enabled := .F.
   ::Application:Props[ "SaveBttn"          ]:Enabled := .F.
   ::Application:Props[ "RunBttn"           ]:Enabled := .F.
   ::Application:Props[ "ProjSaveItem"      ]:Enabled := .F.
   ::Application:Props[ "ProjBuildItem"     ]:Enabled := .F.
   ::Application:Props[ "ProjRunItem"       ]:Enabled := .F.
   ::Application:Props[ "ForceBuildItem"    ]:Enabled := .F.
   ::Application:Props[ "RunItem"           ]:Enabled := .F.
   ::Application:Props[ "ResourceManager"   ]:Enabled := .F.
   ::Application:Props[ "NewFormBttn"       ]:Enabled := .F.
   ::Application:Props[ "NewFormItem"       ]:Enabled := .F.
   ::Application:Props[ "CustomControl"     ]:Enabled := .F.
   ::Application:Props[ "BttnCustomControl" ]:Enabled := .F.
   ::Application:Props[ "NewFormProjItem"   ]:Enabled := .F.
   ::Application:Props[ "FileOpenItem"      ]:Enabled := .F.

   ::Application:QuickForm:Disable()


   ::Application:AddToProjectMenu:Disable()
   ::Application:SaveMenu:Disable()
   ::Application:SaveAsMenu:Disable()
   ::Application:CloseMenu:Disable()

   #ifdef VXH_DEMO
    ::Application:MainForm:Caption := "Visual xHarbour Demo " + VXH_Version
   #else
    ::Application:MainForm:Caption := "Visual xHarbour " + VXH_Version
   #endif

   ::Application:SourceEditor:Enabled := .F.
   ::Application:SourceEditor:Visible := .F.
   ::Application:DesignPage:Enabled   := .F.
   
   ::Application:Props[ "StartTabPage" ]:Select()
   ::Application:Props[ "ComboSelect" ]:ResetContent()

   ::aUndo := {}
   ::aRedo := {}

   ::Application:Props[ "EditUndoItem"  ]:Enabled := .F.
   ::Application:Props[ "EditUndoBttn"  ]:Enabled := .F.
   ::Application:Props[ "EditRedoItem"  ]:Enabled := .F.
   ::Application:Props[ "EditRedoBttn"  ]:Enabled := .F.

   ::CopyBuffer  := {}
   ::PasteOn     := .F.

   ::DesignPage  := .F.
   ::ProjectFile := NIL
   ::Forms       := {}
   ::Modified    := .F.
   ::Properties  := NIL
   ::Modified    := .F.

   ::CurrentForm := NIL
   
   EVAL( ::Application:MainTab:OnSelChanged, NIL, NIL, 1)
   ::EditReset(1)

   ::Application:SourceEditor:Caption := ""
   IF lCloseErrors
      ::Application:MainForm:DebugBuild1:ResetContent()
      ::Application:DebugWindow:Hide()
      ::Application:Props[ "ViewDebugBuildItem" ]:Checked := .F.
   ENDIF
   ::Application:Components:Close()
   hb_gcall( .T. )
RETURN .T.

//-------------------------------------------------------------------------------------------------------

FUNCTION DeleteFilesAndFolders( cFolder )

   LOCAL n, aDir := directory( cFolder + "\*.*", "D", .F.,.T. )

   FOR n := 1 TO LEN( aDir )
       IF aDir[n][5] != "D"
          FERASE( aDir[n][1] )
        ELSEIF RIGHT( aDir[n][1],1 ) != "."
          DeleteFilesAndFolders( aDir[n][1] )
       ENDIF
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------
METHOD SaveSource( oEditor ) CLASS Project
   DEFAULT oEditor TO ::Application:SourceEditor:Source
   IF EMPTY( oEditor:FileName )
      ::SaveSourceAs( oEditor )
    ELSE
      oEditor:Save()
   ENDIF
   oEditor:Modified := .F.
   OnShowEditors()
RETURN Self

METHOD SaveSourceAs( oEditor, lSetTabName ) CLASS Project
   LOCAL ofn, cFile, n, x
   DEFAULT oEditor TO ::Application:SourceEditor:Source
   DEFAULT lSetTabName TO .F.

   WHILE .T.
      ofn := (struct OPENFILENAME)

      ofn:lStructSize     := 76
      ofn :hwndOwner      := ::Application:MainForm:hWnd
      ofn:hInstance       := GetModuleHandle()
      ofn:nMaxFile        := MAX_PATH + 1

      ofn:lpstrFile       := Space( MAX_PATH )
      ofn:lpstrDefExt     := "prg"
      ofn:lpstrFilter     := "xHarbour source files" + Chr(0) + "*.prg;*.ch;*.xbs;*.xfm" + Chr(0) +;
                             "C sources"             + Chr(0) + "*.c;*.cpp;*.h"          + Chr(0) +;
                             "Resource source file"  + Chr(0) + "*.rc"                   + Chr(0) +;
                             "xBuild project files"  + Chr(0) + "*.xbp;*.inc"            + Chr(0) +;
                             "Log files"             + Chr(0) + "*.log"                  + Chr(0) +;
                             "Text files"            + Chr(0) + "*.txt"                  + Chr(0) +;
                             "All files"             + Chr(0) + "*.*"                    + Chr(0)
      ofn:lpstrTitle      := "Visual xHarbour - Save File As"
      ofn:Flags           := OFN_NOREADONLYRETURN | OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST

      IF GetSaveFileName( @ofn )
         cFile := Left( ofn:lpstrFile, At( Chr(0), ofn:lpstrFile ) - 1 )
         n := ASCAN( ::Application:SourceEditor:aDocs, {|o| o == oEditor} )
         IF ( x := ASCAN( ::Application:SourceEditor:aDocs, {|o| o:File == cFile } ) ) > 0 .AND. x != n
            MessageBox( 0, cFile +" cannot be saved because it's being edited, please select another path and / or name", "Save As", MB_ICONEXCLAMATION )
            ::Application:Yield()
            LOOP
         ENDIF
         oEditor:Save( cFile )
         IF lSetTabName
            ::Application:SourceTabs:SetItem( n, oEditor:FileName )
         ENDIF
      ENDIF
      EXIT
   ENDDO
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD CloseSource() CLASS Project
   LOCAL nRes, n := ::Application:SourceTabs:GetCurSel()
   nRes := IDNO
   IF ::Application:SourceEditor:Source:Modified
      nRes := MessageBox( 0, "Save changes before closing?", ::Application:SourceEditor:Source:FileName, MB_YESNOCANCEL | MB_ICONQUESTION )
      IF nRes == IDCANCEL
         RETURN Self
      ENDIF
   ENDIF
   ::Application:SourceTabs:DeleteTab( n )
   IF nRes == IDYES
      ::SaveSource()
   ENDIF
   ::Application:SourceEditor:Source:Close()
   n := MIN( n, ::Application:SourceEditor:DocCount )
   IF n > 0
      ::Application:SourceTabs:SetCurSel( n )
      ::SourceTabChanged(, n )
    ELSE
      ::Application:SourceEditor:Caption := ""
      ::Application:SourceEditor:Hide()

      ::Application:CloseMenu:Caption := "&Close Project"
      ::Application:CloseMenu:Disable()

      ::Application:SaveMenu:Caption := "Save Project"
      ::Application:SaveMenu:Disable()

      ::Application:SaveAsMenu:Caption := "Save Project &As ..."
      ::Application:SaveAsMenu:Disable()
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD NewSource() CLASS Project
   LOCAL oEditor
   ::Application:SourceEditor:Show()
   ::Application:SourceEditor:Enable()
   oEditor := Source( ::Application:SourceEditor )

   ::Application:SourceTabs:Visible := .T.
   ::Application:SourceTabs:InsertTab( "  Untitled Source * ",,,.T. )
   ::Application:SourceTabs:SetCurSel( ::Application:SourceEditor:DocCount )
   ::SourceTabChanged(, ::Application:SourceEditor:DocCount )
   IF !::Application:SourceEditor:IsWindowVisible()
      ::Application:EditorPage:Select()
   ENDIF
   ::Application:SourceEditor:SetFocus()
   ::Application:CloseMenu:Enable()
   OnShowEditors()
RETURN Self

METHOD OpenSource( cSource ) CLASS Project
   LOCAL oFile, n, oEditor, aFilter
   DEFAULT cSource TO ""
   oFile := CFile( cSource )
   oFile:AddFilter( "Source File (*.prg,*.c,*.cpp,*.rc)", "*.prg;*.c;*.cpp;*.rc" )
   oFile:AddFilter( "Header File (*.ch,*.h)", "*.ch;*.h" )
   oFile:AddFilter( "All Files (*.*)", "*.*" )

   IF !EMPTY( cSource )
      aFilter := { ".prg", ".c", ".cpp", ".rc", ".ch", ".h" }
      n := RAT( ".", cSource )
      IF ASCAN( oFile:Filter, SUBSTR( cSource, n ) ) == 0
         RETURN Self
      ENDIF
   ENDIF

   oFile:Path := ::Application:DefaultFolder
   IF ::ProjectFile != NIL
      oFile:Path := ::ProjectFile:Path
      IF EMPTY( oFile:Path )
         oFile:Path := ::Application:DefaultFolder
      ENDIF
   ENDIF
   IF EMPTY( cSource )
      oFile:Flags := OFN_EXPLORER | OFN_FILEMUSTEXIST
      oFile:OpenDialog()
      ::Application:MainForm:UpdateWindow()
      IF oFile:Result == IDCANCEL
         RETURN Self
      ENDIF
   ENDIF

   IF ( n := ASCAN( ::Application:SourceEditor:aDocs, {|o| lower(o:File) == lower(oFile:Path+"\"+oFile:Name) } ) ) > 0
      // File is open, just re-show

      ::Application:SourceTabs:SetCurSel( n )
      ::SourceTabChanged(, n )

      IF !::Application:SourceEditor:IsWindowVisible()
         ::Application:EditorPage:Select()
      ENDIF
      ::Application:SourceEditor:SetFocus()
      RETURN Self
   ENDIF
   ::Application:SourceEditor:Show()

   oEditor := Source( ::Application:SourceEditor, oFile:Path+"\"+oFile:Name )

   ::Application:SourceTabs:Visible := .T.
   ::Application:SourceTabs:InsertTab( oFile:Name )
   ::Application:SourceTabs:SetCurSel( ::Application:SourceEditor:DocCount )
   ::SourceTabChanged(, ::Application:SourceEditor:DocCount )
   IF !::Application:SourceEditor:IsWindowVisible()
      ::Application:EditorPage:Select()
   ENDIF
   ::Application:SourceEditor:SetFocus()
   ::Application:SourceEditor:Enable()
   OnShowEditors()
RETURN Self

METHOD AddSource( cFile ) CLASS Project
   IF cFile != NIL
      ::OpenSource( cFile )
   ENDIF
   DEFAULT cFile TO ::Application:SourceEditor:Source:File
   AADD( ::Properties:Sources, cFile )
   ::Application:RemoveSourceMenu:Enable()
   ::Application:AddSourceMenu:Disable()
   ::Application:FileTree:UpdateView()
   ::Modified := .T.
RETURN Self

METHOD RemoveSource() CLASS Project
   LOCAL n
   IF ::cFileRemove != NIL
      IF ( n := ASCAN( ::Properties:Binaries, ::cFileRemove ) ) > 0
         ADEL( ::Properties:Binaries, n, .T. )
      ENDIF
    ELSE
      IF ( n := ASCAN( ::Properties:Sources, ::cSourceRemove ) ) > 0
         ADEL( ::Properties:Sources, n, .T. )
      ENDIF
   ENDIF
   ::cFileRemove   := NIL
   ::cSourceRemove := NIL
   ::Application:RemoveSourceMenu:Disable()
   ::Application:FileTree:UpdateView()
   ::Modified := .T.
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD AddBinary( cFile ) CLASS Project
   LOCAL oFile, n, c
   IF cFile == NIL
      oFile := CFile( NIL )
      oFile:AddFilter( "Binary Files (*.lib,*.obj)", "*.lib;*.obj" )
      oFile:Path := SPACE(256)
      oFile:Name := SPACE(256)
      oFile:OpenDialog()
      IF oFile:Result == IDCANCEL
         RETURN Self
      ENDIF
      cFile := oFile:Path + "\" + oFile:Name
   ENDIF
   ::Application:MainForm:UpdateWindow()
   IF ASCAN( ::Properties:Binaries, cFile ) > 0
      ::Application:MainForm:MessageBox( "The File " + cFile + " is already part of the project", "Add Binary", MB_ICONEXCLAMATION )
      RETURN Self
   ENDIF

   c := cFile
   IF ( n := RAT( "\", cFile ) ) > 0
      c := SUBSTR( cFile, n+1 )
   ENDIF

   IF UPPER( c ) == "VXH.LIB" //.OR. UPPER( c ) == "ACTIVEX.LIB"
      ::Application:MainForm:MessageBox( "The File " + cFile + " is a system file and it's already part of the project", "Add Binary", MB_ICONEXCLAMATION )
      RETURN Self
   ENDIF

   AADD( ::Properties:Binaries, cFile )
   ::Application:FileTree:UpdateView()
   ::Modified := .T.
   ::Application:FileTree:ExpandAll()

RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD Open( cProject ) CLASS Project

   EXTERN MDIChildWindow

   LOCAL n, Xfm, aChildren
   LOCAL hFile, cLine, oEditor, cSource, oProject, cFile, nLine, aErrors, aEditors, cProp, cSourcePath, oWait

   IF cProject != NIL .AND. !FILE( cProject )
      MessageBox( GetActiveWindow(), "File Not Found", "Open Project", MB_ICONEXCLAMATION )
      ::ResetQuickOpen( cProject )
      RETURN Self
   ENDIF
   
   IF ::Application:DebugWindow:Visible
      ::Application:ErrorView:ResetContent()
      ::Application:DebugWindow:Visible := .F.
      ::Application:Props[ "ViewDebugBuildItem" ]:Checked := .F.
   ENDIF

   DEFAULT cProject TO ""
   oProject := CFile( cProject )

   IF EMPTY( cProject )
      oProject:AddFilter( "Visual-xHarbour (*.vxh)", "*.vxh" )

      oProject:OpenDialog()

      ::Application:MainForm:UpdateWindow()

      IF oProject:Result == IDCANCEL .OR. !FILE( oProject:Path + "\" + oProject:Name )
         RETURN Self
      ENDIF

      IF ::ProjectFile != NIL
         IF !::Close()
            RETURN Self
         ENDIF
      ENDIF
      ::ProjectFile := oProject
    ELSE
      IF ::ProjectFile != NIL
         IF !::Close()
            RETURN Self
         ENDIF
      ENDIF
      ::ProjectFile := oProject
      IF ( n := RAT( "\", cProject ) ) == 0
         ::ProjectFile:Path := LEFT( cProject, n - 1 )
         ::ProjectFile:Name := SUBSTR( cProject, n + 1 )
       ELSE
         ::ProjectFile:Path := LEFT( cProject, n - 1 )
         ::ProjectFile:Name := SUBSTR( cProject, n + 1 )
      ENDIF

   ENDIF
   
   oWait := ::Application:MainForm:MessageWait( ::ProjectFile:Path + "\" + ::ProjectFile:Name, "Loading project", .T. )
   
   ::Application:Cursor := ::System:Cursor:Busy
   SetCursor( ::Application:Cursor )

   ::aImages := {}

   ::Properties := ProjProp( ::ProjectFile:Path + "\" + ::ProjectFile:Name )

   // Open Project.prg
   cSourcePath := ::Properties:Path + "\" + ::Properties:Source

   IF !FILE( cSourcePath +"\" + ::Properties:Name +"_Main.prg" )

      n := ::Application:MainForm:MessageBox( ::Properties:Name + " was created with a previous version of Visual xHarbour, would you like to convert it to the current version", "Open Project", MB_ICONQUESTION | MB_YESNOCANCEL )
      DO CASE
         CASE n == IDYES
              FRENAME( cSourcePath +"\" + ::Properties:Name +".prg", cSourcePath +"\" + ::Properties:Name +"_Main.prg" )
      ENDCASE
      oWait:Position := 10
   ENDIF
   IF FILE( cSourcePath +"\" + ::Properties:Name +"_Main.prg" )
      ::Application:ProjectPrgEditor := Source( ::Application:SourceEditor )
      ::Application:ProjectPrgEditor:Open( cSourcePath +"\" + ::Properties:Name +"_Main.prg" )

      ::Application:SourceTabs:InsertTab( ::Properties:Name +"_Main.prg" )

    ELSEIF ::Properties:TargetType == 1
      n := ::Application:MainForm:MessageBox( "Mising main file " + cSourcePath +"\" + ::Properties:Name +"_Main.prg", "Open Project", MB_ICONQUESTION | MB_OKCANCEL )
      IF n == IDCANCEL
         ::Close()
         oWait:Close()
         RETURN .F.
      ENDIF
   ENDIF
   oWait:Position := 20

   ::OpenDesigner()
   ::Application:MainForm:ToolBox1:Enabled := .T.

   ::Application:SourceTabs:Visible := .T.

   ::Application:AddToProjectMenu:Enabled := .T.
   ::Application:QuickForm:Enable()

   ::Application:Props[ "RunBttn"           ]:Enabled := .T.
   ::Application:Props[ "ResourceManager"   ]:Enabled := .T.
   ::Application:Props[ "RunItem"           ]:Enabled := .T.
   ::Application:Props[ "RunBttn"           ]:Enabled := .T.
   ::Application:Props[ "NewFormBttn"       ]:Enabled := .T.
   ::Application:Props[ "NewFormItem"       ]:Enabled := .T.
   ::Application:Props[ "CustomControl"     ]:Enabled := .T.
   ::Application:Props[ "BttnCustomControl" ]:Enabled := .T.
   ::Application:Props[ "NewFormProjItem"   ]:Enabled := .T.
   ::Application:Props[ "FileOpenItem"      ]:Enabled := .T.
   ::Application:Props[ "CloseBttn"         ]:Enabled := .T.
   ::Application:Props[ "SaveBttn"          ]:Enabled := .T.
   ::Application:Props[ "ForceBuildItem"    ]:Enabled := .T.

   ::Application:MainForm:StatusBarPanel2:Caption := "Loading " + ::Properties:Path + "\" + ::Properties:Name

   aErrors     := {}

   ::AppObject := Application():Init( .T. )
   ::AppObject:__ClassInst := __ClsInst( ::AppObject:ClassH )
   ::Application:ObjectTree:InitProject()

   ::Modified := .F.
   oWait:Position := 30

   IF FILE( cSourcePath +"\" + ::Properties:Name +"_XFM.prg" )
      Xfm         := cSourcePath +"\" + ::Properties:Name +"_XFM.prg"
      hFile       := FOpen( Xfm, FO_READ )
      nLine       := 1
      aChildren   := {}
      WHILE HB_FReadLine( hFile, @cLine, XFM_EOL ) == 0
         ::ParseXFM(, cLine, hFile, @aChildren, cFile, @nLine, @aErrors, @aEditors )
         hb_gcall()
         nLine++
      END
      oWait:Position := 40
      FClose( hFile )
   ENDIF

   aEditors := {}

   FOR EACH Xfm IN ::Properties:Files
       IF ! ::LoadForm( Xfm, @aErrors, @aEditors, HB_EnumIndex()==1 )
          MessageBox( GetActiveWindow(), "The File " + Xfm + " is missing, the project will now close", "Visual xHarbour - Open Project", MB_ICONERROR )
          ::Application:Cursor := NIL
          oWait:Close()
          RETURN ::Close()
       ENDIF
   NEXT
   oWait:Position := 60

   ::Application:SourceTabs:Visible := .T.
   FOR EACH cSource IN ::Properties:Sources
       n := RAT( "\", cSource )
       IF FILE( cSource )
          oEditor := Source( ::Application:SourceEditor )
          oEditor:Open( cSource )

          ::Application:SourceTabs:InsertTab( SUBSTR( cSource, n+1 ) )
          ::Application:SourceTabs:SetCurSel( ::Application:SourceEditor:DocCount )
          ::SourceTabChanged(, ::Application:SourceEditor:DocCount )
        ELSE
          AADD( aErrors, { ::Properties:Name, "0", "Open error: " + cSource, "I/O Error"} )
       ENDIF
   NEXT
   oWait:Position := 80

   IF !EMPTY( aErrors )
      ::Application:DebugWindow:Show()
      ::Application:Props[ "ViewDebugBuildItem" ]:Checked := .T.
      ::Application:ErrorView:ProcessErrors( , aErrors )
      ::Application:ErrorView:Parent:Select()
      ::Application:Yield()
      ::Application:Cursor := NIL
      //::Application:MainForm:MessageBox( "Error(s) loading " + cProject + CHR(13) + "See errors log", "Project closed", MB_ICONSTOP )
      oWait:Close()
      RETURN ::Close(.F.)
   ENDIF

   // Initialize everything !!!!!
   IF LEN( ::Forms ) > 0
      ::CurrentForm := ::Forms[1]

      ::SelectBuffer()
      IF ::CurrentForm != NIL
         ::CheckValidProgram()
         ::Application:DesignPage:Select()

         oWait:Position := 90

         IF ::CurrentForm:MDIContainer
            cProp := ::CurrentForm:MDIClient:AlignLeft
            IF VALTYPE( cProp ) == "C" .AND. ( n := ASCAN( ::CurrentForm:Children, {|o| o:Name == cProp } ) ) > 0
               ::CurrentForm:MDIClient:AlignLeft := ::CurrentForm:Children[n]
            ENDIF

            cProp := ::CurrentForm:MDIClient:AlignTop
            IF VALTYPE( cProp ) == "C" .AND. ( n := ASCAN( ::CurrentForm:Children, {|o| o:Name == cProp } ) ) > 0
               ::CurrentForm:MDIClient:AlignTop := ::CurrentForm:Children[n]
            ENDIF

            cProp := ::CurrentForm:MDIClient:AlignRight
            IF VALTYPE( cProp ) == "C" .AND. ( n := ASCAN( ::CurrentForm:Children, {|o| o:Name == cProp } ) ) > 0
               ::CurrentForm:MDIClient:AlignRight := ::CurrentForm:Children[n]
            ENDIF

            cProp := ::CurrentForm:MDIClient:AlignBottom
            IF VALTYPE( cProp ) == "C" .AND. ( n := ASCAN( ::CurrentForm:Children, {|o| o:Name == cProp } ) ) > 0
               ::CurrentForm:MDIClient:AlignBottom := ::CurrentForm:Children[n]
            ENDIF

            IF VALTYPE( ::CurrentForm:MDIClient:AlignLeft ) == "O"
               ::CurrentForm:LeftMargin := ::CurrentForm:MDIClient:AlignLeft:Left + ::CurrentForm:MDIClient:AlignLeft:Width
            ENDIF
            IF VALTYPE( ::CurrentForm:MDIClient:AlignTop ) == "O"
               ::CurrentForm:TopMargin := ::CurrentForm:MDIClient:AlignTop:Top + ::CurrentForm:MDIClient:AlignTop:Height
            ENDIF
            IF VALTYPE( ::CurrentForm:MDIClient:AlignRight ) == "O"
               ::CurrentForm:RightMargin := ::CurrentForm:MDIClient:AlignRight:Left
            ENDIF
            IF VALTYPE( ::CurrentForm:MDIClient:AlignBottom ) == "O"
               ::CurrentForm:BottomMargin := ::CurrentForm:MDIClient:AlignBottom:Top
            ENDIF

            MoveWindow( ::CurrentForm:MDIClient:hWnd, ::CurrentForm:LeftMargin,;
                                                      ::CurrentForm:TopMargin,;
                                                      ::CurrentForm:RightMargin - ::CurrentForm:LeftMargin,;
                                                      ::CurrentForm:BottomMargin - ::CurrentForm:TopMargin, .T.)
         ENDIF

         ::CurrentForm:Show():UpdateWindow()

         ::Application:Components:Reset( ::CurrentForm )
         ::Application:FormsTabs:SetCurSel(1)
         ::Application:Props[ "ComboSelect" ]:Reset()

         ::Application:ObjectManager:ResetProperties({{ ::CurrentForm }})
         ::Application:EventManager:ResetEvents({{ ::CurrentForm }})

         ::EditReset(1)
      ENDIF

      ::Application:MainForm:StatusBarPanel2:Caption := ""
      IF ::CurrentForm == NIL
         MessageBox( GetActiveWindow(), "The project file "+::ProjectFile:Name+" appears to be corrupted or it's not a Visual xHarbour project file", "Visual xHarbour - Open Project", MB_ICONERROR )
         ::Application:Cursor := NIL
         RETURN ::Close()
      ENDIF
    ELSEIF EMPTY( ::Application:ProjectPrgEditor )
      MessageBox( GetActiveWindow(), "The project file "+::ProjectFile:Name+" appears to be corrupted or it's not a Visual xHarbour project file", "Visual xHarbour - Open Project", MB_ICONERROR )
      ::Close()
    ELSE
      ::Application:Props[ "ComboSelect" ]:Reset()

      ::Application:ObjectManager:ResetProperties( {{::AppObject}} )
      ::Application:EventManager:ResetEvents( {{::AppObject}} )

      ::Application:EditorPage:Select()
   ENDIF
   oWait:Position := 100

   ::Application:FileTree:UpdateView()
   ::ResetQuickOpen( ::ProjectFile:Path + "\" + ::ProjectFile:Name )
   IF LEN( ::Forms ) > 0 .AND. !FILE( cSourcePath +"\" + ::Properties:Name +"_XFM.prg" )
      n := ::Application:MainForm:MessageBox( ::Properties:Name + " was created with a previous version of Visual xHarbour, would you like to convert it to current version", "Open Project", MB_ICONQUESTION | MB_YESNOCANCEL )
      DO CASE
         CASE n == IDYES
              ::Application:ProjectPrgEditor:lModified := .T.
              ::Save( .T. )
              IF FILE( cSourcePath +"\" + ::Properties:Name +".xfm" )
                 FERASE( cSourcePath +"\" + ::Properties:Name +".xfm" )
              ENDIF

         CASE n == IDCANCEL
              ::Close()
      ENDCASE
   ENDIF
   EVAL( ::Application:MainTab:OnSelChanged, NIL, NIL, IIF( LEN( ::Forms ) > 0, 4, 3 ) )
   ::Application:Cursor := NIL
   SetCursor( ::System:Cursor:Arrow )
   ::Built := .F.
   oWait:Close()
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD LoadUnloadedImages( cFile ) CLASS Project
   LOCAL n, aImage, cLine, hFile := FOpen( cFile, FO_READ )
   WHILE HB_FReadLine( hFile, @cLine, XFM_EOL ) == 0
      cLine := ALLTRIM( cLine )
      IF UPPER( LEFT( cLine, 6 ) ) == "::ICON" .OR. UPPER( LEFT( cLine, 10 ) ) == ":IMAGENAME" 
         IF ( n := AT( "{", cLine ) ) > 0
            aImage := &(SUBSTR( cLine, n ))
            IF ASCAN( ::aImages, {|a| a[2] == aImage[2] } ) == 0
               AADD( ::aImages, { aImage[1], aImage[2], UPPER(RIGHT(aImage[1],3)), NIL } )
            ENDIF
         ENDIF
       ELSEIF UPPER( cLine ) HAS "(?i)^:ADDIMAGE\("
         cLine := STRTRAN( cLine, ":AddImage(" )
         cLine := STRTRAN( cLine, ")" )
         aImage := hb_aTokens( cLine, "," )
         IF ASCAN( ::aImages, {|a| a[2] == &(aImage[1]) } ) == 0
            AADD( ::aImages, { &(aImage[6]), &(aImage[1]), UPPER(RIGHT(&(aImage[6]),3)), NIL } )
         ENDIF
      ENDIF
   ENDDO
   FClose( hFile )
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD LoadForm( cFile, aErrors, aEditors, lLoadProps, oForm ) CLASS Project
   LOCAL cObjectName, cXfm, cLine, nLine, aChildren, hFile, cClassName, aTokens, cBkMk
   LOCAL cSourcePath := ::Properties:Path + "\" + ::Properties:Source
   cXfm := cSourcePath +"\" + cFile
   DEFAULT lLoadProps TO .T.

   hFile := FOpen( cXfm, FO_READ )
   IF hFile == -1
      RETURN .F.
   ENDIF
   nLine       := 1
   aChildren   := {}
   cObjectName := Token( cFile, ".", 1 )
   cClassName  := ""

   WHILE HB_FReadLine( hFile, @cLine, XFM_EOL ) == 0
      IF cLine HAS "(?i)^CLASS +[_A-Z|a-z|0-9]+ +INHERIT +"
         aTokens     := HB_aTokens( cLine )
         cClassName  := UPPER( aTokens[-1] )
         cObjectName := aTokens[2]
         EXIT
      ENDIF
   ENDDO
   FSeek( hFile, 0, 0 )
   
   IF oForm == NIL
      oForm := ::AddWindow( .F., cObjectName + ".prg", cClassName == "CUSTOMCONTROL" )
      cBkMk := GetPrivateProfileString( "Files", cFile, "", ::Properties:Path + "\" + ::Properties:Name + ".vxh")

      ::CurrentForm := oForm
      cSourcePath := ::Properties:Path + "\" + ::Properties:Source

      ::Application:SourceEditor:Source := oForm:Editor
      oForm:Editor:Open( cSourcePath + "\" + cObjectName + ".prg", cBkMk )
   ENDIF

   IF lLoadProps
      nLine := 1
      DEFAULT aErrors  TO {}
      DEFAULT aEditors TO {}
      hb_gcall()
      WHILE HB_FReadLine( hFile, @cLine, XFM_EOL ) == 0
         ::ParseXFM( oForm, cLine, hFile, @aChildren, cFile, @nLine, @aErrors, @aEditors )
         nLine++
      END
    ELSEIF aErrors != NIL
      oForm:Name := cObjectName
      oForm:Cargo := cFile
      ::Application:FormsTabs:InsertTab( cObjectName,,, .F. )
   ENDIF
   FClose( hFile )
RETURN .T.

//-------------------------------------------------------------------------------------------------------
METHOD ParseXFM( oForm, cLine, hFile, aChildren, cFile, nLine, aErrors, aEditors, oCC, lCustomOwner ) CLASS Project
   LOCAL oErr, nRead, nPos, n, cParent, lFound, hPtr
   LOCAL aTokens, nTokens, nToken, Topic, Event
   LOCAL cClassName, cObjectName, oParent, cEvent, cHandler, cProperty, cValue, xValue
   LOCAL cWithClassName, cWithProperty, cWithEvent, cWithHandler, cWithValue
   LOCAL aoWithObjects := {}, cPropertyObject, lDialog := .F.
   LOCAL oObj, oPrev
   ( aEditors )

   DEFAULT lCustomOwner TO .F.
   TRY
      cLine := AllTrim( cLine )

      IF Empty( cLine ) .OR. cLine = "//"
         BREAK
      ENDIF

      IF cLine HAS "(?i)^CLASS +[_A-Z|a-z|0-9]+ +INHERIT +"
         aTokens := HB_aTokens( cLine )

         cClassName   := UPPER( aTokens[-1] )
         cObjectName  := aTokens[2]
         IF cClassName == "FORM"
            cClassName := "WINFORM"
         ENDIF
         IF cClassName == "DIALOG"
            cClassName := "WINFORM"
            lDialog := .T.
         ENDIF
         IF cClassName == "FORM"
            cClassName := "WINFORM"
         ENDIF
         IF cClassName == "WINDOW" .OR. cClassName == "MDICHILDWINDOW" .OR. cClassName == "WINFORM" .OR. cClassName == "FORM" .OR. cClassName == "CUSTOMCONTROL"
            IF oCC != NIL
               oObj := oCC
             ELSEIF oForm != NIL
               // Initialize Form Designer
               oObj := oForm
               AADD( aChildren, { cObjectName, oForm } )
            ENDIF
          ELSEIF cClassName == "APPLICATION"
            oObj := ::AppObject
          ELSE
            // Find corresponding parent based on Prefix
            n := RAT( "_", cObjectName )
            cParent := LEFT( cObjectName, n-1 )
            nPos := ASCAN( aChildren, {|a| a[1]==cParent} )

            // Initialize Container Control
            oObj := &cClassName( aChildren[nPos][2] )
            AADD( aChildren, { cObjectName, oObj } )
         ENDIF

         WHILE ( nRead := HB_FReadLine( hFile, @cLine, XFM_EOL ) ) == 0
            nLine++
            cLine := AllTrim( cLine )

            IF UPPER( LEFT( ALLTRIM( cLine ), 4 ) ) == "VAR "
               oObj:UserVariables := ALLTRIM( SUBSTR( cLine, 5 ) )
               LOOP
            ENDIF

            IF cLine LIKE "(?i)^METHOD +Init\( *oParent *\) +CLASS +" + cObjectName
               EXIT
            ENDIF
            IF cLine LIKE "(?i)^METHOD +Init\( *oParent, aParameters *\) +CLASS +" + cObjectName
               EXIT
            ENDIF
            IF cLine HAS "(?i)aParameters"
               EXIT
            ENDIF

         END

         IF nRead != 0
            TraceLog( hFile, nRead, cLine )
            Throw( ErrorNew( "VXH Loader", 0, 1001, "Could not locate INIT Method of Class: " + cObjectName, "", HB_aParams() ) )
         ENDIF

         WHILE ( nRead := HB_FReadLine( hFile, @cLine, XFM_EOL ) ) == 0
            nLine++
            cLine := AllTrim( cLine )

            IF Empty( cLine ) .OR. cLine = "//"
               LOOP
            ENDIF

            IF cLine HAS "(?i)ENDCLASS"
               EXIT
            ENDIF

            aTokens := HB_aTokens( cLine )
            nTokens := Len( aTokens )
            FOR nToken := 1 TO nTokens
               IF Empty( aTokens[nToken] )
                  aDel( aTokens, nToken, .T. )
                  nToken--
                  nTokens--
               ENDIF
            NEXT

            IF cLine HAS "(?i)^::EventHandler\["
               IF oCC == NIL
                  // Handle Eevents.
                  cEvent := SubStr( aTokens[2], 2, Len( aTokens[2] ) - 2 )
                  cHandler := SubStr( aTokens[5], 2, Len( aTokens[5] ) - 2 )

                  lFound := .F.
                  FOR EACH Topic IN oObj:Events
                      FOR EACH Event IN Topic[2]
                          IF Event[1] == cEvent
                             Event[2] := cHandler
                             lFound := .T.
                             EXIT
                          ENDIF
                      NEXT
                      IF lFound
                         EXIT
                      ENDIF
                  NEXT
               ENDIF
            ELSEIF cLine HAS "(?i)^::Show\(\)"
               // Skip Show command

            ELSEIF cLine HAS "(?i)^::[A-Z|a-z|0-9_]+ *:= *[A-Z|a-z|0-9|_]+\("
               // Skip call to containers.

            ELSEIF cLine HAS "(?i)^::[A-Z|a-z|0-9]+ *:="
               // Handle Properties.
               cProperty := SubStr( aTokens[1], 3 )
               nPos := AT( aTokens[ 3 ], cLine )
               cValue    := SUBSTR( cLine, nPos )

               IF !__objHasMsg( oObj, cProperty )
                  Throw( ErrorNew( "BASE", EG_NOVARMETHOD, 1005, oObj:Name + ":" + cProperty, "INVALID PROPERTY NAME", {xValue} ) )
               ENDIF

               IF UPPER( LEFT( cValue, 23 ) ) == "APPLICATION:MAINWINDOW:"
                  cValue := STRTRAN( cValue, "Application:MainWindow:" )
                  xValue := ::Forms[1]:Property[ cValue ]

                ELSEIF UPPER( LEFT( cValue, 21 ) ) == "APPLICATION:MAINFORM:"
                  cValue := STRTRAN( cValue, "Application:MainForm:" )
                  xValue := ::Forms[1]:Property[ cValue ]

                ELSEIF UPPER( LEFT( cValue, 17 ) ) == "SYSTEM:IMAGELIST:"
                  cValue := SUBSTR( cValue, 18 )
                  xValue := ::System:ImageList[ cValue ]



                ELSEIF UPPER( LEFT( cValue, 25 ) ) == "::APPLICATION:MAINWINDOW:"
                  cValue := STRTRAN( cValue, "::Application:MainWindow:" )
                  xValue := ::Forms[1]:Property[ cValue ]

                ELSEIF UPPER( LEFT( cValue, 23 ) ) == "::APPLICATION:MAINFORM:"
                  cValue := STRTRAN( cValue, "::Application:MainForm:" )
                  xValue := ::Forms[1]:Property[ cValue ]

                ELSEIF UPPER( LEFT( cValue, 19 ) ) == "::SYSTEM:IMAGELIST:"
                  cValue := SUBSTR( cValue, 20 )
                  xValue := ::System:ImageList[ cValue ]

                ELSEIF LEFT( cValue, 2 ) == "::"
                  cValue := SUBSTR( cValue, 3 )
                  xValue := oObj:Property[ cValue ]

                ELSE
                  xValue := &cValue
               ENDIF
               __objSendMsg( oObj, "_" + cProperty, xValue )

            ELSEIF cLine HAS "(?i)^::Create\(\)"
               // Create Container / Form
               IF oCC == NIL
                  oObj:Create()
               ENDIF
            ELSEIF cLine HAS "(?i)^WITH OBJECT +::"
               // Generate object type PROPERTY for CLASS
               cPropertyObject := SubStr( aTokens[3], 3 )
               IF oObj:HasMessage( cPropertyObject )
                  oObj := oObj:&cPropertyObject
                ELSE
                  oPrev := oObj
                  oObj  := oForm:Property[ cPropertyObject ]
               ENDIF

            ELSEIF cLine HAS "(?i)^END"
               // Finish object type PROPERTY / Control, return to previous parent
               IF __clsParent( oObj:ClassH, "COMPONENT" ) .OR. UPPER( oObj:ClsName ) IN { "ANCHOR", "DOCK", "FREEIMAGERENDERER" }
                  oObj := oObj:Owner
                ELSE
                  TRY
                     oObj := IIF( UPPER( oObj:__xCtrlName ) == "OPTIONBARBUTTON", oObj:Parent:Parent, oObj:Parent )
                  CATCH
                     oObj := oObj:Parent
                  END
                  IF oPrev != NIL
                     oObj := oPrev
                     oPrev := NIL
                  ENDIF
               ENDIF

            ELSEIF cLine HAS "(?i)^WITH OBJECT +\("
               // Handle WITH OBJECT property

               IF LEFT( aTokens[4], 2 ) == "::"
                  cWithClassName := Left( aTokens[6], Len( aTokens[6] ) - 1 )
                ELSE
                  cWithClassName := Left( aTokens[4], Len( aTokens[4] ) - 1 )
               ENDIF

               IF UPPER( cWithClassName ) == "EDIT"
                  cWithClassName := "EditBox"
                ELSEIF UPPER( cWithClassName ) == "PICTURE"
                  cWithClassName := "PictureBox"
               ENDIF

               IF ASCAN( ::Application:CControls, {|c| UPPER( STRTRAN( SplitFile(c)[2], ".xfm" ) ) == cWithClassName} ) > 0
                  oParent := oObj
                  oObj := CustomControl()
                  oObj:__xCtrlName := cWithClassName
                  oObj:Init( oParent )
                ELSE
                  TRY
                     oObj := &cWithClassName( oObj )
                     oObj:__CustomOwner := lCustomOwner
                  CATCH
                     WITH OBJECT OpenFileDialog( ::Application:MainForm )
                        :CheckFileExists := .T.
                        :Multiselect     := .F.
                        :DefaultExt      := "xfm"
                        :Title           := "Missing File " + cWithClassName
                        :Filter := "Visual xHarbour Form (*.xfm)|*.xfm"
                        IF :Show()
                           cWithClassName := STRTRAN( SplitFile( :FileName )[2], ".xfm" )

                           oParent := oObj
                           oObj := CustomControl()
                           oObj:__xCtrlName := cWithClassName
                           oObj:Init( oParent, :FileName )
                        ENDIF
                     END
                  END
               ENDIF

               IF UPPER( cWithClassName ) == "TABPAGE"
                  oObj:BackgroundImage := FreeImageRenderer( oObj )
               ENDIF

            ELSEIF UPPER( cLine ) HAS "(?i)^:EVENTHANDLER\["

               IF oCC == NIL .AND. oObj:ClsName != "CCTL"
                  // Handle WITH OBJECT Events.
                  cWithEvent   := SubStr( aTokens[2], 2, Len( aTokens[2] ) - 2 )
                  cWithHandler := SubStr( aTokens[5], 2, Len( aTokens[5] ) - 2 )

                  IF oObj:ClsName == "AtlAxWin" .AND. oObj:Events == NIL
                     oObj:__GetEventList(.F.)
                     oObj:__LoadEvents := .F.
                  ENDIF

                  lFound := .F.
                  FOR EACH Topic IN IIF( oObj:ClsName == "ToolButton" .AND. oObj:IsMenuItem .AND. oObj:Item!=NIL, oObj:Item:Events, oObj:Events )
                      FOR EACH Event IN Topic[2]
                          IF Event[1] == cWithEvent
                             Event[2] := cWithHandler
                             lFound := .T.
                             EXIT
                          ENDIF
                      NEXT
                      IF lFound
                         EXIT
                      ENDIF
                  NEXT
               ENDIF
            ELSEIF cLine HAS "(?i)^:[A-Z|a-z|0-9]+ *:="
               // Handle WITH OBJECT Properties.
               cWithProperty := SubStr( aTokens[1], 2 )
               nPos := AT( aTokens[ 3 ], cLine )
               cWithValue    := SUBSTR( cLine, nPos )

               IF UPPER( LEFT( cWithValue, 14 ) ) == ":OWNER:PARENT:"
                  cWithValue := STRTRAN( cWithValue, ":Owner:Parent:" )
                  n := ASCAN( oObj:Owner:Parent:Children, {|o| o:Name == cWithValue } )
                  //xValue := oObj:Owner:Parent:&cWithValue
                  IF n > 0
                     xValue := oObj:Owner:Parent:Children[n]
                   ELSE
                     xValue := cWithValue
                  ENDIF

                ELSEIF UPPER( LEFT( cWithValue, 13 ) ) == ":OWNER:PARENT"
                  cWithValue := STRTRAN( cWithValue, ":Owner:Parent" )
                  xValue := oObj:Owner:Parent

                ELSEIF UPPER( LEFT( cWithValue, 19 ) ) == "::SYSTEM:IMAGELIST:"
                  cWithValue := SUBSTR( cWithValue, 20 )
                  xValue := ::System:ImageList[ cWithValue ]

                ELSEIF UPPER( LEFT( cWithValue, 25 ) ) == "::APPLICATION:MAINWINDOW:"
                  cWithValue := STRTRAN( cWithValue, "::Application:MainWindow:" )
                  xValue := ::Forms[1]:Property[ cWithValue ]

                ELSEIF UPPER( LEFT( cWithValue, 23 ) ) == "::APPLICATION:MAINFORM:"
                  cWithValue := STRTRAN( cWithValue, "::Application:MainForm:" )
                  xValue := ::Forms[1]:Property[ cWithValue ]

                ELSEIF UPPER( LEFT( cWithValue, 6 ) ) == ":FORM:"
                  cWithValue := STRTRAN( cWithValue, ":Form:" )
                  IF HGetPos( oObj:Form:Property, cWithValue ) > 0
                     xValue := oObj:Form:Property[ cWithValue ]
                   ELSE
                     xValue := cWithValue
                  ENDIF

                ELSEIF UPPER( LEFT( cWithValue, 2 ) ) == "::"
                  cWithValue := STRTRAN( cWithValue, "::" )
                  xValue := NIL
                  TRY
                     IF ( n := ASCAN( oObj:Owner:Parent:Children, {|o| o:Name == cWithValue } ) ) > 0
                        xValue := oObj:Owner:Parent:Children[n]
                     ENDIF
                   CATCH
                  END
                  IF xValue == NIL
                     IF HGetPos( oObj:Form:Property, cWithValue ) > 0
                        xValue := oObj:Form:Property[ cWithValue ]
                     ENDIF
                  ENDIF
                  DEFAULT xValue TO cWithValue

                ELSEIF UPPER( LEFT( cWithValue, 5 ) ) == ":FORM"
                  cWithValue := STRTRAN( cWithValue, ":Form" )
                  xValue := oObj:Form

                ELSE
                  IF UPPER( cWithProperty ) IN {"CAPTION","TEXT"} .AND. LEFT( cWithValue, 1 ) == "(" .AND. RIGHT( ALLTRIM( cWithValue ), 1 ) == ")"
                     xValue := cWithValue
                   ELSEIF UPPER( cWithProperty ) == "OWNER"
                     IF AT( ":PARENT:", UPPER( cWithValue ) ) > 0
                        cWithValue := STRTRAN( cWithValue, ":Parent:" )
                        IF ( n := ASCAN( oObj:Parent:Children, {|o| o:Name == cWithValue } ) ) > 0
                           xValue := oObj:Parent:Children[n]
                         ELSE
                           xValue := cWithValue
                        ENDIF

                        //xValue := oObj:Parent:&cWithValue
                      ELSEIF AT( ":FORM:", UPPER( cWithValue ) ) > 0
                        cWithValue := STRTRAN( cWithValue, ":Form:" )
                        xValue := oObj:Form:&cWithValue
                      ELSE
                        xValue := &cWithValue
                     ENDIF
                   ELSE
                     xValue := &cWithValue
                  ENDIF
               ENDIF
               IF oObj:ClsName == "AtlAxWin" .AND. oObj:__OleVars != NIL .AND. HGetPos( oObj:__OleVars, cWithProperty ) > 0
                  IF VALTYPE( oObj:__OleVars[cWithProperty][1] ) == "A" // Enumeration
                     oObj:__OleVars[cWithProperty][4] := xValue
                   ELSE
                     oObj:__OleVars[cWithProperty][1] := xValue
                  ENDIF
                ELSE
                  __objSendMsg( oObj, "_" + cWithProperty, xValue )
               ENDIF
            ELSEIF UPPER( cLine ) HAS "(?i)^:ADDIMAGE\("
               // Add saved Images to ImageList component
               cLine := STRTRAN( cLine, ":AddImage(" )
               cLine := STRTRAN( cLine, ")" )+", .T., .T. "
               hPtr := HB_ObjMsgPtr( oObj, "AddImage" )
               HB_Exec( hPtr, oObj, &cLine )

            ELSEIF UPPER( cLine ) HAS "(?i)^:CREATE\(\)"
               // Create Object
               oObj:Create()

            ELSEIF cLine HAS "(?i)^WITH OBJECT +:"
               // Generate object type PROPERTY for Control
               cPropertyObject := SubStr( aTokens[3], 2 )
               oObj := oObj:&cPropertyObject

            ELSEIF cLine HAS "(?i)^RETURN Self"
               // Finish container ????????
               IF !lDialog
                  BREAK
               ENDIF
            ENDIF

         ENDDO

      ENDIF

   CATCH oErr
      IF oErr != NIL
         ::Application:DebugWindow:Visible := .T.
         ::Application:Props[ "ViewDebugBuildItem" ]:Checked := .T.
         IF Empty( oErr:ProcName )
            AADD( aErrors, { cFile, NTRIM( nLine ), "PARSER", IIF( VALTYPE( oErr:Description ) == "C", oErr:Description, "" ) } )
          ELSE
            AADD( aErrors, { cFile, NTRIM( nLine ), "PARSER", IIF( VALTYPE( oErr:Description ) == "C", oErr:Description, "" ) + " " + oErr:Operation + " at: " + oErr:ProcName + "(" + Str( oErr:ProcLine(), 5 ) + ")" } )
         ENDIF

         #if 0
            TRY
               TraceLog( ValToPrgExp( oErr ) )
            CATCH
               // Do nothing.
            END
         #endif
      ENDIF
   END

RETURN NIL

//-------------------------------------------------------------------------------------------------------

METHOD SaveAs( cName ) CLASS Project
   LOCAL cPrevPath, cPath, cPrev, cCurr, cChar, oFile, lSave := .T., cSourcePath

   cPath := ::Properties:Path
   IF cName == NIL
      oFile := CFile( ::Properties:Name + ".vxh")
      oFile:Flags := OFN_EXPLORER | OFN_OVERWRITEPROMPT
      oFile:AddFilter( "Visual-xHarbour (*.vxh)", "*.vxh" )
      oFile:Path := ::Properties:Path
      oFile:SaveDialog()
      cName := oFile:Name
      cPath := oFile:Path
      lSave := oFile:Result == IDOK
   ENDIF

   IF lSave

      cCurr := ALLTRIM( STRTRAN( cName, ".vxh" ) )

      FOR EACH cChar IN cCurr
         IF ! ( cChar == '_' .OR. ( cChar >= 'a' .AND. cChar <= 'z' ) .OR. ( cChar >= 'A' .AND. cChar <= 'Z' ) .OR. ( cChar >= '0' .AND. cChar <= '9' ) .OR. cChar == " ")
            ::Application:MainForm:MessageBox( "Invalid project name: " + cName, "Save As", MB_ICONSTOP )
            RETURN Self
         ENDIF
      NEXT

      cPrev := ::Properties:Name
      IF !EMPTY( ::Forms )
         ::Application:ObjectManager:RenameForm( "__"+cPrev, "__"+STRTRAN( cCurr, " ","_" ), .T. )
      ENDIF

      cSourcePath := ::Properties:Path + "\" + ::Properties:Source
      IF FILE( cSourcePath + "\" + cPrev +"_XFM.prg" )
         FRENAME( cSourcePath + "\" + cCurr +"_XFM.prg",;
                  cSourcePath + "\" + STRTRAN( cCurr," ","_") +"_XFM.prg" )
      ENDIF

      cPrevPath := cPath

      ::Properties:Path := cPath
      ::Properties:Name := STRTRAN( cCurr," ","_")

      ::Save( .T., .T., cPrevPath )

      ::Application:SourceTabs:SetItemText( 1, cCurr +".prg", .F. )
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD RemoveImage( cImage, oObj ) CLASS Project
   LOCAL n
   IF VALTYPE( cImage ) == "C"
      n := ASCAN( ::aImages, {|a| a[1] == cImage .AND. a[4] == oObj } )
      IF n > 0
         ADEL( ::aImages, n, .T. )
      ENDIF
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD AddImage( cImage, nType, oObj, lIcon, lFirst ) CLASS Project
   LOCAL cResImg, i
   DEFAULT lFirst TO .F.
   DEFAULT lIcon TO .F.

   i := RAT( "\", cImage ) + 1
   cResImg := RIGHT( cImage, LEN( cImage ) - i + 1 )

   IF AT( ".", cResImg ) > 0
      IF lIcon
         cResImg := UPPER( STRTRAN( cResImg, "." ) )
         IF lFirst
            cResImg := "_1"+UPPER( STRTRAN( cResImg, " " ) )
          ELSE
            cResImg := "_"+UPPER( STRTRAN( cResImg, " " ) )
         ENDIF
       ELSE
         cResImg := STRTRAN( cResImg, " " )
         cResImg := "_"+UPPER(STRTRAN( cResImg, "." ))
      ENDIF
      IF ASCAN( ::aImages, {|a| a[2] == cResImg } ) == 0
         AADD( ::aImages, { cImage, cResImg, nType, oObj } )
      ENDIF
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD Save( lProj, lForce, cPrevPath ) CLASS Project
   LOCAL n, cWindow := "", oFile, oForm
   LOCAL lNew := .F., aImage, aEditors, aChildEvents, nInsMetPos, cChildEvents, cEvent, cText, cPath, cBuffer, cResPath, nSecs
   LOCAL aDir, x, xVersion, cType, cRc, cPrj, hFile, cLine, xPath, xName, lPro, i, cName, cResImg, cFile, cSourcePath, cPrevRes//, oWait

   //oWait := ::Application:MainForm:MessageWait( "Saving Project " + ::Properties:Name )

   m->aChangedProps := {} // reset changed properties for bold text display
   ::Application:ObjectManager:InvalidateRect(, .F. )

   ::__ExtraLibs := {}
   
   hb_gcall(.T.)
   nSecs := Seconds()

   DEFAULT lProj TO .F.
   DEFAULT lForce TO .F.

   IF EMPTY( ::AppObject:Version )
      ::AppObject:Version := "1.0.0.0"
   ENDIF

   ::Application:Cursor := ::System:Cursor:Busy
   WinSetCursor( ::Application:Cursor )

   cPath := ::Properties:Path

   IF lNew  .OR. ! IsDirectory( cPath )
      MakeDir( cPath )
   ENDIF

   IF ! IsDirectory( ::FixPath( cPath, ::Properties:Binary ) )
      MakeDir( ::FixPath( cPath, ::Properties:Binary ) )
   ENDIF
   IF ! IsDirectory( ::FixPath( cPath, ::Properties:Objects ) )
      MakeDir( ::FixPath( cPath, ::Properties:Objects ) )
   ENDIF
   IF ! IsDirectory( ::FixPath( cPath, ::Properties:Source ) )
      MakeDir( ::FixPath( cPath, ::Properties:Source ) )
   ENDIF
   IF ! IsDirectory( ::FixPath( cPath, ::Properties:Resource ) )
      MakeDir( ::FixPath( cPath, ::Properties:Resource ) )
   ENDIF

   IF cPrevPath != NIL
      cPrevRes := cPrevPath + "\" + ::Properties:Source
      cResPath := ::Properties:Path + "\" + ::Properties:Resource

      aDir := directory( cPrevRes + "\*.*", "D", .F.,.f. )

      FOR n := 1 TO LEN( aDir )
          IF aDir[n][5] != "D"
             CopyFile( cResPath + "\" + aDir[n][1],;
                       cResPath + "\" + aDir[n][1] )
          ENDIF
      NEXT
   ENDIF

   IF ::Properties:TargetType == 5 .AND. EMPTY( ::Properties:ClassID )
      ::Properties:ClassID := UPPER( CreateUUID() )
   ENDIF

   ::Properties:Save()

   aEditors := ::Application:SourceEditor:aDocs

   cSourcePath := cPath + "\" + ::Properties:Source

   FOR n := 1 TO LEN( aEditors )
       WITH OBJECT aEditors[n]
          IF (:Modified .OR. lForce) .AND. !EMPTY( :Path ) .AND. !EMPTY( :File )
             :Save()
             IF :PrevFile != NIL
                FERASE( cSourcePath + "\" + :PrevFile + ".prg" )
                FERASE( cSourcePath + "\" + :PrevFile + ".xfm" )
                :PrevFile := NIL
             ENDIF
          ENDIF
       END
   NEXT

   IF ::Application:ProjectPrgEditor:Modified .OR. lForce .OR. !FILE( cSourcePath + "\" + ::Properties:Name +"_Main.prg" )
      ::Application:ProjectPrgEditor:Save( cSourcePath + "\" + ::Properties:Name +"_Main.prg" )
   ENDIF

   ::AppObject:Resources := {}
   FOR EACH cFile IN ::Properties:Resources
       IF FILE( cFile )
          n := RAT( "\", cFile )
          cResImg := SUBSTR( cFile, n + 1 )
          cResImg := STRTRAN( cResImg, " " )
          cResImg := "_"+UPPER(STRTRAN( cResImg, "." ))

          cType := UPPER( SUBSTR( cFile, RAT( ".", cFile )+1 ) )
          AADD( ::AppObject:Resources, { cResImg, cType } )
       ENDIF
   NEXT

   IF ::Properties:TargetType == 5
      oFile := CFile( ::Properties:Name + "_OLE.prg" )
      oFile:Path := cSourcePath
      cText := '#include "vxh.ch"' + CRLF +;
               'static s_cProjectName := "'+::Properties:Name+'"' + CRLF+CRLF+;
               ;
               '#pragma BEGINDUMP' + CRLF+;
               '   #define CLS_Name "'+::Properties:Name+'.'+::Properties:Name+'.'+::AppObject:Version[1]+'"' + CRLF+;
               '   #define CLS_ID "{'+::Properties:ClassID+'}"' + CRLF+;
               '   #include "OleServer.h"' + CRLF+;
               '#pragma ENDDUMP' + CRLF + CRLF+;
               'REQUEST HB_GT_NUL_DEFAULT'+ CRLF+ CRLF+;
               ;
               'CLASS OleForms' + CRLF
               FOR EACH oForm IN ::Forms
                   cText += '   DATA o'+oForm:Name+ ' EXPORTED'+CRLF+;
                            '   METHOD ' + oForm:Name + '( hWnd, aParam ) INLINE ::o'+oForm:Name+' := ' + oForm:Name + '():SetInstance( s_cProjectName, Self ):Init( hWnd, aParam )' + CRLF+ CRLF
               NEXT
               cText += 'ENDCLASS' + CRLF
               
      oFile:FileBuffer := cText
      oFile:Save()
   ENDIF

   IF LEN( ::Forms ) > 0
      oFile := CFile( ::Properties:Name + "_XFM.prg" )
      oFile:Path := cSourcePath
      ::AppObject:Name := ::Properties:Name

      cWindow := '#include "vxh.ch"' + CRLF +;
                 "//---------------------------------------- End of system code ----------------------------------------//" + CRLF + CRLF

      cWindow += ::GenerateControl( ::AppObject, "__", "Application", , , @aChildEvents, @nInsMetPos, .F. )
      cWindow += CRLF

      oFile:FileBuffer := cWindow
      oFile:Save()
   ENDIF

   lPro := .F.
   #ifdef VXH_PROFESSIONAL
      lPro := .T.
   #endif

   ::Application:MainForm:FormEditor1:ResetScroll()

   FOR n := 1 TO LEN( ::Forms )
      
       // Unloaded forms need to report resources to be generated in RC file!!!
       IF ::Forms[n]:Cargo != NIL
          ::LoadUnloadedImages( cSourcePath + "\" + ::Forms[n]:Cargo )
       ENDIF
       //-------------------------------------------------------------------------------------------

       IF ::Forms[n]:lCustom
          cName := ::Forms[n]:Name
          IF ::Forms[n]:__OldName != NIL
             cName := ::Forms[n]:__OldName
             FERASE( cSourcePath + "\" + cName + ".xfm" )
             FERASE( cSourcePath + "\" + cName + ".prg" )
          ENDIF

          IF ( i := ASCAN( ::Application:CControls, {|cCC| UPPER(cName) == UPPER( STRTRAN( SplitFile(cCC)[2], ".xfm" ) ) } ) ) > 0
             ADEL( ::Application:CControls, i, .T. )
          ENDIF

          IF ASCAN( ::Application:CControls, cSourcePath + "\" + ::Forms[n]:Name + ".xfm",,, .T. ) == 0
             AADD( ::Application:CControls, cSourcePath + "\" + ::Forms[n]:Name + ".xfm" )
          ENDIF

       ENDIF

       IF ::Forms[n]:__lModified .OR. lForce

          aChildEvents := {}

          cWindow := ::GenerateControl( ::Forms[n], "", IIF( ::Forms[n]:MDIChild, "MDIChildWindow", IIF( ::Forms[n]:Modal, "Dialog", IIF( AT( "Window", ::Forms[n]:Name ) > 0, "Window", "WinForm" ) ) ), .F., n, @aChildEvents, @nInsMetPos, ::Forms[n]:lCustom )

          cChildEvents := ""
          FOR EACH cEvent IN aChildEvents
              IF AT( "METHOD "+cEvent+"()", cWindow+cChildEvents ) == 0
                 cChildEvents += "   METHOD "+cEvent+"()" + CRLF
              ENDIF
          NEXT

          cText := SUBSTR( cWindow, nInsMetPos )
          cWindow := SUBSTR( cWindow, 1, nInsMetPos ) + cChildEvents + cText

          oFile := CFile( ::Forms[n]:Name + ".xfm" )
          oFile:Path := cSourcePath
          IF x == 2
             oFile:Path := ::Forms[n]:PathName
          ENDIF
          oFile:FileBuffer := cWindow
          oFile:Save()

          IF ::Forms[n]:Editor:Modified .OR. lForce .OR. !FILE( cSourcePath + "\" + ::Forms[n]:Name + ".prg" )
             xPath := cSourcePath
             xName := ::Forms[n]:Name + ".prg"
             IF x == 2
                xPath := oFile:Path
             ENDIF
             ::Forms[n]:Editor:Save( xPath + "\" + xName )
          ENDIF

          ::Forms[n]:__lModified := .F.
       ENDIF
   NEXT

   IF ::Properties:ThemeActive
      oFile := CFile( ::Properties:Name + ".XML" )
      oFile:Path := cPath + "\" + ::Properties:Resource
      oFile:FileBuffer := ;
         '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'                    + CRLF +;
         '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">'  + CRLF +;
         '<assemblyIdentity'                                                          + CRLF +;
         '    version="1.0.0.0"'                                                      + CRLF +;
         '    processorArchitecture="X86"'                                            + CRLF +;
         '    name="CompanyName.ProductName.YourApp"'                                 + CRLF +;
         '    type="win32"'                                                           + CRLF +;
         '/>'                                                                         + CRLF +;
         '<description>Your application description here.</description>'              + CRLF +;
         '<dependency>'                                                               + CRLF +;
         '    <dependentAssembly>'                                                    + CRLF +;
         '        <assemblyIdentity'                                                  + CRLF +;
         '            type="win32"'                                                   + CRLF +;
         '            name="Microsoft.Windows.Common-Controls"'                       + CRLF +;
         '            version="6.0.0.0"'                                              + CRLF +;
         '            processorArchitecture="X86"'                                    + CRLF +;
         '            publicKeyToken="6595b64144ccf1df"'                              + CRLF +;
         '            language="*"'                                                   + CRLF +;
         '        />'                                                                 + CRLF +;
         '    </dependentAssembly>'                                                   + CRLF +;
         '</dependency>'                                                              + CRLF +;
         '</assembly>'                                                                + CRLF

      oFile:Save()
   ENDIF
   // Generate Resource file
   oFile := CFile( ::Properties:Name + ".rc" )
   oFile:Path := cPath + "\" + ::Properties:Resource

   IF ::Properties:ThemeActive
      cBuffer := 'IDOK MANIFEST "' + ::Properties:Name + '.XML"' + CRLF
    ELSE
      cBuffer := ""
   ENDIF

   #ifdef __GENVERSIONINFO__
      xVersion := STRTRAN( ::AppObject:Version, ".", "," )

      cBuffer += '#include "Winver.h"'                                                + CRLF + CRLF

      cBuffer += '1 VERSIONINFO'                                                      + CRLF
      cBuffer += 'FILEVERSION       '+xVersion                                        + CRLF
      cBuffer += 'PRODUCTVERSION    '+xVersion                                        + CRLF
      cBuffer += 'FILEFLAGS         0'                                                + CRLF
      cBuffer += 'FILEFLAGSMASK     VS_FFI_FILEFLAGSMASK'                             + CRLF
      cBuffer += 'FILEOS            VOS__WINDOWS32'                                   + CRLF
      cBuffer += 'FILETYPE          VFT_APP'                                          + CRLF
      cBuffer += 'FILESUBTYPE       0'                                                + CRLF
      cBuffer += '{'                                                                  + CRLF
      cBuffer += '   BLOCK "StringFileInfo"'                                          + CRLF
      cBuffer += '   {'                                                               + CRLF
      cBuffer += '      BLOCK "040904E4"'                                             + CRLF
      cBuffer += '      {'                                                            + CRLF
      cBuffer += '         VALUE "CompanyName",      "'+ ::AppObject:Company+'"'      + CRLF
      cBuffer += '         VALUE "FileDescription",  "'+ ::AppObject:Description+'"'  + CRLF
      cBuffer += '         VALUE "FileVersion",      "'+ ::AppObject:Version+'\0"'    + CRLF
      cBuffer += '         VALUE "InternalName",     "'+ ::Properties:Name+'"'        + CRLF
      cBuffer += '         VALUE "LegalCopyright",   "'+ ::AppObject:Copyright+'"'    + CRLF
      cBuffer += '         VALUE "OriginalFilename", "'+ ::Properties:Name+'.exe"'    + CRLF
      cBuffer += '         VALUE "ProductName",      "'+ ::Properties:TargetName+'"'  + CRLF
      cBuffer += '         VALUE "ProductVersion",   "'+ ::AppObject:Version+'\0"'    + CRLF
      cBuffer += '      }'                                                            + CRLF
      cBuffer += '   }'                                                               + CRLF
      cBuffer += '   BLOCK "VarFileInfo"'                                             + CRLF
      cBuffer += '   {'                                                               + CRLF
      cBuffer += '      // English language and the Windows ANSI codepage'            + CRLF
      cBuffer += '      VALUE "Translation", 0x409, 1252'                             + CRLF
      cBuffer += '   }'                                                               + CRLF
      cBuffer += '}'                                                                  + CRLF
   #endif

   IF ! EMPTY( ::AppObject:Icon )
       cBuffer += "_0APPICON ICON "+ValToPrgExp( STRTRAN( ::AppObject:Icon, "\", "\\" )) + CRLF
   ENDIF

   FOR EACH aImage IN ::aImages
       cType := aImage[3]

       IF VALTYPE( aImage[3] ) == "C"
          IF aImage[3] == "CUR"
             cType := "CURSOR"
           ELSEIF aImage[3] == "ICO"
             cType := "ICON"
           ELSEIF aImage[3] == "BMP"
             cType := "BITMAP"
          ENDIF
        ELSEIF VALTYPE( aImage[3] ) != "C"
          IF aImage[3] == IMAGE_CURSOR
             cType := "CURSOR"
           ELSEIF aImage[3] == IMAGE_ICON
             cType := "ICON"
           ELSE
             cType := "BITMAP"
          ENDIF
       ENDIF
       cBuffer += aImage[2]+" "+ cType +" "+ValToPrgExp( STRTRAN( aImage[1], "\", "\\" )) + CRLF
   NEXT

   FOR EACH cPrj IN ::Properties:ExtImages
       n := RAT( "\", cPrj )
       cRc := LEFT( cPrj, n ) + "Resource\" + SUBSTR( cPrj, n+1 )
       cRc := STRTRAN( lower( cRc ), ".vxh", ".rc" )
       IF FILE( cRc )

          hFile := FOpen( cRc, FO_READ )
          WHILE HB_FReadLine( hFile, @cLine, XFM_EOL ) == 0
             IF AT( "\\", cLine ) > 0
                n := AT( '"', cLine )
                IF FILE( STRTRAN( SUBSTR( cLine, n ), '"' ) ) .AND. AT( cLine, cBuffer ) == 0
                   cBuffer += cLine + CRLF
                ENDIF
             ENDIF
          END
          FClose( hFile )

       ENDIF
   NEXT

   FOR EACH cFile IN ::Properties:Resources
       IF FILE( cFile )
          n := RAT( "\", cFile )
          cResImg := SUBSTR( cFile, n + 1 )
          cResImg := STRTRAN( cResImg, " " )
          cResImg := "_"+UPPER(STRTRAN( cResImg, "." ))

          cType := UPPER( SUBSTR( cFile, RAT( ".", cFile )+1 ) )
          IF cType == "CUR"
             cType := "CURSOR"
           ELSEIF cType == "ICO"
             cBuffer += cResImg+" "+ cType +" "+ValToPrgExp( STRTRAN( cFile, "\", "\\" )) + CRLF
             cType := "ICON"
           ELSEIF cType == "BMP"
             cType := "BITMAP"
          ENDIF

          cBuffer += cResImg+" "+ cType +" "+ValToPrgExp( STRTRAN( cFile, "\", "\\" )) + CRLF
       ENDIF
   NEXT

   oFile:FileBuffer := cBuffer
   oFile:Save()
   //OutputDebugString( " Saving finished: " + xStr( Seconds()-nSecs ) )

   ::Built := .F.

   ::ResetQuickOpen( ::Properties:Path + "\" + ::Properties:Name + ".vxh" )

   ::Application:Props[ "RunItem"         ]:Enabled := .T.
   ::Application:Props[ "ResourceManager" ]:Enabled := .T.
   ::Application:Props[ "ProjSaveItem"    ]:Enabled := .F.
   ::Application:Props[ "ProjBuildItem"   ]:Enabled := .T.
   ::Application:Props[ "ProjRunItem"     ]:Enabled := .T.

   ::Application:Cursor := NIL
   WinSetCursor( ::System:Cursor:Arrow )

   ::Modified := .F.
   //oWait:Destroy()
RETURN Self

#define LANG_NEUTRAL       0x00
#define SUBLANG_DEFAULT    0x01
#define SUBLANG_NEUTRAL    0x00

#define MAKELANGID( p, s ) ( ( ( (s) )<<10) |(p) )

// aResource = { { cFileName, cType, cResName } }
FUNCTION AddResources( cExe, aResources )
   LOCAL n, aRes, cBuffer, hFile, hResource := BeginUpdateResource( cExe, .T. )
   IF hResource != NIL .AND. hResource != 0
      FOR EACH aRes IN aResources
          IF FILE( aRes[1] )
             hFile := fOpen( aRes[1] )
             n     := FileSize( aRes[1] )
             cBuffer := SPACE(n)
             n := fRead( hFile, @cBuffer, n )
             UpdateResource( hResource, aRes[2], aRes[3], MAKELANGID( LANG_NEUTRAL, SUBLANG_NEUTRAL ), cBuffer, n )
             FClose( hFile )
          ENDIF
      NEXT
      EndUpdateResource( hResource, .F. )
   END
RETURN NIL

//------------------------------------------------------------------------------------------------------------------------------------
METHOD GenerateChild( oCtrl, nTab, aChildEvents, cColon, cParent, nID ) CLASS Project
   LOCAL cText := "", oChild, Topic, Event, n, cProp, cChild
   ( cColon )
   ( nID )
   IF oCtrl:Caption != "[ Add New Item ]"
      IF !oCtrl:__CustomOwner
         cText := SPACE( nTab ) + "WITH OBJECT ( " + IIF( oCtrl:ClassName == "CUSTOMCONTROL", UPPER( oCtrl:__xCtrlName ), oCtrl:ClassName ) + "( " + cParent + " ) )" + CRLF

         cProp := ::GenerateProperties( oCtrl, nTab + 3, ":",,,,, cParent )

         IF !Empty( oCtrl:Events )
            FOR EACH Topic IN oCtrl:Events
                FOR EACH Event IN Topic[2]
                    IF ! EMPTY( Event[2] )
                       AADD( aChildEvents, Event[2] )
                       cProp += SPACE( nTab+3 ) + ":EventHandler[ " + ValToPrgExp( Event[1] )+ " ] := " + ValToPrgExp( Event[2] ) + CRLF
                    ENDIF
                NEXT
            NEXT
         ENDIF

         IF !oCtrl:__lCreateAfterChildren
            cProp += SPACE( nTab+3 ) + ":Create()" + CRLF
            IF oCtrl:ClsName == "AtlAxWin"
               ::GenerateProperties( oCtrl, nTab+3, ":",,, oCtrl:__OleVars, @cProp, cParent )
               cProp += SPACE( nTab+3 ) + ":Configure()" + CRLF
            ENDIF
         ENDIF

         n := 1
         cChild := ""
         FOR EACH oChild IN oCtrl:Children
             IF oChild:__xCtrlName != "DataGridHeader"
                cChild += ::GenerateChild( oChild, IIF( oCtrl:ClassName == "CUSTOMCONTROL", nTab, nTab+3 ), @aChildEvents, ":", ":this", n )
             ENDIF
             n++
         NEXT

         IF !oCtrl:ClassName == "CUSTOMCONTROL"
            cProp += cChild
         ENDIF

         IF oCtrl:__lCreateAfterChildren
            cProp += SPACE( nTab+3 ) + ":Create()" + CRLF
            IF oCtrl:ClsName == "AtlAxWin"
               ::GenerateProperties( oCtrl, nTab+3, ":",,, oCtrl:__OleVars, @cProp, cParent )
               cProp += SPACE( nTab+3 ) + ":Configure()" + CRLF
            ENDIF
         ENDIF

         cText += cProp + SPACE( nTab ) + "END //" + oCtrl:ClassName + CRLF + CRLF

         IF oCtrl:ClassName == "CUSTOMCONTROL"
            cText += cChild
         ENDIF

       ELSE
         cText := SPACE( nTab ) + "WITH OBJECT ::" + IIF( oCtrl:__OriginalName == NIL, oCtrl:Name, oCtrl:__OriginalName ) + CRLF
         cProp := ::GenerateProperties( oCtrl, nTab + 3, ":",,,,, cParent )

         IF !Empty( oCtrl:Events )
            FOR EACH Topic IN oCtrl:Events
                FOR EACH Event IN Topic[2]
                    IF ! EMPTY( Event[2] )
                        AADD( aChildEvents, Event[2] )
                        cProp += SPACE( nTab+3 ) + ":EventHandler[ " + ValToPrgExp( Event[1] )+ " ] := " + ValToPrgExp( Event[2] ) + CRLF
                    ENDIF
                NEXT
            NEXT
         ENDIF

         IF EMPTY( cProp )
            cText := ""
          ELSE
            cText += cProp
            n := 1

            FOR EACH oChild IN oCtrl:Children
                IF oChild:__xCtrlName != "DataGridHeader" .AND. !oChild:__CustomOwner
                   cText += ::GenerateChild( oChild, nTab+3, @aChildEvents, ":", ":this", n )
                ENDIF
                n++
            NEXT

            cText += SPACE( nTab ) + "END //" + oCtrl:ClassName + CRLF + CRLF
         ENDIF

         n := 1
         FOR EACH oChild IN oCtrl:Children
             IF oChild:__xCtrlName != "DataGridHeader" .AND. oChild:__CustomOwner
                cText += ::GenerateChild( oChild, nTab, @aChildEvents, ":", ":this", n )
             ENDIF
             n++
         NEXT

      ENDIF
   ENDIF
RETURN cText

//------------------------------------------------------------------------------------------------------------------------------------
METHOD GenerateProperties( oCtrl, nTab, cColon, cPrev, cProperty, hOleVars, cText, cParent ) CLASS Project
   LOCAL aProperties, aProperty, cProp, xValue1, xValue2, cProps
   LOCAL lParent, cResImg, n, cArray, x

   DEFAULT cPrev TO ""
   DEFAULT cText TO ""

   IF oCtrl:__ClassInst != NIL
      IF hOleVars == NIL
         aProperties := __ClsGetPropertiesAndValues( oCtrl )
       ELSE
         aProperties := hOleVars:Keys
      ENDIF

      FOR EACH aProperty IN aProperties

          IF cProperty == NIL
             IF hOleVars == NIL
                cProp := __GetProperCase( __Proper( aProperty[1] ) )[1]
               ELSE
                cProp := aProperty
             ENDIF
           ELSE
             cProp := cProperty
          ENDIF
          IF cProp == "Position" .AND. oCtrl:__xCtrlName == "TabPage"
             LOOP
          ENDIF

          IF UPPER( cProp ) == "TABORDER"
             LOOP
          ENDIF
          IF ( oCtrl:ClsName == "GridColumn" .AND. cProp == "Position" ) .OR. cProp == "UserVariables"
             LOOP
          ENDIF
          IF cProp != "Parent"
             IF hOleVars == NIL
                IF UPPER( cProp ) == "HEIGHT" .AND. oCtrl:__xCtrlName == "Expando"
                   xValue1 := oCtrl:__nHeight
                   DEFAULT xValue1 TO oCtrl:Height
                   xValue2 := 0
                 ELSE
                   xValue1 := __objSendMsg( oCtrl, UPPER( cProp ) )
                   xValue2 := __objSendMsg( oCtrl:__ClassInst, UPPER( cProp ) )
                ENDIF

              ELSE
                xValue1 := hOleVars[cProp][1]
                xValue2 := hOleVars[cProp][2]
                
                IF VALTYPE( xValue1 ) == "A" // Enumeration
                   xValue1 := hOleVars[cProp][4]
                   TRY
                      xValue2 := oCtrl:&cProp
                   CATCH
                      LOOP
                   END
                ENDIF
                IF hOleVars[cProp][3]
                   xValue1 := NIL
                   xValue2 := NIL
                ENDIF
                IF VALTYPE( xValue1 ) == "O" // Collection
                   xValue1 := NIL
                   xValue2 := NIL
                ENDIF
             ENDIF
             IF !( xValue1 == xValue2 )
                IF VALTYPE(xValue1) == "O" .AND. __ObjHasMsg( xValue1, "Name" ) .AND. !EMPTY( xValue1:Name ) 

                   IF UPPER( LEFT( xValue1:Name, 9 ) ) != "::SYSTEM:"
                      cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + ValToPrgExp(xValue1:Name)+ CRLF
                    ELSE
                      cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + xValue1:Name + CRLF
                   ENDIF

                 ELSEIF ( cProp == "Icon" .OR. cProp == "ImageName" .OR. cProp == "BitmapMask") .AND. VALTYPE( xValue1 ) == "C" .AND. ! oCtrl == ::AppObject
                 
                   IF !EMPTY( xValue1 )
                      n := RAT( "\", xValue1 ) + 1
                      cResImg := RIGHT( xValue1, LEN( xValue1 ) - n + 1 )

                      IF AT( ".", cResImg ) > 0
                         cResImg := UPPER( STRTRAN( cResImg, "." ) )

                         IF cProp == "Icon" .AND. oCtrl == ::Forms[1]
                            cResImg := "_1"+UPPER( STRTRAN( cResImg, " " ) )
                          ELSE
                            cResImg := "_"+UPPER( STRTRAN( cResImg, " " ) )
                         ENDIF
                         cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := { " + ValToPrgExp( xValue1 ) + "," + ValToPrgExp(cResImg) + " }"+ CRLF
                       ELSE
                         cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := { " + ValToPrgExp( xValue1 ) + ", }"+ CRLF
                      ENDIF
                   ENDIF

                 ELSE
                   IF VALTYPE( xValue1 ) == "O"

                      IF cPrev == "Dock" .OR. cPrev == "Anchor"
                         cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + IIF( xValue1:hWnd == oCtrl:Owner:Parent:hWnd, cColon + "Owner:Parent", "::" + xValue1:Name ) + CRLF
                       ELSEIF cPrev == "MDIClient" .AND. ( cProp == "AlignLeft" .OR. cProp == "AlignTop" .OR. cProp == "AlignRight" .OR. cProp == "AlignBottom" )
                         cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + ValToPrgExp( xValue1:Name ) + CRLF

                       ELSE
                         IF cProp == "Owner"
                            cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := ::" + xValue1:Name + CRLF
                          ELSE
                            lParent := .F.
                            IF __clsParent( xValue1:ClassH, "COMPONENT" ) .OR. xValue1:ClsName == "FreeImageRenderer"
                               IF xValue1:Owner == oCtrl
                                  lParent := .T.
                               ENDIF
                             ELSE
                               IF xValue1:Parent == oCtrl //.OR. oCtrl:ClsName == "CMenuItem"
                                  lParent := .T.
                               ENDIF
                            ENDIF

                            IF lParent
                               cProps := ::GenerateProperties( xValue1, nTab+3, ":", cProp,,,,cParent )
  
                               IF cProp == "BackgroundImage"
                                  cProp := "BackgroundImage := FreeImageRenderer( "+cParent+" )"
                               ENDIF
                               IF !EMPTY( ALLTRIM( cProps ) )
                                  cText += SPACE( nTab ) + "WITH OBJECT " + cColon + cProp + CRLF
                                  cText += cProps
                                  cText += SPACE( nTab ) + "END" + CRLF + CRLF
                               ENDIF
                            ENDIF
                         ENDIF
                      ENDIF
                    ELSE
                      IF cProp IN {"Caption","Text"}
                         IF xValue1 != NIL .AND. Left( xValue1, 1 ) == "\"
                            cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + ValToPrgExp( SubStr( xValue1, 2 ) ) + CRLF
                         ELSEIF xValue1 != NIL .AND. Left( xValue1, 1 ) == "("
                            cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + xValue1 + CRLF
                         ELSE
                            cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + ValToPrgExp( xValue1 ) + CRLF
                         ENDIF
                       ELSEIF VALTYPE( xValue1 ) != "A"

                         //IF oCtrl:ClsName == "VXH_FORM_IDE"
                         //   IF UPPER( cProp ) == "TOP"
                         //      xValue1 += oCtrl:Parent:VertScrollPos
                         //    ELSEIF UPPER( cProp ) == "LEFT"
                         //      xValue1 += oCtrl:Parent:HorzScrollPos
                         //   ENDIF
                         //ENDIF
                         cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + IIF( cProp == "FaceName", '"' + STRTRAN( xValue1, CHR(0) ) + '"', ValToPrgExp( xValue1 ) ) + CRLF

                       ELSEIF oCtrl:__xCtrlName == "MemoryTable" .OR. cProp == "Resources" .OR. ( cProp == "Structure" .AND. oCtrl:__xCtrlName == "MemoryDataTable" )
                         IF VALTYPE( xValue1 ) == "A"
                            cArray := "{ "
                            FOR n := 1 TO LEN( xValue1 )
                                cArray += "{ "
                                FOR x := 1 TO LEN( xValue1[n] )
                                    cArray += ALLTRIM( ValToPrgExp( xValue1[n][x] ) ) + IIF( x < LEN( xValue1[n] ), ", ", "" )
                                NEXT x
                                cArray += " }" + IIF( n < LEN( xValue1 ), ", ", "" )
                            NEXT n
                            cArray += " }"
                          ELSE
                            cArray := ValToPrg( xValue1 )
                         ENDIF
                         cText += SPACE( nTab ) + cColon + PadR( cProp, MAX( LEN(cProp)+1, 20 ) ) + " := " + cArray + CRLF
                      ENDIF
                   ENDIF
                ENDIF
             ENDIF
          ENDIF
          IF cProperty != NIL
             EXIT
          ENDIF

      NEXT
   ENDIF

RETURN cText

//------------------------------------------------------------------------------------------------------------------------------------
METHOD ResetQuickOpen( cFile ) CLASS Project
   LOCAL lMems, aEntries, n, oItem, nBkHeight, oLink, x, lLink := .T.

   aEntries := ::Application:IniFile:GetEntries( "Recent" )
   IF ! EMPTY( aEntries ) .AND. cFile != NIL .AND. aEntries[1] == cFile
      RETURN NIL
   ENDIF

   lMems := ::Application:GenerateMembers

   ::Application:GenerateMembers := .F.

   // IniFile Recently open projects

   AEVAL( aEntries, {|c| ::Application:IniFile:DelEntry( "Recent", c ) } )

   IF cFile != NIL .AND. ( n := ASCAN( aEntries, {|c| c == cFile } ) ) > 0
      ADEL( aEntries, n, .T. )
   ENDIF
   IF cFile != NIL .AND. FILE( cFile )
      aIns( aEntries, 1, cFile, .T. )
      IF LEN( aEntries )>=20
         ASIZE( aEntries, 20 )
      ENDIF
   ENDIF

   nBkHeight := 35
   // Reset StartPage and Open Dropdown menu

   FOR n := 1 TO LEN( aEntries )
       ::Application:IniFile:WriteString( "Recent", aEntries[n], "" )

       WITH OBJECT ::Application:Props[ "OpenBttn" ]   // Open Button
          IF LEN( :Children ) < n
             oItem := MenuStripItem( :this )
             oItem:Create()
           ELSE
             oItem := :Children[n]
          ENDIF
       END
       oItem:Caption := aEntries[n]
       oItem:Action  := {|o| ::Application:Project:Open( o:Caption ) }

       IF lLink
          x := RAT( "\", aEntries[n] )
          IF LEN( ::Application:aoLinks ) < n
             oLink := LinkLabel( ::Application:MainForm:Panel4 )
             oLink:ImageIndex  := 32
             oLink:Caption     := SUBSTR( aEntries[n], x + 1, LEN( aEntries[n] )-x-4 )
             oLink:Left        := 30
             oLink:Top         := nBkHeight + 2
             oLink:Url         := aEntries[n]
             oLink:Action      := {|o| ::Application:Project:Open( o:Url ) }
             oLink:Font:Bold   := .T.
             oLink:Create()
             AADD( ::Application:aoLinks, oLink )
           ELSE
             oLink := ::Application:aoLinks[n]
             oLink:Caption     := SUBSTR( aEntries[n], x + 1, LEN( aEntries[n] )-x-4 )
             oLink:Url         := aEntries[n]
             oLink:Action      := {|o| ::Application:Project:Open( o:Url ) }
          ENDIF
       ENDIF
       nBkHeight := oLink:Top + oLink:Height
       IF nBkHeight > oLink:Parent:Height-( (oLink:Height*3 )*1.5)
          lLink := .F.  
       ENDIF
   NEXT

   ::Application:GenerateMembers := lMems

RETURN Self

//------------------------------------------------------------------------------------------------------------------------------------
METHOD Run( lRunOnly ) CLASS Project

   LOCAL cExe, cPath, oFile, pHrb, cBinPath, cCurDir
   DEFAULT lRunOnly TO .F.
   TRY
      cPath := ::Properties:Path
      cBinPath := ::FixPath( cPath, ::Properties:Binary )
      
      cCurDir := GetCurrentDirectory()
      DirChange( cPath )

      cExe := cBinPath + "\" + IIF( !EMPTY( ::Properties:TargetName ), ::Properties:TargetName, ::Properties:Name ) + aTargetTypes[ ::Properties:TargetType ]

      IF ::Modified .AND. !lRunOnly
         ::Save()
      ENDIF

      IF ( ( ! ::Built ) .OR. ( ! File( cExe ) ) ) .AND. !lRunOnly
         ::Build()
      ENDIF

      lRunOnly := lRunOnly .AND. FILE( cExe )
      IF ::Built .OR. lRunOnly
         IF lRunOnly .AND. ::Application:RunMode == 0
            ::Build()
         ENDIF
         IF ::Properties:TargetType == 1
            IF ::Application:RunMode == 0
               ShellExecute( GetActiveWindow(), "open", cExe, ::Properties:Parameters + " //DEBUG", , SW_SHOW )
               ::Debug()
            ELSE
               ::Application:DebuggerPanel:Hide()

               IF ::Application:DisableWhenRunning
                  WaitExecute( cExe, ::Properties:Parameters, SW_SHOW )
                ELSE
                  ShellExecute( GetActiveWindow(), "open", cExe, ::Properties:Parameters, , SW_SHOW )
               ENDIF

               ::Application:DebugWindow:Hide()
               ::Application:Props[ "ViewDebugBuildItem" ]:Checked := .F.
            ENDIF

          ELSEIF ::Properties:TargetType == 4
            oFile := CFile( cExe )
            oFile:Load()
            pHrb := __hrbLoad( ALLTRIM( oFile:FileBuffer ) )
            __hrbDo( pHrb, ::Application:MainForm )
         ENDIF
      ENDIF
      DirChange( cCurDir )
   CATCH
   END
RETURN 0

//------------------------------------------------------------------------------------------------------------------------------------
#define TYPE_SOURCE_LIB -5
#define TYPE_SOURCE_OBJ -4
#define TYPE_SOURCE_RES -3
#define TYPE_RC         -2
#define TYPE_INCLUDE    -1
#define TYPE_NO_ACTION   0

// Actions generating
#define TYPE_FROM_PRG    1
#define TYPE_FROM_C      2
#define TYPE_FROM_SLY    3
#define TYPE_FROM_RC     4

// Targets
#define TYPE_EXE        10
#define TYPE_LIB        11
#define TYPE_DLL        12
#define TYPE_HRB        13

METHOD Build( lForce ) CLASS Project
   LOCAL n, cProject, cExe, cResPath
   LOCAL oProject, bErrorHandler, bProgress, oErr, oWnd, cTemp
   LOCAL lBuilt, cSource, cPath, oHrb, cControl, cBinPath, cSourcePath, cObjPath, cCurDir

   DEFAULT lForce TO .F.

   IF LEN( ::Forms ) > 0 .AND. ASCAN( ::Forms, {|o| ! o:lCustom} ) == 0
      RETURN .F.
   ENDIF
   cPath := ::Properties:Path

   cBinPath    := ::FixPath( cPath, ::Properties:Binary )
   cSourcePath := ::FixPath( cPath, ::Properties:Source )
   cObjPath    := ::FixPath( cPath, ::Properties:Objects )
   cResPath    := ::FixPath( cPath, ::Properties:Resource )

   IF ! IsDirectory( cBinPath )
      MakeDir( cBinPath )
   ENDIF
   IF ! IsDirectory( cObjPath )
      MakeDir( cObjPath )
   ENDIF


   cExe  := cBinPath + "\" + IIF( !EMPTY( ::Properties:TargetName ), ::Properties:TargetName, ::Properties:Name ) + aTargetTypes[ ::Properties:TargetType ]
   IF lForce .AND. FILE( cExe )
      DeleteFilesAndFolders( cObjPath )
      FERASE( cExe )
   ENDIF

   ::Application:DebugWindow:Visible := .T.
   ::Application:Props[ "ViewDebugBuildItem" ]:Checked := .T.

   ::Application:ErrorView:ResetContent()

   ::Application:MainForm:DebugBuild1:ResetContent()
   ::Application:MainForm:TabPage5:Select()
   ::Application:MainForm:DebugBuild1:SetFocus()
   ::Application:MainForm:DebugBuild1:AddItem( "Building: "+::Properties:Name )
   ::Application:MainForm:DebugBuild1:Redraw()
   ::Application:MainForm:UpdateWindow()

   n := 1
   lBuilt := .F.
   TRY
      cPath := ::Properties:Path
      cCurDir := GetCurrentDirectory()
      DirChange( cPath )
      
      cProject := cPath + "\" + ::Properties:Name + aTargetTypes[ ::Properties:TargetType ]
      IF !EMPTY( ::Properties:TargetName )
         cProject := cPath + "\" + ::Properties:TargetName + aTargetTypes[ ::Properties:TargetType ]
      ENDIF

      oProject := TMakeProject():New( cProject, ::Properties:TargetType + 9 )

      WITH OBJECT oProject
         :lMT          := ::Properties:MultiThread
         :lGUI         := ::Properties:GUI
         :lINI         := .F.
         :OutputFolder := cObjPath
         :TargetFolder := cBinPath
         :RunArguments := ::Properties:Parameters
         :lNoAutoFWH   := .T.

         IF !EMPTY( ::Properties:Definitions )
            ::Properties:Definitions := "; " + ::Properties:Definitions
         ENDIF

         :SetDefines( "__VXH__" + ::Properties:Definitions )

         :lClean := ::Properties:CleanBuild
         :SetIncludeFolders( ::Properties:IncludePath )

         oHrb := NIL
         IF ::Properties:TargetType == 4 //HRB only
            IF FILE( cTemp )
               FERASE( cTemp )
            ENDIF
            oHrb := CFile()
            oHrb:Path := cSourcePath
            oHrb:Name := ::Properties:Name + "_HRB.prg"
            cTemp := oHrb:Path + "\" + oHrb:Name

            oHrb:FileBuffer := '#include "vxh.ch"' + CRLF+;
                               'FUNCTION __' + ::Properties:Name + '( oParent, aParameters )' + CRLF+;
                               '   '+::Forms[1]:Name+'():Init( oParent, aParameters )' + CRLF +;
                               'RETURN NIL' + CRLF + CRLF
         ENDIF

         IF FILE( cSourcePath + "\" + ::Properties:Name + "_Main.prg" )
            // FUNCTION Main should only be included in EXE files
            IF oHrb == NIL .AND. ::Properties:TargetType == 1
               :AddFiles( cSourcePath + "\" + ::Properties:Name + "_Main.prg" )
            ENDIF
         ENDIF

         IF FILE( cSourcePath + "\" + ::Properties:Name + "_XFM.prg" )
            // Application declaration only for EXE files
            IF oHrb == NIL .AND. ::Properties:TargetType <> 2
               :AddFiles( cSourcePath + "\" + ::Properties:Name + "_XFM.prg" )
            ENDIF
         ENDIF

         FOR EACH cControl IN ::CustomControls
             :AddFiles( STRTRAN( cControl, ".xfm", ".prg" ) )
         NEXT

         IF ::Properties:TargetType == 5
            :AddFiles( cSourcePath + "\" + ::Properties:Name + "_OLE.prg" )
         ENDIF

         FOR EACH oWnd IN ::Forms
             IF FILE( cSourcePath + "\" + oWnd:Name + ".prg" )
                IF oHrb != NIL
                   oHrb:FileBuffer += '#include ' + ValToPrgExp( cSourcePath + "\" + oWnd:Name + ".prg" ) + CRLF
                 ELSE
                   :AddFiles( cSourcePath + "\" + oWnd:Name + ".prg" )
                ENDIF
             ENDIF
         NEXT

         FOR EACH cSource IN ::Application:Project:Properties:Sources
             IF oHrb != NIL
                oHrb:FileBuffer += '#include ' + ValToPrgExp( cSource ) + CRLF
              ELSE
                :AddFiles( cSource )
             ENDIF
         NEXT

         IF oHrb != NIL
            oHrb:Save()
            :AddFiles( cTemp )
         ENDIF

         :MyPrg_Flags := ::Properties:CompilerFlags

         IF ::Properties:TargetType == 1 //EXE
            IF ::Application:RunMode == 0
               :lClean := .T.
               :MyPrg_Flags += " -b" //IIF( !Empty( :MyPrg_Flags ), :MyPrg_Flags, :Prg_Flags ) + " -b"
               :AddFiles( "dbgserve.lib" )
            ENDIF
            AEVAL( ::__ExtraLibs, {|cLib| :AddFiles( cLib )} )
         ENDIF

         IF LEN( ::Forms ) > 0
            ::Properties:GUI := .T.
         ENDIF

         :lGUI := ::Properties:GUI

         :AddFiles( cResPath + "\" + ::Properties:Name + ".rc" )

         IF ::Properties:TargetType IN {1,3,5} // EXE, DLL, DLL OLE SERVER
            #ifdef VXH_DEMO
             IF ::Properties:UseDll
                MessageBox( , "Sorry, 'UseDLL' is not allowed in the demo version.", "Visual xHarbour", MB_OK | MB_ICONEXCLAMATION )
                ::Properties:UseDll:=.F.
             ENDIF
            #endif

            IF ::Properties:UseDll
               :SetDefines( "WIN ;WIN32 ;__EXPORT__ ;__IMPORT__ ;__VXH__" + ::Properties:Definitions )
               IF ::Properties:GUI
                  :AddFiles( "vxhdll.lib" )
               ENDIF
             ELSEIF ::Properties:GUI
               :SetDefines( "WIN ;WIN32 ;__EXPORT__; __VXH__" + ::Properties:Definitions )
               :AddFiles( "vxh.lib" )
               :AddFiles( "Activex.lib" )
               IF ::Properties:TargetType == 5
//                  :AddFiles( "OleServer.lib" )
                ELSE
                  :AddFiles( "Ole.lib" )
               ENDIF
               :AddFiles( ::Application:IniFile:ReadString( "General", "SQL lib", "sql.lib" ) )
            ENDIF

            FOR EACH cSource IN ::Application:Project:Properties:Binaries
               :AddFiles( cSource )
            NEXT

         ENDIF
         :lUseDLL := ::Properties:UseDll
         :lXBP    := ::Application:IniFile:ReadInteger( "General", "SaveXBP", 0 )==1
      END

      ::Application:BuildLog:Caption := ""

      bProgress := {|Module| ::Application:MainForm:DebugBuild1:AddItem( IIF( Module:nType != ::Properties:TargetType + 9, "Compiling "+Module:cFile+"...", "Linking "+Module:cFile ), .T. ),;
                             ::Application:MainForm:DebugBuild1:SetHorizontalExtent( 1000 ),;
                             ::Application:MainForm:StatusBarPanel2:Caption := "Building: "+::Properties:Name+" - "+Module:cFile,;
                             ::Application:MainForm:DebugBuild1:UpdateWindow(),;
                             ::Application:Yield() }

      bErrorHandler := {|oError|GUI_ErrorGrid( oError, MEMOREAD( cProject + ".log" ) )}

      //-----------------------------------------------------
      lBuilt := oProject:Make( bErrorHandler, bProgress )
      DirChange( cCurDir )
      //-----------------------------------------------------


      IF EMPTY( ::Application:BuildLog:Caption )
         ::Application:BuildLog:Caption := MEMOREAD( cProject + ".log" )
      ENDIF

   CATCH oErr
      OutputDebugString(ValToPrg(oErr))
      ::Application:MainForm:StatusBarPanel2:Caption := "ERRORS!"
      ::Application:MainForm:DebugBuild1:AddItem( "ERRORS!", .T. )
      ::Application:MainForm:DebugBuild1:AddItem( oErr:Description+" "+oErr:Operation, .T. )
      ::Application:MainForm:DebugBuild1:AddItem( oErr:Modulename+ " ("+LTrim(Str(oErr:ProcLine))+")", .T. )
      RETURN .F.
   END

   IF !lBuilt
      RETURN .F.
   ENDIF
   IF FILE( cProject + ".log" )
      FERASE( cProject + ".log" )
   ENDIF

   ::Application:MainForm:DebugBuild1:AddItem( STRTRAN( ::Properties:Name, aTargetTypes[ ::Properties:TargetType ] + ".xbp" )+ " Built", .T. )

   ::Application:MainForm:StatusBarPanel2:Caption := STRTRAN( ::Properties:Name, aTargetTypes[ ::Properties:TargetType ] + ".xbp" )+ " Built"
   ::Built := .T.

RETURN .T.

//-------------------------------------------------------------------------------------------------------
METHOD Debug() CLASS Project
   IF ::Debugger != NIL
      ::Debugger:Stop()
    ELSE
      ::Debugger := XHDebuggerGUI():new()
   ENDIF
   ::Debugger:Start()
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD DebugStop() CLASS Project
   IF ::Debugger != NIL
      ::Debugger:Stop()
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
FUNCTION GUI_ErrorGrid( oError, cLog )

   LOCAL cFile, cDesc, aErrors := GetLogErrors( cLog ), oApp := __GetApplication()

   oApp:BuildLog:Caption := cLog

   IF EMPTY( aErrors )
      cDesc := oError:Description
      cFile := ""
      IF LEFT( cDesc, 28 ) == "couldn't find required file:"
         cFile := STRTRAN( SUBSTR( cDesc, 29 ), "'" )
         cDesc := "File not found"
      ENDIF
      cDesc := STRTRAN( cDesc, "Couldn't build", "Error creating" )
      AADD( aErrors, { cFile, "0", "I/O Error", cDesc } )
   ENDIF

   oApp:DebugWindow:Show()
   oApp:Yield()
   oApp:ErrorView:ProcessErrors( oError, aErrors, cLog )
   oApp:ErrorView:Parent:Select()
RETURN .T.

//-------------------------------------------------------------------------------------------------------
FUNCTION xBuild_GUI_ONERROR()
   OutputDebugString( "onerror" )
RETURN .T.

//-------------------------------------------------------------------------------------------------------
FUNCTION xBuild_GUI_SETERROR()
RETURN .T.

//------------------------------------------------------------------------------------------------------------------------------------
METHOD GenerateControl( oWnd, cPrefix, cClsName, lChildren, nID, aChildEvents, nInsMetPos, lCustom ) CLASS Project
   LOCAL cText
   LOCAL oChild, Event, n, cResImg, Topic, oCtrl, nPos
   LOCAL cProperty, cChar, aImg
   ( lChildren )

   cText := "//------------------------------------------------------------------------------------------------------------------------------------" + CRLF

   cText += CRLF

   IF !EMPTY( cPreFix ) .AND. RIGHT( cPreFix, 1 ) != "_"
      cPreFix += "_"
   ENDIF

   IF oWnd:ClsName == "CMenuItem"
      IF oWnd:Caption[1] == '-'
         cProperty := "Sep_" + LTrim( Str( nID, 3 ) )
      ELSE
         cProperty := ""
         FOR EACH cChar IN oWnd:Caption
            IF ( cChar >= 'A' .AND. cChar <= 'Z' ) .OR. ( cChar >= 'a' .AND. cChar <= 'z' ) .OR. ( cChar >= '0' .AND. cChar <= '9' ) .OR. cChar == '_'
               cProperty += cChar
            ENDIF
         NEXT
      ENDIF
      oWnd:Name := cProperty
   ENDIF

   cText += "CLASS "+ cPrefix + STRTRAN( oWnd:Name, " ", "_" ) + " INHERIT " + IIF( !lCustom, cClsName, "CustomControl" ) + CRLF
   cText += "   // Components declaration" + CRLF

   IF !EMPTY( oWnd:UserVariables )
      cText += "   // User variables definitions" + CRLF
      cText += "   VAR " + oWnd:UserVariables + CRLF
   ENDIF


   cText += "   METHOD Init() CONSTRUCTOR" + CRLF
   IF oWnd:Modal
      cText += "   METHOD OnInitDialog()" + CRLF
   ENDIF
   cText += CRLF
   cText += "   // Event declaration" + CRLF

   TRY
      FOR EACH Topic IN oWnd:Events
          FOR EACH Event IN Topic[2]
              IF ! EMPTY( Event[2] )
                 AADD( aChildEvents, Event[2] )
              ENDIF
          NEXT
      NEXT
   CATCH
   END

   nInsMetPos := LEN( cText )

   cText += "ENDCLASS" + CRLF + CRLF

   cText += "METHOD Init( oParent, aParameters ) CLASS "+cPrefix+STRTRAN( oWnd:Name, " ", "_" ) + CRLF
   cText += "   ::Super:Init( oParent, aParameters )" + CRLF + CRLF

   FOR EACH Topic IN oWnd:Events
       FOR EACH Event IN Topic[2]
           IF ! EMPTY( Event[2] )
               cText += SPACE( 3 ) + "::EventHandler[ " + ValToPrgExp( Event[1] )+ " ] := " + ValToPrgExp( Event[2] ) + CRLF
           ENDIF
       NEXT
   NEXT

   cText += CRLF
   cText += "   // Populate Components" + CRLF

   // Generate Components
   FOR EACH oChild IN oWnd:Components
       IF ( oChild:__xCtrlName IN {"DataTable","AdsDataTable","MemoryDataTable"} ) .AND. ! Empty( oChild:Driver ) .AND. Empty( oChild:Socket )
          DO CASE
             CASE Upper( oChild:Driver ) == "DBFNTX"

             CASE Upper( oChild:Driver ) == "DBFCDX"
                cText += "   REQUEST DBFCDX, DBFFPT" + CRLF

             CASE LEFT( UPPER( oChild:Driver ), 3 ) == "ADS"
                cText += "   REQUEST ADS" + CRLF

             CASE UPPER( oChild:Driver ) == "ADT"
                cText += "   REQUEST ADS" + CRLF

             OTHERWISE
                cText += "   REQUEST " + oChild:Driver + CRLF
          ENDCASE
       ENDIF
       
       IF oChild:__xCtrlName IN {"BindingSource", "SqlConnector"}
          IF oChild:Server == 0
             AADD( ::__ExtraLibs, "libmysql.lib" )
             AADD( ::__ExtraLibs, "fbclient_ms.lib" )
             AADD( ::__ExtraLibs, "libpq.lib" )
             AADD( ::__ExtraLibs, "oci.lib" )

             cText += "   REQUEST SR_ODBC" + CRLF
             cText += "   REQUEST SR_MYSQL" + CRLF
             cText += "   REQUEST SR_FIREBIRD" + CRLF
           ELSE
             cText += "   REQUEST SR_" + UPPER( oChild:EnumServer[1][ oChild:Server+1 ] )  + CRLF
             IF oChild:aIncLibs[ oChild:Server+1 ] != NIL
                AADD( ::__ExtraLibs, oChild:aIncLibs[ oChild:Server+1 ] )
             ENDIF
          ENDIF
       ENDIF
       
       cText += "   WITH OBJECT ( " + oChild:__xCtrlName + "( Self ) )" + CRLF
       cText += ::GenerateProperties( oChild, 6, ":",,,,, ":This" )

       IF !Empty( oChild:Events )
          FOR EACH Topic IN oChild:Events
              FOR EACH Event IN Topic[2]
                  IF ! EMPTY( Event[2] )
                     AADD( aChildEvents, Event[2] )
                     cText += "      :EventHandler[ " + ValToPrgExp( Event[1] )+ " ] := " + ValToPrgExp( Event[2] ) + CRLF
                  ENDIF
              NEXT
          NEXT
       ENDIF

       // Generate ImageList array of Images
       IF oChild:__xCtrlName == "ImageList" .OR. oChild:__xCtrlName == "HotImageList" .OR. oChild:__xCtrlName == "ImageListSmall"
          IF LEN( oChild:Images ) > 0
             FOR EACH aImg IN oChild:Images
                 n := RAT( "\", aImg[1] ) + 1
                 cResImg := RIGHT( aImg[1], LEN( aImg[1] ) - n + 1 )

                 IF AT( ".", cResImg ) > 0
                    cResImg := STRTRAN( cResImg, " " )
                    cResImg := "_"+UPPER(STRTRAN( cResImg, "." ))

                    cText += '      :AddImage( '+ValToPrgExp(cResImg)+', '+;
                                                 ValToPrgExp(aImg[2])+', '+;
                                                 ValToPrgExp(aImg[3])+', NIL,'+;
                                                 ValToPrgExp(aImg[5])+', '+;
                                                 ValToPrgExp(aImg[1])+' )' + CRLF
                 ENDIF
             NEXT
          ENDIF
       ENDIF

       cText += "      :Create()" + CRLF

       nPos := 1
       FOR EACH oCtrl IN oChild:Children
           cText += ::GenerateChild( oCtrl, 6, @aChildEvents, ":", ":this", nPos )
           nPos++
       NEXT

       cText += "   END //" + oChild:Name + CRLF + CRLF
   NEXT

   cText += "   // Properties declaration" + CRLF

   cText += ::GenerateProperties( oWnd, 3, "::",,,,, "Self" )
   cText += CRLF

   cText += "   ::Create()" + CRLF + CRLF

   cText += "   // Populate Children" + CRLF

   IF ( n := AT( "CoolMenuItem", cPrefix ) ) > 0
      cPrefix := LEFT( cPrefix, n-1 )
   ENDIF

   IF !oWnd:Modal
      nPos := 1
      FOR EACH oChild IN oWnd:Children
          IF oChild:ClsName == "CMenuItem"
             cProperty := ""

             IF oChild:Caption[1] == '-'
                cProperty := "Sep_" + LTrim( Str( nPos, 3 ) )
              ELSE
                FOR EACH cChar IN oChild:Caption
                   IF ( cChar >= 'A' .AND. cChar <= 'Z' ) .OR. ( cChar >= 'a' .AND. cChar <= 'z' ) .OR. ( cChar >= '0' .AND. cChar <= '9' ) .OR. cChar == '_'
                      cProperty += cChar
                   ENDIF
                NEXT
             ENDIF

             cText += "   " + cPrefix + cProperty + "( Self )" + CRLF
           ELSE
             cText += ::GenerateChild( oChild, 3, @aChildEvents, "::", "Self", nPos )
          ENDIF
          nPos++
      NEXT
      IF UPPER(cClsName) == "WINDOW" .OR. UPPER(cClsName) == "MDICHILDWINDOW" .OR. UPPER(cClsName) == "WINFORM"
         cText += "   ::Show()" + CRLF + CRLF
      ENDIF
   ENDIF
   cText += "RETURN Self" + CRLF

   IF oWnd:Modal
      cText += CRLF + "METHOD OnInitDialog() CLASS "+STRTRAN( oWnd:Name, " ", "_" ) + CRLF

      cText += "   // Properties declaration" + CRLF
      cText += ::GenerateProperties( oWnd, 3, "::", , "Opacity",,, "Self" )
      cText += CRLF

      cText += "   // Populate Children" + CRLF
      nPos := 1
      FOR EACH oChild IN oWnd:Children
          cText += ::GenerateChild( oChild, 3, @aChildEvents, "::", "Self", nPos )
          nPos++
      NEXT
      cText += "RETURN Self" + CRLF + CRLF
   ENDIF
RETURN cText

//-------------------------------------------------------------------------------------------------------
#ifdef VXH_PROFESSIONAL
METHOD AddActiveX() CLASS Project
   ListOle( ::Application:MainForm )
RETURN Self
#endif

//-------------------------------------------------------------------------------------------------------
METHOD SetAction( aActions, aReverse ) CLASS Project
   LOCAL x, n, o, nPos, aChildren, aAction, oCtrl, aCtrlProps, nWidth, nHeight

   aAction := ACLONE( aActions[ -1 ] )
   ::Modified := .T.
   IF ::CurrentForm != NIL
      ::CurrentForm:__lModified := .T.
   ENDIF

   IF EMPTY( aAction )
      RETURN Self
   ENDIF
   SWITCH aAction[1]

      CASE DG_ADDCONTROL
           FOR n := 1 TO aAction[10]
               nWidth  := NIL
               nHeight := NIL

               IF aAction[9] != NIL
                  IF ( nPos := ASCAN( aAction[9], {|a|a[1]=="WIDTH"} ) ) > 0
                     nWidth := aAction[9][nPos][2]
                  ENDIF
                  IF ( nPos := ASCAN( aAction[9], {|a|a[1]=="HEIGHT"} ) ) > 0
                     nHeight := aAction[9][nPos][2]
                  ENDIF
               ENDIF

               IF VALTYPE( aAction[7] ) == "C" .AND. aAction[7] == "Splitter" .AND. !EMPTY( aAction[9] )
                  x := ASCAN( aAction[9], {|a| a[1] == "POSITION"} )
                  ::Application:MainForm:FormEditor1:CtrlMask:nSplitterPos := aAction[9][x][2]
               ENDIF

               o := ::Application:MainForm:ToolBox1:SetControl( aAction[7], aAction[2], aAction[3], aAction[4], aAction[6], nWidth, nHeight, aAction[5], @aAction[12], aAction[9], @oCtrl )

               IF o != NIL
                  ReCreateChildren( o, aAction[11] )

                  IF o:__xCtrlName == "DataGrid"
                     o:Create()
                  ENDIF

                  AADD( aReverse, { DG_DELCONTROL, aAction[2], aAction[3], aAction[4], aAction[5], aAction[6], aAction[7], o, , aAction[10], aAction[11], aAction[12]  } )
               ENDIF

               ADEL( aActions, LEN( aActions ), .T. )
               aAction := aActions[ -1 ]
               IF EMPTY( aAction ) .OR. aAction[1] != DG_ADDCONTROL
                  EXIT
               ENDIF
           NEXT
           ::Application:Props[ "EditUndoItem"  ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
           ::Application:Props[ "EditRedoItem"  ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0

           ::Application:Props[ "ComboSelect" ]:Reset(oCtrl)
           RETURN Self

      CASE DG_DELCONTROL
           IF aAction[8]:__CustomOwner
              ::Application:MainForm:MessageBox( "Cannot delete internal components of a Custom Control. Only individual objects can be deleted", "Custom Control", MB_ICONSTOP )
              RETURN NIL
           ENDIF
           o := aAction[8]:Form
           FOR n := 1 TO aAction[10]
               IF aAction[8]:Parent != NIL
                  FOR EACH oCtrl IN aAction[8]:Parent:Children
                      TRY
                         IF oCtrl:Dock:Left == aAction[8]
                            oCtrl:Dock:Left := NIL
                         ENDIF
                       CATCH
                      END
                      TRY
                         IF oCtrl:Dock:Top == aAction[8]
                            oCtrl:Dock:Top := NIL
                         ENDIF
                       CATCH
                      END
                      TRY
                         IF oCtrl:Dock:Right == aAction[8]
                            oCtrl:Dock:Right := NIL
                         ENDIF
                       CATCH
                      END
                      TRY
                         IF oCtrl:Dock:Bottom == aAction[8]
                            oCtrl:Dock:Bottom := NIL
                         ENDIF
                       CATCH
                      END
                  NEXT
               ENDIF
               oCtrl      := aAction[8]
               aCtrlProps := GetCtrlProps( oCtrl ) //, { "NAME" } )
               aChildren  := CollectChildren( aAction[8] )

               IF VALTYPE( aAction[7] ) == "C" .AND. UPPER( aAction[7] ) == "FORM"
                  IF ( x := ASCAN( ::Application:Project:Forms, {|o| o:hWnd == aAction[8]:hWnd } ) ) > 0
                     ::Application:FormsTabs:SendMessage( TCM_DELETEITEM, x - 1 )
                     ADEL( ::Application:Project:Forms, x, .T. )
                     ::Application:MainForm:PostMessage( WM_USER + 3000, x - 1 )
                  ENDIF

                  IF ( x := ASCAN( ::Application:SourceEditor:aDocs, {|o| o == aAction[8]:Editor } ) ) > 0
                     ::Application:SourceTabs:DeleteTab( x )
                     ::Application:SourceEditor:aDocs[x]:Close()
                  ENDIF

               ENDIF
               TRY
                  IF aAction[8]:Owner:ClsName == "CoolBarBand"
                     aAction[8]:Owner:BandChild := NIL
                  ENDIF
                catch
               END

               IF aAction[8]:__xCtrlName == "CustomControl"
                  IF ( x := ASCAN( ::CustomControls, aAction[8]:Reference,,, .T. ) ) > 0
                     ADEL( ::CustomControls, x, .T. )
                  ENDIF
               ENDIF

               aAction[8]:TreeItem:Delete()
               aAction[8]:TreeItem := NIL
               aAction[8]:Destroy()
               TRY
                  aAction[8]:Owner := NIL
                catch
               END

               IF aAction[12] != NIL
                  aAction[12]:Delete()
               ENDIF

               AADD( aReverse, { DG_ADDCONTROL, aAction[2], aAction[3], aAction[4], aAction[5], aAction[6], aAction[7],, aCtrlProps, aAction[10], aChildren, } )


               ADEL( aActions, LEN( aActions ), .T. )
               aAction := aActions[ -1 ]
               IF EMPTY( aAction ) .OR. aAction[1] != DG_DELCONTROL
                  EXIT
               ENDIF
           NEXT
           ::Application:Props[ "EditUndoItem"  ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
           ::Application:Props[ "EditRedoItem"  ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0

           IF !(o == ::CurrentForm)
              TRY
                 o:CtrlMask:Points := NIL
                 o:CtrlMask:CurControl := NIL
                 o:CtrlMask:InvalidateRect()
                 o:CtrlMask:UpdateWindow()
               CATCH
                 o := ::CurrentForm
              END
            ELSE
              o := ::Forms[1]
           ENDIF
           ::Application:Props[ "ComboSelect" ]:Reset()
           TRY
              o:SelectControl( o )
            CATCH
           END
           ::Application:Project:Modified := .T.
           RETURN Self

      CASE DG_MOVESELECTION
           TRY
              IF aAction[5] == 1
                 IF aAction[6] != NIL .AND. !(aAction[6]==aAction[2][1]:Parent)
                    ::CurrentForm:UpdateSelection()
                    o := aAction[2][1]:Parent
                    aAction[2][1]:SetParent( aAction[6] )
                    aAction[6] := o
                 ENDIF

                 FOR n := 1 TO LEN( aAction[2] )
                     MoveWindow( aAction[2][n]:hWnd, aAction[3][n][1], aAction[3][n][2], aAction[3][n][3], aAction[3][n][4] )
                 NEXT
              ENDIF
              AADD( aReverse, { DG_MOVESELECTION, aAction[2], aAction[4], aAction[3], 1, aAction[6], aAction[2][1]:Parent } )
           CATCH
           END

           ADEL( aActions, LEN( aActions ), .T. )

           ::Application:Props[ "EditUndoItem"  ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
           ::Application:Props[ "EditRedoItem"  ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0

           ::CurrentForm:UpdateSelection()

           ::Application:ObjectManager:CheckValue( "Left",   "Position", ::CurrentForm:Selected[1][1]:Left )//+ IIF( __ObjHasMsg( ::CurrentForm:Selected[1][1]:Parent, "HorzScrollPos" ), ::CurrentForm:Selected[1][1]:Parent:HorzScrollPos, 0 ) )
           ::Application:ObjectManager:CheckValue( "Top",    "Position", ::CurrentForm:Selected[1][1]:Top  )//+ IIF( __ObjHasMsg( ::CurrentForm:Selected[1][1]:Parent, "VertScrollPos" ), ::CurrentForm:Selected[1][1]:Parent:VertScrollPos, 0 ) )
           ::Application:ObjectManager:CheckValue( "Width",  "Size",     ::CurrentForm:Selected[1][1]:Width )
           ::Application:ObjectManager:CheckValue( "Height", "Size",     ::CurrentForm:Selected[1][1]:Height )
           RETURN Self

      CASE DG_PROPERTYCHANGED
           ::Application:ObjectManager:SetObjectValue( aAction[2], aAction[3], aAction[4], aAction[5], aAction[6], aAction[7] )//, aAction[8] )
           ::Application:ObjectManager:InvalidateRect(,.F.)
           AADD( aReverse, { DG_PROPERTYCHANGED, aAction[2], aAction[6], aAction[4], aAction[5], aAction[3], aAction[7] } )//, aAction[8]  } )
           hb_gcall()
           EXIT

      CASE DG_FONTCHANGED
           ::Application:ObjectManager:SetActiveObjectFont( aAction[2], aAction[3], aAction[4], aAction[5] )
           AADD( aReverse, { DG_FONTCHANGED, aAction[2], aAction[4], aAction[3], aAction[5] } )
           EXIT
   END
   ADEL( aActions, LEN( aActions ), .T. )
   ::Application:Props[ "EditUndoItem"  ]:Enabled := ::Application:Props[ "EditUndoBttn" ]:Enabled := LEN( ::aUndo ) > 0
   ::Application:Props[ "EditRedoItem"  ]:Enabled := ::Application:Props[ "EditRedoBttn" ]:Enabled := LEN( ::aRedo ) > 0
RETURN Self

//-------------------------------------------------------------------------------------------------------
STATIC FUNCTION CollectChildren( oParent )
   LOCAL aCtrlProps, oChild, aChild, aChildren := {}
   IF oParent != NIL
      TRY
         FOR EACH oChild IN oParent:Children
             aCtrlProps := GetCtrlProps( oChild, { "NAME" } )
             aChild := CollectChildren( oChild )
             AADD( aChildren, { oChild:__xCtrlName, oChild:Left, oChild:Top, oChild:Width, oChild:Height, aCtrlProps, aChild } )
         NEXT
         IF oParent:LeftSplitter != NIL
            aCtrlProps := GetCtrlProps( oParent:LeftSplitter, { "NAME" } )
            AADD( aChildren, { "Splitter", oParent:LeftSplitter:Left, oParent:LeftSplitter:Top, oParent:LeftSplitter:Width, oParent:LeftSplitter:Height, aCtrlProps, {} } )
            oParent:LeftSplitter:Destroy()
         ENDIF
         IF oParent:TopSplitter != NIL
            aCtrlProps := GetCtrlProps( oParent:TopSplitter, { "NAME" } )
            AADD( aChildren, { "Splitter", oParent:TopSplitter:Left, oParent:TopSplitter:Top, oParent:TopSplitter:Width, oParent:TopSplitter:Height, aCtrlProps, {} } )
            oParent:TopSplitter:Destroy()
         ENDIF
         IF oParent:RightSplitter != NIL
            aCtrlProps := GetCtrlProps( oParent:RightSplitter, { "NAME" } )
            AADD( aChildren, { "Splitter", oParent:RightSplitter:Left, oParent:RightSplitter:Top, oParent:RightSplitter:Width, oParent:RightSplitter:Height, aCtrlProps, {} } )
            oParent:RightSplitter:Destroy()
         ENDIF
         IF oParent:BottomSplitter != NIL
            aCtrlProps := GetCtrlProps( oParent:BottomSplitter, { "NAME" } )
            AADD( aChildren, { "Splitter", oParent:BottomSplitter:Left, oParent:BottomSplitter:Top, oParent:BottomSplitter:Width, oParent:BottomSplitter:Height, aCtrlProps, {} } )
            oParent:BottomSplitter:Destroy()
         ENDIF
      CATCH
      END
   ENDIF
RETURN aChildren

//-------------------------------------------------------------------------------------------------------
STATIC FUNCTION ReCreateChildren( oParent, aChildren )
   LOCAL aChild, oChild, aProperty, cProp, aObj, n, oApp := __GetApplication()
   FOR EACH aChild IN aChildren

       IF aChild[1] == "Splitter"
          n := ASCAN( aChild[6], {|a| a[1] == "POSITION"} )
          oApp:MainForm:FormEditor1:CtrlMask:nSplitterPos := aChild[6][n][2]
       ENDIF
       oChild := oApp:MainForm:ToolBox1:SetControl( aChild[1], NIL, aChild[2], aChild[3], oParent, aChild[4], aChild[5], .F.,, aChild[6] )

       FOR EACH aProperty IN aChild[6]
           cProp := aProperty[1]
           TRY
              IF VALTYPE( aProperty[2] ) != "A"
                 __objSendMsg( oChild, "_" + aProperty[1], aProperty[2] )
               ELSE
                 FOR EACH aObj IN aProperty[2]
                     TRY
                        __objSendMsg( oChild:&cProp, "_" + aObj[1], aObj[2] )
                     CATCH
                     END
                 NEXT
              ENDIF
           CATCH
           END
       NEXT
       ReCreateChildren( oChild, aChild[7] )
       IF oChild:__xCtrlName == "DataGrid"
          oChild:Create()
       ENDIF
   NEXT
RETURN NIL

//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------

CLASS ProjProp INHERIT Component

   DATA __TargetTypes EXPORTED INIT { "Executable", "Library", "Dynamic Load Library", "Harbour PCode", "Ole Server" }

   DATA ClsName       EXPORTED INIT "ProjProp"

   DATA TargetType    PUBLISHED INIT 1

   DATA Binary        PUBLISHED INIT "Bin"
   DATA Objects       PUBLISHED INIT "Obj"
   DATA Source        PUBLISHED INIT "Source"
   DATA Resource      PUBLISHED INIT "Resource"

   DATA Name          PUBLISHED
   DATA Path          PUBLISHED

   DATA SourcePath    PUBLISHED INIT ""
   DATA IncludePath   PUBLISHED INIT ""
   DATA CompilerFlags PUBLISHED INIT "-es2 -gc0 -m -n -w -q"
   DATA Definitions   PUBLISHED INIT ""
   DATA CleanBuild    PUBLISHED INIT .F.
   DATA UseDLL        PUBLISHED INIT .F.
   DATA TargetName    PUBLISHED INIT ""
   DATA ThemeActive   PUBLISHED INIT .T.
   DATA Parameters    PUBLISHED INIT ""
   DATA MultiThread   PUBLISHED INIT .F.
   DATA GUI           PUBLISHED INIT .F.

   DATA ClassID       EXPORTED INIT ""
   DATA Files         EXPORTED
   DATA Bookmarks     EXPORTED INIT {}
   DATA Sources       EXPORTED INIT {}
   DATA Binaries      EXPORTED INIT {}
   DATA ExtImages     EXPORTED INIT {}
   DATA Resources     EXPORTED INIT {}

   DATA __IsControl   EXPORTED INIT .F.
   DATA Form          EXPORTED
   DATA oIni          EXPORTED

   METHOD Init()  CONSTRUCTOR
   METHOD Save()
   METHOD GetRectangle() INLINE {0,0,0,0}
ENDCLASS

//------------------------------------------------------------------------------------------------------------------------------------
METHOD Init( cFile ) CLASS ProjProp

   LOCAL n

   IF ! EMPTY( cFile )
      ::oIni := IniFile( cFile )

      n := RAt( "\", cFile )
      IF n > 0
         ::Path := Left( cFile, n - 1 )
      ELSE
         ::Path := ""
      ENDIF

      ::Name          := ::oIni:ReadString( "Project", "Name" )
      ::Binary        := ::oIni:ReadString( "Project", "Bin" )
      ::Objects       := ::oIni:ReadString( "Project", "Obj" )
      ::Source        := ::oIni:ReadString( "Project", "Source" )
      ::Resource      := ::oIni:ReadString( "Project", "Resource" )

      ::Parameters    := ::oIni:ReadString( "Project", "Parameters" )

      ::SourcePath    := ::oIni:ReadString( "Project", "SourcePath" )
      ::IncludePath   := ::oIni:ReadString( "Project", "IncludePath" )
      ::CompilerFlags := ::oIni:ReadString( "Project", "CompilerFlags", "-es2 -gc0 -m -n -q -w" )
      ::Definitions   := ::oIni:ReadString( "Project", "Definitions", "" )
      ::CleanBuild    := IIF( ::oIni:ReadInteger( "Project", "CleanBuild", 0 ) == 1, .T., .F. )
      ::UseDll        := IIF( ::oIni:ReadInteger( "Project", "UseDLL", 0 ) == 1, .T., .F. )
      ::ThemeActive   := IIF( ::oIni:ReadInteger( "Project", "ThemeActive", 1 ) == 1, .T., .F. )
      ::TargetName    := ::oIni:ReadString( "Project", "TargetName" )
      ::TargetType    := ::oIni:ReadInteger( "Project", "TargetType", 1 )

      ::Files         := ::oIni:GetEntries( "Files" )
      ::Sources       := ::oIni:GetEntries( "Sources" )
      ::Binaries      := ::oIni:GetEntries( "Binaries" )

      ::ExtImages     := ::oIni:GetSectionEntries( "ExtImages" )
      ::Resources     := ::oIni:GetSectionEntries( "Resources" )

      ::MultiThread   := IIF( ::oIni:ReadInteger( "Project", "MultiThread", 0 ) == 1, .T., .F. )
      ::GUI           := IIF( ::oIni:ReadInteger( "Project", "GUI", 0 ) == 1, .T., .F. )
      ::ClassID       := ::oIni:ReadString( "Project", "ClassID", "" )
   ENDIF

RETURN Self

//------------------------------------------------------------------------------------------------------------------------------------
METHOD Save() CLASS ProjProp
   LOCAL oWnd, oFile, cSource, cBkMk, n

   oFile := CFile( ::Name + ".vxh" )

   oFile:Path := ::Path

   oFile:FileBuffer := "[Project]"      + CRLF +;
                       "Name="          + ::Name    + CRLF +;
                       "Bin="           + ::Binary + CRLF +;
                       "Obj="           + ::Objects + CRLF +;
                       "Source="        + ::Source + CRLF +;
                       "Resource="      + ::Resource + CRLF +;
                       "Parameters="    + ::Parameters + CRLF +;
                       "SourcePath="    + ::SourcePath + CRLF +;
                       "IncludePath="   + ::IncludePath + CRLF +;
                       "CompilerFlags=" + ::CompilerFlags + CRLF +;
                       "Definitions="   + ::Definitions + CRLF +;
                       "CleanBuild="    + IIF( ::CleanBuild, "1", "0" ) + CRLF +;
                       "UseDLL="        + IIF( ::UseDLL, "1", "0" ) + CRLF +;
                       "ThemeActive="   + IIF( ::ThemeActive, "1", "0" ) + CRLF +;
                       "TargetName="    + ::TargetName + CRLF +;
                       "TargetType="    + XSTR(::TargetType) + CRLF +;
                       "MultiThread="   + IIF( ::MultiThread, "1", "0" ) + CRLF +;
                       "GUI="           + IIF( ::GUI, "1", "0" ) + CRLF +;
                       "ClassID="       + ::ClassID + CRLF +;
                       "[Files]"

   FOR EACH oWnd IN ::Application:Project:Forms
       oFile:FileBuffer += CRLF + oWnd:Name + ".xfm=" + oWnd:Editor:GetBookmarks()
   NEXT

   oFile:FileBuffer += CRLF + "[Sources]"
   FOR EACH cSource IN ::Sources
       cBkMk := ""
       IF ( n := ASCAN( ::Application:SourceEditor:aDocs, {|o| UPPER(o:File)==UPPER(cSource)} ) ) > 0
          cBkMk := ::Application:SourceEditor:aDocs[n]:GetBookmarks()
       ENDIF
       oFile:FileBuffer += CRLF + cSource +"=" + cBkMk
   NEXT

   oFile:FileBuffer += CRLF + "[Binaries]"
   FOR EACH cSource IN ::Binaries
       oFile:FileBuffer += CRLF + cSource +"="
   NEXT

   oFile:FileBuffer += CRLF + "[ExtImages]"
   FOR EACH cSource IN ::ExtImages
       oFile:FileBuffer += CRLF + cSource
   NEXT

   oFile:FileBuffer += CRLF + "[Resources]"
   FOR EACH cSource IN ::Resources
       oFile:FileBuffer += CRLF + cSource
   NEXT

   oFile:FileBuffer += CRLF
   oFile:Save()

RETURN Self

//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------

CLASS ControlObjCombo INHERIT ObjCombo
   DATA Controls EXPORTED INIT {}
   METHOD FillData()
   METHOD SelectControl()
   METHOD Reset()
ENDCLASS

//-------------------------------------------------------------------------------------------------------
METHOD Reset() CLASS ControlObjCombo
   ::ResetContent()
   ::Controls := {}
   ::SetCurSel( -1 )
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD FillData( oWnd ) CLASS ControlObjCombo
   LOCAL Child, cObj, cCaption

   AADD( ::Controls, oWnd )

   cObj := ""
   cCaption := ""
   IF __clsParent( oWnd:ClassH, "COMPONENT" )
      cObj += oWnd:Owner:Name+":"
    ELSEIF oWnd:ClsName != "VXH_FORM_IDE"
      cObj += oWnd:Parent:Name+":"
      cCaption := oWnd:Caption
    ELSE
      cCaption := oWnd:Caption
   ENDIF
   DEFAULT cCaption TO ""

   cObj += oWnd:Name

   ::AddItem( cObj + CHR(9) + cCaption )

   FOR Each Child IN oWnd:Children
       ::FillData( Child )
   NEXT
   IF __objHasMsg( oWnd, "Components" )
      FOR Each Child IN oWnd:Components
          ::FillData( Child )
      NEXT
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SelectControl( oControl, lSetTree ) CLASS ControlObjCombo
   LOCAL n
   DEFAULT lSetTree TO .F.
   IF VALTYPE( oControl ) == "O"
      n := ASCAN( ::Controls, {|o|o == oControl} )
      ::SetCurSel( n-1 )
    ELSE
      IF ( n := ::GetCurSel() + 1 ) > 0
         IF ::Controls[n]:__xCtrlName == "TabPage"
            ::Controls[n]:Select()
         ENDIF
         ::Application:Project:CurrentForm:SelectControl( ::Controls[n] )
      ENDIF
   ENDIF
RETURN Self

//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------

#ifdef VXH_PROFESSIONAL

CLASS ListOle INHERIT Dialog
   DATA aOle    EXPORTED
   DATA aAddOn  EXPORTED
   METHOD Init( oParent ) CONSTRUCTOR
   METHOD OnOk()
   METHOD OnInitDialog()
ENDCLASS

METHOD Init( oParent ) CLASS ListOle
   Super:Init( oParent )
   ::Template := "OLELIST"
   ::Modal    := .T.
   //::DlgModalFrame := .T.
   ::Center   := .T.
   ::aOle     := GetRegOle()
   ::AutoClose := .T.
   ::Create()
RETURN Self

METHOD OnInitDialog() CLASS ListOle
   Super:OnInitDialog()

   WITH OBJECT PictureBox( Self )
      :Height          := 77
      :BackColor       := C_WHITE
      :Type            := "BMP"
      :ImageName       := "Banner"
      :Dock:Margin     := 0
      :Dock:Left       := :Parent
      :Dock:Top        := :Parent
      :Dock:Right      := :Parent
      :Create()
   END

   RegOle( Self )

   WITH OBJECT GroupBox( Self )
      :Caption       := ::aOle[1][1]
      :Dock:Margin   := 5
      :Dock:Left     := :Parent
      :Dock:Top      := :Parent:DataGrid1
      :Dock:Bottom   := :Parent:Button1
      :Dock:Right    := :Parent
      :Create()
      WITH OBJECT Label( :This )
         :Caption  := ::aOle[1][6]
         :Left     := 70
         :Top      := 16
         :Width    := :Parent:Width - :Left
         :Create()
      END
      WITH OBJECT Label( :This )
         :Caption  := ::aOle[1][6]
         :Left     := 70
         :Dock:Margin := 3
         :Dock:Top := ::Label1
         :Height   := :Height * 2
         :Width    := :Parent:Width - :Left
         :Create()
      END
      :MoveWindow()
   END
RETURN 0

METHOD OnOk() CLASS ListOle
   LOCAL oTypeLib, cId

   ::Application:MainForm:ToolBox1:ComObjects := {}

   ::MemoryTable1:GoTop()
   WHILE !::MemoryTable1:Eof()
      IF ::MemoryTable1:Fields:Select == 1
         TRY
            oTypeLib := LoadTypeLib( ::MemoryTable1:Fields:ClsID, .F. )
            cId := oTypeLib:Objects[1]:Name
          CATCH
            cId := STRTRAN( ::MemoryTable1:Fields:ProgID, "." )
         END
         AADD( ::Application:MainForm:ToolBox1:ComObjects, { cId, ::MemoryTable1:Fields:Control, ::MemoryTable1:Fields:ProgID, ::MemoryTable1:Fields:ClsID } )
      ENDIF
      ::MemoryTable1:Skip()
   ENDDO

   ::Application:MainForm:ToolBox1:UpdateComObjects()
   ::Close()
RETURN 0

CLASS RegOle INHERIT DataGrid
   METHOD Init() CONSTRUCTOR
   METHOD OnKeyDown()
   METHOD OnClick()
   METHOD OnRowChanged()
   METHOD OnDestroy()
ENDCLASS

METHOD Init( oParent ) CLASS RegOle
   LOCAL n, cClass, aOle, x, lEnter := .F.
   Super:Init( oParent )
   ::Height        := 300
   ::ShowGrid      := .F.
   ::ItemHeight    := 17

   ::Dock:Margin   := 0
   ::Dock:Left     := ::Parent
   ::Dock:Top      := ::Parent:PictureBox1
   ::Dock:Right    := ::Parent

   ::AutoVertScroll:= .T.
   ::FullRowSelect := .T.

   ::DataSource := MemoryTable( ::Parent )

   WITH OBJECT ::DataSource
      aOle := ::Form:aOle
      :Structure := { {"SELECT", "N", 1}, {"CONTROL", "C", 200}, {"PROGID", "C", 200}, {"CLSID", "C", 200} }
      :Table     := ACLONE( ::Form:aOle )
      FOR n := 1 TO LEN( :Table )
          cClass := :Table[n][2]
          IF ( x := ASCAN( ::Application:MainForm:ToolBox1:ComObjects, {|a| a[3] == cClass } ) ) > 0
             x := 1
          ENDIF
          AINS( :Table[n], 1, x, .T. )
      NEXT
      :Create()
   END

   ::Create()
   ::AutoAddColumns()
   AEVAL( ::Children, {|o| o:Width := 200 } )
   ::Form:GridColumn1:Caption := ""
   ::Form:GridColumn1:Width   := 20
   ::Form:GridColumn1:Representation := 3
   ::Form:GridColumn1:SelOnlyRep := .F.
   ::Update()

   ::SetFocus()
RETURN Self

METHOD OnDestroy() CLASS RegOle
   ::DataSource:GoTop()
   WHILE ! ::DataSource:Eof()
      IF VALTYPE( ::Form:aOle[ ::DataSource:Recno() ][4] ) == "N"
         DestroyIcon( ::Form:aOle[ ::DataSource:Recno() ][4] )
      ENDIF
      ::DataSource:Skip()
   ENDDO
RETURN NIL

METHOD OnRowChanged() CLASS RegOle
   LOCAL hBmp, aBmp, cImage := ::Form:aOle[ ::DataSource:Recno() ][4]
   ::Form:GroupBox1:Caption := ::DataSource:Fields:Control
   ::Form:GroupBox1:Redraw()
   
   IF VALTYPE( ::Form:aOle[ ::DataSource:Recno() ][4] ) == "C"
      aBmp := hb_aTokens( cImage, "," )
      IF LEN( aBmp ) > 1
         hBmp := ExtractIcon( __GetApplication():Instance, aBmp[1], 0 )
         IF hBmp <> 0
            ::Form:aOle[ ::DataSource:Recno() ][4] := hBmp
         ENDIF
      ENDIF
   ENDIF
   hBmp := ::Form:aOle[ ::DataSource:Recno() ][4]
   IF VALTYPE( hBmp ) == "N"
      DrawIconEx( ::Form:GroupBox1:Drawing:hDC, (::Form:GroupBox1:Height/2)-8, 20, hBmp, 32, 32, 0, NIL, DI_NORMAL )
   ENDIF
   ::Form:Label1:Caption := "Version: " + ::Form:aOle[ ::DataSource:Recno() ][5]
   ::Form:Label2:Caption := ::Form:aOle[ ::DataSource:Recno() ][6]
RETURN NIL

METHOD OnClick( nCol, nRow ) CLASS RegOle
   ( nRow )
   IF nCol == 1
      ::DataSource:Fields:Select := IIF( ::DataSource:Fields:Select == 0, 1, 0 )
      ::UpdateRow()
   ENDIF
RETURN 0

METHOD OnKeyDown( nwParam, nlParam ) CLASS RegOle
   IF nwParam == VK_SPACE
      ::DataSource:Fields:Select := IIF( ::DataSource:Fields:Select == 0, 1, 0 )
      ::UpdateRow()
      RETURN 0
   ENDIF
RETURN Super:OnKeyDown( nwParam, nlParam )

#endif

//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------

CLASS MsgBoxEx INHERIT Dialog
   DATA BodyText   EXPORTED INIT ""
   DATA nIcon      EXPORTED
   METHOD Init( oParent ) CONSTRUCTOR
   METHOD OnCommand()
   METHOD OnInitDialog()
ENDCLASS

METHOD Init( oParent, cText, cCaption, nIcon ) CLASS MsgBoxEx
   Super:Init( oParent )
   ::nIcon    := nIcon
   ::Template := "MSGBOXEX"
   ::Modal    := .T.
   ::Caption  := cCaption
   ::Center   := .T.
   ::BodyText := cText
   ::Create()
RETURN Self

METHOD OnInitDialog() CLASS MsgBoxEx
   ::Label1:SetStyle( SS_ICON, .T. )
   ::Label1:SendMessage( STM_SETICON, LoadIcon(, IDI_QUESTION ) )
   ::Label2:Caption := ::BodyText
RETURN 0

METHOD OnCommand() CLASS MsgBoxEx
   ::Close( ::wParam )
RETURN 0

//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------

CLASS StartPageBrushes
   DATA HeaderBkGnd  EXPORTED INIT {,,}
   DATA HeaderLogo   EXPORTED INIT {,,}
   DATA BodyBkGnd    EXPORTED INIT {,,}
   DATA RecentBk     EXPORTED INIT {,,}
   DATA NewsBk       EXPORTED INIT {,,}
   METHOD Init() CONSTRUCTOR
   METHOD Destroy()
ENDCLASS

METHOD Init() CLASS StartPageBrushes
   LOCAL aSiz, hPict := LoadBitmap( GetModuleHandle(), "HEADERBK" )
   aSiz := GetBmpSize( hPict )
   ::HeaderBkGnd[1] := CreatePatternBrush( hPict )
   ::HeaderBkGnd[2] := aSiz[1]
   ::HeaderBkGnd[3] := aSiz[2]
   DeleteObject( hPict )

   hPict := PictureLoadFromResource( GetModuleHandle(), "HEADERLOGO", "JPG" )
   aSiz := PictureGetSize( hPict )
   ::HeaderLogo[1] := hPict
   ::HeaderLogo[2] := aSiz[1]
   ::HeaderLogo[3] := aSiz[2]

   hPict := PictureLoadFromResource( GetModuleHandle(), "BODYBKGND", "GIF" )
   aSiz := PictureGetSize( hPict )
   ::BodyBkGnd[1] := hPict
   ::BodyBkGnd[2] := aSiz[1]
   ::BodyBkGnd[3] := aSiz[2]

   hPict := PictureLoadFromResource( GetModuleHandle(), "RECENTBK", "JPG" )
   aSiz := PictureGetSize( hPict )
   ::RecentBk[1] := hPict
   ::RecentBk[2] := aSiz[1]
   ::RecentBk[3] := aSiz[2]

   hPict := PictureLoadFromResource( GetModuleHandle(), "NEWSBK", "JPG" )
   aSiz := PictureGetSize( hPict )
   ::NewsBk[1] := hPict
   ::NewsBk[2] := aSiz[1]
   ::NewsBk[3] := aSiz[2]
RETURN Self

METHOD Destroy() CLASS StartPageBrushes
   DeleteObject( ::HeaderBkGnd[1] )
   PictureRemove( ::HeaderLogo[1] )
   PictureRemove( ::BodyBkGnd[1] )
   PictureRemove( ::RecentBk[1] )
   PictureRemove( ::NewsBk[1] )
RETURN Self

//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------

CLASS AboutVXH INHERIT Dialog
   DATA Picture    EXPORTED
   DATA Panel      EXPORTED
   DATA LinkLabel1 EXPORTED
   DATA BetaLabel  EXPORTED
   DATA Red        EXPORTED INIT 255
   DATA Green      EXPORTED INIT 255
   DATA Blue       EXPORTED INIT 255
   METHOD Init() CONSTRUCTOR
   METHOD OnInitDialog()
   METHOD LinkLabel1_OnClick()
   METHOD OnTimer()
ENDCLASS

METHOD Init() CLASS AboutVXH
   Super:Init( ::Application:MainForm )
   ::Left          := 0
   ::Top           := 0
   ::Width         := 497
   ::Height        := 300
   ::Center        := .T.
   ::DlgModalFrame := .T.
   ::Style         := WS_POPUP | WS_CAPTION | WS_SYSMENU | DS_MODALFRAME
   ::Caption       := "Visual xHarbour"
   ::Create()
RETURN Self

METHOD OnInitDialog() CLASS AboutVXH
   LOCAL oBtn, oLabel, n, aDev := { "Augusto R. Infante", "Phil Krylov", "Ron Pinkas", "Patrick Mast" }

   //::BackColor   := ::System:Color:White
   WITH OBJECT ( ::Picture := PictureBox( Self ) )
      :Dock:Margin := 0
      :Dock:Left   := Self
      :Dock:Top    := Self
      :Dock:Right  := Self
      :Type        := "BMP"
      :ImageName   := "BANNER"
      :Create()
      :Height      := :PictureHeight
      WITH OBJECT ( ::BetaLabel := LABEL( :this ) )
         :Left           := 210
         :Top            := 0
         :Width          := 300
         :Height         := 62
         :Caption        := VXH_Version
         :Font:FaceName  := "Times New Roman"
         :Font:Bold      := .F.
         :Font:PointSize := 48
         :ForeColor      := C_GREY
         :Create()
      END
      /*
      WITH OBJECT ( LABEL( :this ) )
         :Left           := 363
         :Top            := 61
         :Width          := 300
         :Height         := 20
         :Caption        := "Build: " + VXH_BuildVersion
         :Font:FaceName  := "Tahoma"
         :Font:Bold      := .T.
         :Font:PointSize := 10
         :ForeColor      := C_DARKBLUE
         :Create()
      END
      */
   END

   WITH OBJECT ( oBtn := Button( Self ) )
      :Dock:Bottom := Self
      :Dock:Left   := Self
      :Caption     := "&OK"
      :Id          := IDCANCEL
      :Create()
   END

   WITH OBJECT ( ::Panel := PANEL( Self ) )
      :Dock:Margin := 0
      :Dock:Left   := Self
      :Dock:Top    := ::Picture
      :Dock:Right  := Self
      :Dock:Bottom := oBtn
//      :BackColor   := ::System:Color:LightGray
      :Create()
      WITH OBJECT ( LINKLABEL( :this ) )
         :Left           := 2
         :Dock:Bottom    := :Parent
         :Dock:Right     := :Parent
         :Width          := 90
         :Height         := 15
         :FocusRect      := .F.
         :Caption        := ::Application:MainForm:StatusBarPanel1:Caption
         :Font:Underline := .T.
         :EventHandler[ "OnClick" ] := "LinkLabel1_OnClick"
         :Create()
         :DockIt()
      END

      WITH OBJECT ( oLabel := LABEL( :this ) )
         :Left           := 29
         :Top            := 30
         :Width          := 61
         :Height         := 16
         :Caption        := "Architect:"
         :Font:Underline := .T.
         :Create()
      END

      WITH OBJECT ( oLabel := LABEL( :this ) )
         :Left           := 95
         :Top            := 30
         :Width          := 119
         :Height         := 16
         :Caption        := "Augusto R. Infante"
         //:Font:Bold      := .T.
         //:ForeColor   := ::System:Color:Gray
         :Create()
      END

      WITH OBJECT ( oLabel := LABEL( :this ) )
         :Left           := 17
         :Top            := 50
         :Width          := 69
         :Height         := 16
         :Caption        := "Developers:"
         :Font:Underline := .T.
         :Create()
      END

      FOR n := 1 TO LEN( aDev )
         WITH OBJECT ( oLabel := LABEL( :this ) )
            :Left        := 95
            :Top         := 50 + ( 20 * (n-1) )
            :Width       := 120
            :Height      := 22
            :Caption     := aDev[n]
            //:Font:Bold   := .T.
            //:ForeColor   := ::System:Color:Gray
            :Create()
         END
      NEXT
   END

   ::SetFocus()
RETURN 1

METHOD LinkLabel1_OnClick() CLASS AboutVXH
   ShellExecute( ::hWnd, 'open', "http://www.xharbour.com", , , SW_SHOW )
RETURN Self

METHOD OnTimer( n ) CLASS AboutVXH
   ::BetaLabel:ForeColor := RGB( ::Red, ::Green, ::Blue )
   IF n == 1
      ::KillTimer( 1 )
      IF ::Red > 0
         ::Red -= 5
         ::Red := MAX( ::Red, 0 )
         ::SetTimer( 1, 250 )
       ELSEIF ::Green > 0
         ::Green -= 5
         ::Green := MAX( ::Green, 0 )
         ::SetTimer( 1, 250 )
       ELSEIF ::Blue > 0
         ::Blue -= 5
         ::Blue := MAX( ::Blue, 0 )
         ::SetTimer( 1, 250 )
       ELSE
         ::Red := ::Green := ::Blue := 0
         ::SetTimer( 2, 250 )
      ENDIF
    ELSE
      ::KillTimer( 2 )
      IF ::Red < 255
         ::Red += 5
         ::Red := MIN( ::Red, 255 )
         ::SetTimer( 2, 250 )
       ELSEIF ::Green < 255
         ::Green += 5
         ::Green := MIN( ::Green, 255 )
         ::SetTimer( 2, 250 )
       ELSEIF ::Blue < 255
         ::Blue += 5
         ::Blue := MIN( ::Blue, 255 )
         ::SetTimer( 2, 250 )
       ELSE
         ::Red := ::Green := ::Blue := 255
         ::SetTimer( 1, 250 )
      ENDIF
   ENDIF
RETURN NIL

#ifndef VXH_PROFESSIONAL

   CLASS WebBrowser INHERIT ActiveX
      DATA ProgID        EXPORTED
      DATA ClsID         EXPORTED

      PROPERTY Url READ xUrl WRITE WebNavigate PROTECTED

      METHOD Init() CONSTRUCTOR
      METHOD Create()
      METHOD WebNavigate()
      METHOD OnGetDlgCode() INLINE DLGC_WANTALLKEYS
   ENDCLASS

   METHOD Init( oParent ) CLASS WebBrowser
      DEFAULT ::__xCtrlName TO "WebBrowser"
      Super:Init( oParent )
      ::ProgID  := "Shell.Explorer.2"
   RETURN Self

   METHOD Create() CLASS WebBrowser
      Super:Create()
      IF !EMPTY( ::Url )
         ::WebNavigate( ::Url )
      ENDIF
   RETURN Self

   METHOD WebNavigate( Url ) CLASS WebBrowser
      IF ::__ClassInst == NIL .AND. ::hObj != NIL
         ::Navigate( Url )
      ENDIF
   RETURN Self
#endif

FUNCTION GetLogErrors( sText )
   LOCAL nID := 0, aaErrors := {}, sLine, aMatch, sFile
   LOCAL s_TraceLog := HB_RegExComp( "Type: . >>>(.*)(<<<)?" )
   LOCAL s_ErrorLine := HB_RegExComp( "(?i)(?:[0-9]+00\r+)*(.+)\(([0-9]+)?\):? *(error:|Error [EF][0-9]+) (.+)" )
   LOCAL s_WarningLine := HB_RegExComp( "(?i)(?:[0-9]+00\r+)*(.+)\(([0-9]+)\):? *(warning:|Warning [A-Z][0-9]+) (.+)" )
   LOCAL s_MissingExternal := HB_RegExComp( "(?i)(xLink)(:) *(error:|Error [EF][0-9]+) (.+)" )

   WHILE NextLine( @sText, @sLine )
      IF Empty( sLine )
         LOOP
      ENDIF

      sLine := LTrim( sLine )
      aMatch := HB_Regex( s_TraceLog, sLine )

      IF Empty( aMatch )
         aMatch := HB_Regex( s_ErrorLine, sLine )

         IF Empty( aMatch )
            aMatch := HB_Regex( s_WarningLine, sLine )
         ENDIF

         IF Empty( aMatch )
            aMatch := HB_Regex( s_MissingExternal, sLine )
         ENDIF

         IF ! Empty( aMatch )
            aAdd( aaErrors, aDel( aMatch, 1, .T. )  )
         ENDIF
      ELSE
         IF aMatch[2] = "Couldn't"
            sFile := HB_aTokens( sLine, " " )[-1]
            sFile := Left( sFile, Len( sFile ) - 3 )
            aAdd( aaErrors, { sFile, "", "Error", "Couldn't build" } )
         ELSEIF aMatch[2] = "[In use?]"
            sFile := HB_aTokens( sLine, " " )[-1]
            sFile := Left( sFile, Len( sFile ) - 3 )
            aAdd( aaErrors, { sFile, "", "Error", "[In use?] couldn't erase" } )
         ENDIF
      ENDIF
   END
RETURN aaErrors

FUNCTION PopupEditor()
RETURN NIL

FUNCTION xEditListView()
RETURN NIL
