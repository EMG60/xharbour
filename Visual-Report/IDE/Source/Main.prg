/*
 * $Id$
 */

// Copyright   WinFakt! / SOCS BVBA  http://www.WinFakt.com
//
// This source file is an intellectual property of SOCS bvba.
// You may NOT forward or share this file under any conditions!


//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

static oApp

#ifdef VRDLL
   #include "vxh.ch"
   #include "debug.ch"

   #ifndef __BuildAsOLE
    #pragma BEGINDUMP
       #define CLS_Name "WinFakt.VisualReport.1"
       #define CLS_ID "{A46F16F6-709C-4F6A-A0DA-38335CF8DD16}"
       #include "OleServer.h"
    #pragma ENDDUMP
    REQUEST HB_GT_NUL_DEFAULT
   #endif

   CLASS VR
      DATA oDoc EXPORTED
      DATA oRep EXPORTED
      DATA oApp EXPORTED
      DATA oWait
      METHOD Load()
      METHOD Run( cReport )
      METHOD Preview()       INLINE ::oRep:Preview( ::oApp )
      METHOD Print( lUI )    INLINE IIF( ::oRep != NIL .AND. ::oRep:oPDF != NIL, ::oRep:oPDF:Print( "", lUI ), )
      METHOD Close()
      METHOD Property()
   ENDCLASS

   METHOD Run( cReport, lShowProgress, cText, cTitle ) CLASS VR
      LOCAL oForm
      DEFAULT lShowProgress TO .F.
      IF cReport != NIL
         ::Load( cReport )
      ENDIF
      IF ::oDoc != NIL
         IF lShowProgress
            DEFAULT cText  TO "Generating Report. Please wait..."
            DEFAULT cTitle TO "Visual Report"
            ::oWait := MessageWait( cText, cTitle, .T. )
         ENDIF
         ::oRep:Run( ::oDoc, ::oWait )
         IF lShowProgress .AND. ::oWait != NIL
            ShowWindow( ::oWait:hWnd, SW_HIDE )
         ENDIF
      ENDIF
   RETURN Self

   METHOD Close() CLASS VR
      ::oRep := NIL
      ::oDoc := NIL
      IF ::oWait != NIL
         ::oWait:Destroy()
      ENDIF
   RETURN Self

   METHOD Load( cReport ) CLASS VR
      IF ::oWait != NIL
         ::oWait:Destroy()
      ENDIF
      ::oRep := VrReport()
      ::oDoc := NIL
      IF !EMPTY( ::oRep )
         ::oDoc := TXmlDocument():New( cReport )
         ::oRep:PrepareArrays( ::oDoc )
      ENDIF
   RETURN Self

   METHOD Property( cName, cProp, xValue )
      LOCAL aPanel, n, hObj, xRet, aPanels := {::oRep:aBody,::oRep:aRepHeader,::oRep:aHeader,::oRep:aFooter,::oRep:aRepFooter,::oRep:aExtraPage,::oRep:aComponents}
      FOR EACH aPanel IN aPanels
          IF ( n := ASCAN( aPanel, {|h| UPPER(h:Name) == UPPER(cName) } ) ) > 0
             hObj := aPanel[n]
             xRet := hObj
             IF cProp != NIL
                xRet := hObj[cProp]
                IF xValue != NIL
                   aPanel[n][cProp] := xValue
                ENDIF
             ENDIF
             EXIT
          ENDIF
      NEXT
   RETURN xRet

#else

#include "vxh.ch"
#include "cstruct.ch"
#include "debug.ch"
#include "hbxml.ch"

#define MXML_STYLE_INDENT        1
#define MXML_STYLE_THREESPACES   4

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

PROCEDURE Main( cFile )
   LOCAL oPDF
   SET CENTURY ON
   SET AUTOPEN ON
   REQUEST DBFNTX, DBFDBT, DBFCDX, DBFFPT, ADS, RMDBFCDX, SQLRDD, SR_ODBC, SR_MYSQL, SR_FIREBIRD, SQLEX

   TRY
      oPDF := GetActiveObject( "PDFCreactiveX.PDFCreactiveX" )
   CATCH
      TRY
         oPDF := CreateObject( "PDFCreactiveX.PDFCreactiveX" )
      CATCH
      END
   END
   IF oPDF == NIL
      MessageBox( 0, "Missing internal components. Please contact customer service support." )
    ELSE
      RepApp( cFile )
   ENDIF
   QUIT
RETURN

//-------------------------------------------------------------------------------------------------------

CLASS RepApp INHERIT Application
   DATA aNames   EXPORTED INIT {}
   DATA Props    EXPORTED INIT {=>}
   DATA Report   EXPORTED

   ACCESS Project INLINE ::Report
   METHOD Init() CONSTRUCTOR
ENDCLASS

METHOD Init( cFile ) CLASS RepApp
   oApp := Self
   oApp:Report := Report()
   HSetCaseMatch( ::Props, .F. )
   ::Super:Init( NIL )
   MainForm( NIL )
   ::Run()
RETURN Self

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

CLASS MainForm FROM WinForm
   METHOD Init() CONSTRUCTOR
   METHOD OnClose()
ENDCLASS

METHOD Init() CLASS MainForm
   LOCAL aSize, aEntries, cReport, oItem, aComp, n, i
   ::Super:Init()

   ::Caption := "Visual Report"
   ::Icon    := "AVR"
   ::xName   := "VR"

   //::BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd
   //::OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripPanelGradientEnd }

   ::Create()

   // StatusBar section ----------------------
   WITH OBJECT StatusBar( Self )
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddIcon( "__VR" )
      :Create()
      WITH OBJECT StatusBarPanel( :this )
         :ImageIndex := 1
         :Caption  := "WinFakt! Visual Reporter. Copyright "+CHR(169)+" "+Str(Year(Date()))+" WinFakt! / SOCS BVBA http://www.WinFakt.com. All rights reserved"
         :Width    := :Parent:Drawing:GetTextExtentPoint32( :Caption )[1] + 40
         :Create()
      END
   END

   //--------------------------------------
   WITH OBJECT MenuStrip( ToolStripContainer( Self ):Create() )

      :Row := 1
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )
      :ImageList:MaskColor := ::System:Color:Cyan
      :Create()

      WITH OBJECT ::Application:Props[ "FileMenu" ] := MenuStripItem( :this )
         :ImageList := :Parent:ImageList
         :Caption := "&File"
         :Create()

         WITH OBJECT MenuStripItem( :this )
            :Caption           := "&New"
            :ImageIndex        := ::System:StdIcons:FileNew
            :ShortCutText      := "Ctrl+N"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Key   := ASC( "N" )
            :Action            := {|o| ::Application:Report:NewReport() }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Caption           := "&Open"
            :ImageIndex        := ::System:StdIcons:FileOpen
            :ShortCutText      := "Ctrl+O"
            :ShortCutKey:Ctrl  := .T.
            :ShortCutKey:Key   := ASC( "O" )
            :Action            := {|o| ::Application:Report:Open() }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "SaveMenu" ] := MenuStripItem( :this )
            :Caption          := "&Save"
            :ImageIndex       := ::System:StdIcons:FileSave
            :Enabled          := .F.
            :ShortCutText     := "Ctrl+S"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "S" )
            :Action     := {|o|::Application:Report:Save() }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "SaveAsMenu" ] := MenuStripItem( :this )
            :Caption    := "Save &As ... "
            :ImageIndex := 0
            :Enabled    := .F.
            :Action     := {|o|::Application:Report:Save(.T.) }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "PageSetupMenu" ] := MenuStripItem( :this )
            :Begingroup := .T.
            :Caption    := "&Page Setup"
            :ShortCutText     := "Ctrl+P"
            :ShortCutKey:Ctrl := .T.
            :ShortCutKey:Key  := ASC( "P" )
            :ImageIndex := 0
            :Enabled    := .F.
            :Action     := {|o|::Application:Report:PageSetup() }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Begingroup := .T.
            :Caption    := "&Exit"
            :ImageIndex := 0
            :Action     := {|o|::Application:MainForm:Close() }
            :Create()
         END

      END

      WITH OBJECT ::Application:Props[ "EditMenu" ] := MenuStripItem( :this )
         :Caption := "&Edit"
         :ImageList := :Parent:ImageList
         :Create()

         WITH OBJECT ::Application:Props[ "EditMenuCopy" ] := MenuStripItem( :this )
            :ImageIndex := ::System:StdIcons:Copy
            :Enabled    := .T.
            :Caption    := "&Copy"
            :Action     := {|| ::Application:Report:EditCopy() }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "EditMenuCut" ] := MenuStripItem( :this )
            :ImageIndex := ::System:StdIcons:Cut
            :Enabled    := .F.
            :Caption    := "&Cut"
            :Action     := {|| ::Application:Report:EditCut() }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "EditMenuPaste" ] := MenuStripItem( :this )
            :ImageIndex := ::System:StdIcons:Paste
            :Enabled    := .T.
            :Caption    := "&Paste"
            :Action     := {|| ::Application:Report:EditPaste() }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :ImageIndex := ::System:StdIcons:Delete
            :Caption    := "&Delete"
            :Action     := {|| ::Application:Report:EditDelete() }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :ImageIndex := ::System:StdIcons:Undo
            :Enabled := .F.
            :Caption := "&Undo"
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :ImageIndex := ::System:StdIcons:Redo
            :Enabled := .F.
            :Caption := "&Redo"
            :Create()
         END
      END

      WITH OBJECT ::Application:Props[ "ViewMenu" ] := MenuStripItem( :this )
         :Caption := "&View"
         :ImageList := :Parent:ImageList
         :Create()

         WITH OBJECT ::Application:Props[ "ViewMenuHeader" ] := MenuStripItem( :this )
            :Caption := "Page &Header"
            :Action  := {|o| o:Checked := !o:Checked, ::Application:Props[ "Header" ]:Visible := o:Checked }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewMenuFooter" ] := MenuStripItem( :this )
            :Caption := "Page &Footer"
            :Action  := {|o| o:Checked := !o:Checked, ::Application:Props[ "Footer" ]:Visible := o:Checked }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewMenuRepHeader" ] := MenuStripItem( :this )
            :BeginGroup := .T.
            :Caption := "&Report Header"
            :Action  := {|o| o:Checked := !o:Checked, ::Application:Props[ "RepHeader" ]:Visible := o:Checked }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewMenuRepFooter" ] := MenuStripItem( :this )
            :Caption := "Report F&ooter"
            :Action  := {|o| o:Checked := !o:Checked, ::Application:Props[ "RepFooter" ]:Visible := o:Checked }
            :Create()
         END

         WITH OBJECT ::Application:Props[ "ViewMenuGrid" ] := MenuStripItem( :this )
            :BeginGroup := .T.
            :Caption := "&Grid"
            :Action  := {|o| o:Checked := !o:Checked, ( ::Application:Props[ "Header" ]:InvalidateRect(),;
                                                        ::Application:Props[ "Body"   ]:InvalidateRect(),;
                                                        ::Application:Props[ "Footer" ]:InvalidateRect(),;
                                                        ::Application:Props[ "ExtraPage" ]:InvalidateRect() )}
            :Checked := ::Application:IniFile:ReadInteger( "View", "Grid", 1 )==1
            :Create()
         END
      END

      WITH OBJECT ::Application:Props[ "HelpMenu" ] := MenuStripItem( :this )
         :Caption := "&Help"
         :ImageList := :Parent:ImageList
         :Create()

         WITH OBJECT MenuStripItem( :this )
            :Caption := "&Help"
            :Action  := {|| MessageBox( , "Sorry, no help available yet.", "Visual Report", MB_OK | MB_ICONEXCLAMATION ) }
            :Create()
         END

         WITH OBJECT MenuStripItem( :this )
            :Caption := "&About"
            :Action  := {|| MessageBox( , ::StatusBarPanel1:Caption, "About Visual Report", MB_OK | MB_ICONINFORMATION ) }
            :Create()
         END
      END
   END

   WITH OBJECT ToolStrip( ::ToolStripContainer1 )
      :ShowChevron := .F.
      :Caption := "Standard"
      :Row     := 2
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )
      :ImageList:MaskColor := ::System:Color:Cyan
      :ImageList:AddBitmap( "TBEXTRA" )
      //:ImageList:AddBitmap( "TREE" )
      :Create()

      WITH OBJECT ToolStripButton( :this )
         :Caption           := "New"
         :ImageIndex        := ::System:StdIcons:FileNew
         :Action            := {|o| ::Application:Report:NewReport() }
         :Create()
      END

      WITH OBJECT ::Application:Props[ "OpenBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:FileOpen
         :ToolTip:Text := "Open"
         :Action       := {|o| ::Application:Report:Open() }
         :DropDown     := 2
         :Create()
         aEntries := ::Application:IniFile:GetEntries( "Recent" )

         FOR EACH cReport IN aEntries
             IF !EMPTY( cReport )
                oItem := MenuStripItem( :this )
                oItem:GenerateMember := .F.
                oItem:Caption := cReport
                oItem:Action  := {|o| ::Application:Report:Open( o:Caption ) }
                oItem:Create()
             ENDIF
         NEXT
      END

      WITH OBJECT ::Application:Props[ "CloseBttn" ] := ToolStripButton( :this )
         :ImageIndex   := 16
         :ToolTip:Text := "Close"
         :Action       := {|o|::Application:Report:Close() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "SaveBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:FileSave
         :ToolTip:Text := "Save"
         :Action       := {|o|::Application:Report:Save() }
         :Enabled      := .F.
         :Create()
      END
   END

   WITH OBJECT ToolStrip( ::ToolStripContainer1 )
      :ShowChevron := .F.
      :Caption := "Edit"
      :Row     := 2
      :Create()
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )

      WITH OBJECT ::Application:Props[ "EditCopyBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Copy
         :ToolTip:Text := "Copy"
         :Action       := {|| ::Application:Report:EditCopy() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditCutBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Cut
         :ToolTip:Text := "Cut"
         :Action       := {||::Application:Report:EditCut() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditPasteBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Paste
         :ToolTip:Text := "Paste"
         :Action       := {|| ::Application:Report:EditPaste() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditDelBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Delete
         :ToolTip:Text := "Delete"
         :Action       := {|| ::Application:Report:EditDelete() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditUndoBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Undo
         :ToolTip:Text := "Undo"
         :BeginGroup   := .F.
         :Action       := {|| ::Application:Report:EditUndo() }
         :Enabled      := .F.
         :Create()
      END

      WITH OBJECT ::Application:Props[ "EditRedoBttn" ] := ToolStripButton( :this )
         :ImageIndex   := ::System:StdIcons:Redo
         :ToolTip:Text := "Redo"
         :Action       := {|| ::Application:Report:EditRedo() }
         :Enabled      := .F.
         :Create()
      END
   END


   WITH OBJECT ToolStrip( ::ToolStripContainer1 )
      :ShowChevron := .F.
      :Row := 2
      :Caption := "Build"
      :ImageList := ImageList( :this, 16, 16 ):Create()
      :ImageList:AddImage( IDB_STD_SMALL_COLOR )
      :ImageList:MaskColor := ::System:Color:Cyan
      :ImageList:AddBitmap( "TBEXTRA" )
      :Create()

      WITH OBJECT ::Application:Props[ "RunBttn" ] := ToolStripButton( :this )
         :ImageIndex      := 18
         :ToolTip:Text    := "Run report (F5)"
         :ShortCutKey:Key := VK_F5
         :Action          := {|o|::Application:Report:Run() }
         :Enabled         := .F.
         :Create()
      END
   END


   WITH OBJECT ::Application:Props[ "ToolBox" ] := ToolBox( Self )
      :Dock:Left      := Self
      :Dock:Top       := ::ToolStripContainer1
      :Dock:Bottom    := ::StatusBar1
      :Dock:Margins   := "2,2,2,2"
      :Text           := "ToolBox"

      :FullRowSelect    := .T.
      :StaticEdge       := .F.
      :ClientEdge       := .F.
      :Border           := .T.

      :NoHScroll        := .T.
      :HasButtons       := .T.
      :LinesAtRoot      := .T.
      :ShowSelAlways    := .T.
      :HasLines         := .F.
      :DisableDragDrop  := .T.

      :Enabled      := .F.
      :Create()
   END

   WITH OBJECT Splitter( Self )
      :Owner := ::Application:Props[ "ToolBox" ]
      :Position := 3
      :Create()
   END

   WITH OBJECT ::Application:Props[ "PropEditor" ] := PropEditor( Self )
      :Width          := 300
      :Height         := 300
      :Dock:Right     := :Parent
      :Dock:Top       := ::ToolStripContainer1
      :Dock:Bottom    := ::StatusBar1
      :Dock:Margins   := "2,2,2,2"

      :FullRowSelect  := .T.
      :Border         := .T.

      :NoHScroll      := .T.
      :HasButtons     := .T.
      :LinesAtRoot    := .T.
      :ShowSelAlways  := .T.

      :Columns := { {120,::System:Color:White}, {120,::System:Color:White} }
      :Create()
      :SetFocus()
      :BackColor := GetSysColor( COLOR_BTNFACE )
      :ExpandAll()
   END

   WITH OBJECT Splitter( Self )
      :Owner := ::Application:Props[ "PropEditor" ]
      :Position := 1
      :Create()
   END

   WITH OBJECT ::Application:Props:Components := ComponentPanel( Self )
      :Dock:Left      := ::Application:Props[ "ToolBox" ]
      :Dock:Right     := ::Application:Props[ "PropEditor" ]
      :Dock:Bottom    := ::StatusBar1
      :Top            := 300
      :Height         := 50
      :StaticEdge     := .F.
      //:FlatCaption    := .T.
      :Border         := .T.
      :GenerateMember := .F.
      :Dock:Margins   := "0,2,0,2"
      :BackColor        := ::System:CurrentScheme:ToolStripGradientBegin
      :OnWMThemeChanged := {|o| o:BackColor := ::System:CurrentScheme:ToolStripGradientBegin }
      :Visible := .T.
      :Create()
   END

   WITH OBJECT ::Application:Props[ "MainTabs" ] := TabStrip( Self )
      :Dock:Left    := ::Application:Props:ToolBox
      :Dock:Top     := ::ToolStripContainer1
      :Dock:Right   := ::Application:Props:PropEditor
      :Dock:Bottom  := ::Application:Props:Components
      :Dock:Margin  := 2
      :Create()

      WITH OBJECT ::Application:Props[ "ReportPageTab" ] := TabPage( :this )
         :Caption    := "Report Page"
         :HorzScroll := .T.
         :BackColor  := ::System:Color:Gray
         :ForeColor  := ::System:Color:LtGray
         :Create()

         WITH OBJECT ::Application:Props[ "RepHeader" ] := RepHeaderEdit( :this )
            :Caption   := "Report Header"
            :BackColor := ::System:Color:White
            :Left      := 2
            :Top       := 2
            :Height    := 100
            :Visible   := .F.
            :Dock:Top  := :Parent
            :Dock:Left := :Parent
            :Dock:Margins := "1,2,0,0"
            :Application:Props[ "ViewMenuRepHeader" ]:Checked := ::Application:IniFile:ReadInteger( "View", "RepHeader", 0 )==1
            :Create()
         END

         WITH OBJECT Splitter( :this )
            :Owner := ::Application:Props[ "RepHeader" ]
            :Position := 4
            :ShowDragging := .T.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "Header" ] := HeaderEdit( :this )
            :Caption      := "Page Header"
            :BackColor    := ::System:Color:White
            :Left         := 1
            :Height       := 100
            :Dock:Margins := "0,0,0,0"
            :Dock:Top     := ::Application:Props[ "RepHeader" ]
            :Visible      := .F.
            :Application:Props[ "ViewMenuHeader" ]:Checked := ::Application:IniFile:ReadInteger( "View", "Header", 0 )==1
            :Create()
         END
         WITH OBJECT Splitter( :this )
            :Owner := ::Application:Props[ "Header" ]
            :Position := 4
            :ShowDragging := .T.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "RepFooter" ] := RepFooterEdit( :this )
            :Caption      := "Report Footer"
            :BackColor    := ::System:Color:White
            :Border       := .T.
            :Left         := 1
            :Top          := 2
            :Height       := 100
            :Dock:Margins := "0,0,0,2"
            :Dock:Bottom  := :Parent
            :Visible      := .F.
            :Application:Props[ "ViewMenuRepFooter" ]:Checked := ::Application:IniFile:ReadInteger( "View", "RepFooter", 0 )==1
            :Create()
         END

         WITH OBJECT Splitter( :this )
            :Owner := ::Application:Props[ "RepFooter" ]
            :Position := 2
            :ShowDragging := .T.
            :Create()
         END

         WITH OBJECT ::Application:Props[ "Footer" ] := FooterEdit( :this )
            :Caption      := "Page Footer"
            :BackColor    := ::System:Color:White
            :Border       := .T.
            :Left         := 1
            :Top          := 2
            :Height       := 100
            :Dock:Margins := "0,0,0,0"
            :Dock:Bottom  := ::Application:Props:RepFooter
            :Visible      := .F.
            :Application:Props[ "ViewMenuFooter" ]:Checked := ::Application:IniFile:ReadInteger( "View", "Footer", 0 )==1
            :Create()
         END

         WITH OBJECT Splitter( :this )
            :Owner := ::Application:Props[ "Footer" ]
            :ShowDragging := .T.
            :Position := 2
            :Create()
         END

         WITH OBJECT ::Application:Props[ "Body" ] := BodyEdit( :this )
            :BackColor    := ::System:Color:White
            :Dock:Margins := "0,0,0,0"
            :Left         := 1
            :Height       := 100
            :Dock:Top     := ::Application:Props:Header
            :Dock:Bottom  := ::Application:Props:Footer
            :Visible      := .F.
            :Create()
         END
      END
      WITH OBJECT ::Application:Props[ "ExtraTab" ] := TabPage( :this )
         :Caption    := "Extra Page"
         :HorzScroll := .T.
         :VertScroll := .T.
         :BackColor  := ::System:Color:Gray
         :ForeColor  := ::System:Color:LtGray
         :Create()
         WITH OBJECT ::Application:Props[ "ExtraPage" ] := ExtraPageEdit( :this )
            :BackColor := ::System:Color:White
            :Left      := 2
            :Top       := 2
            :Height    := 100
            :Visible   := .F.
            :Create()
         END
      END
   END

   ::RestoreLayout(, "Layout")
   ::Application:Props[ "ToolBox" ]:RestoreLayout(, "Layout")
   ::Application:Props[ "PropEditor" ]:RestoreLayout(, "Layout")

   ::Application:Report:ResetQuickOpen()

   ::Show()

RETURN Self

METHOD OnClose() CLASS MainForm
   LOCAL nClose
   IF ::Application:Report != NIL
      IF ( nClose := ::Application:Report:Close() ) != NIL
         RETURN nClose
      ENDIF
   ENDIF

   ::SaveLayout(, "Layout")
   ::Application:Props[ "ToolBox" ]:SaveLayout(, "Layout")
   ::Application:Props[ "PropEditor" ]:SaveLayout(, "Layout")
   ::Application:IniFile:Write( "View", "Header",    IIF( ::Application:Props[ "ViewMenuHeader" ]:Checked, 1, 0 ) )
   ::Application:IniFile:Write( "View", "Footer",    IIF( ::Application:Props[ "ViewMenuFooter" ]:Checked, 1, 0 ) )
   ::Application:IniFile:Write( "View", "Grid",      IIF( ::Application:Props[ "ViewMenuGrid" ]:Checked,   1, 0 ) )
   ::Application:IniFile:Write( "View", "RepHeader", IIF( ::Application:Props[ "ViewMenuRepHeader" ]:Checked, 1, 0 ) )
   ::Application:IniFile:Write( "View", "RepFooter", IIF( ::Application:Props[ "ViewMenuRepFooter" ]:Checked, 1, 0 ) )
RETURN NIL

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------

CLASS Report
   DATA Header, Body, Footer
   DATA VrReport      EXPORTED
   DATA xModified     EXPORTED INIT .F.
   DATA xFileName     EXPORTED INIT ""
   DATA oXMLDoc       EXPORTED
   DATA aCopy         EXPORTED
   DATA aUndo         EXPORTED INIT {}
   DATA aRedo         EXPORTED INIT {}

   ACCESS Modified    INLINE ::xModified
   ASSIGN Modified(l) INLINE oApp:MainForm:Caption := "Visual Report [" + ::GetName() + "]" + IIF( l, " *", "" ), ::xModified := l

   ACCESS FileName    INLINE ::xFileName
   ASSIGN FileName(c) INLINE oApp:MainForm:Caption := "Visual Report [" + ::GetName(c) + "]" + IIF( ::xModified, " *", "" ), ::xFileName := c

   METHOD Save()
   METHOD SaveAs()
   METHOD Close()
   METHOD Open()
   METHOD NewReport()
   METHOD ResetQuickOpen()
   METHOD GetName()
   METHOD GetRectangle() INLINE {0,0,0,0}
   METHOD EditReset()    INLINE NIL
   METHOD Generate()
   METHOD Run()
   METHOD PageSetup()
   METHOD SetScrollArea()
   METHOD EditCopy()     INLINE ::aCopy := ACLONE( oApp:Props:PropEditor:ActiveObject:GetProps() )
   METHOD EditCut()      INLINE ::EditCopy(), ::EditDelete()
   METHOD EditPaste()
   METHOD EditDelete()
   METHOD EditUndo()
   METHOD EditRedo()
ENDCLASS

//-------------------------------------------------------------------------------------------------------
METHOD EditDelete() CLASS Report
   AINS( ::aUndo, 1, { ACLONE( oApp:Props:PropEditor:ActiveObject:GetProps() ), "__DELETE", oApp:Props:PropEditor:ActiveObject }, .T. )
   oApp:Props:EditUndoBttn:Enabled := .T.
   oApp:Props:PropEditor:ActiveObject:Delete()
RETURN NIL

//-------------------------------------------------------------------------------------------------------
METHOD EditUndo() CLASS Report
   LOCAL n, oObj, xVal, cProp, cProp2
   IF VALTYPE( ::aUndo[1][1] ) == "A" .AND. ::aUndo[1][2] == "__MOVESIZE"
      WITH OBJECT ::aUndo[1][3]
         AINS( ::aRedo, 1, { { :Left, :Top, :Width, :Height }, "__MOVESIZE", ::aUndo[1][3] }, .T. )
         :Left   := ::aUndo[1][1][1]
         :Top    := ::aUndo[1][1][2]
         :Width  := ::aUndo[1][1][3]
         :Height := ::aUndo[1][1][4]
      END
    ELSEIF ::aUndo[1][2] == "__DELETE"
      AINS( ::aRedo, 1, ACLONE( ::aUndo[1] ), .T. )
      oObj := ::EditPaste( ::aUndo[1][1] )
      IF oObj:lUI
         n := ASCAN( ::aUndo[1][1], {|a|a[1]=="Left"} )
         oObj:EditCtrl:Left := ::aUndo[1][1][n][2]
         n := ASCAN( ::aUndo[1][1], {|a|a[1]=="Top"} )
         oObj:EditCtrl:Top  := ::aUndo[1][1][n][2]
         oObj:EditCtrl:MoveWindow()
      ENDIF
    ELSE
      cProp  := ::aUndo[1][4]
      cProp2 := ::aUndo[1][5]
      IF cProp2 != NIL
         xVal := ::aUndo[1][3]:&cProp2:&cProp
       ELSE
         xVal := __objSendMsg( ::aUndo[1][3], cProp )
      ENDIF
      AINS( ::aRedo, 1, { xVal, ::aUndo[1][2], ::aUndo[1][3], cProp, cProp2 }, .T. )
      oApp:Props:PropEditor:SetPropValue( ::aUndo[1][1], ::aUndo[1][2], ::aUndo[1][3], ::aUndo[1][4], ::aUndo[1][5] )
   ENDIF
   oApp:Props:PropEditor:ResetProperties( {{ IIF( ::aUndo[1][2]=="__MOVESIZE", ::aUndo[1][3]:Cargo, ::aUndo[1][3] ) }} )
   ::aUndo[1][3]:Parent:InvalidateRect()

   ADEL( ::aUndo, 1, .T. )
   oApp:Props:EditUndoBttn:Enabled := LEN( ::aUndo ) > 0
   oApp:Props:EditRedoBttn:Enabled := LEN( ::aRedo ) > 0
RETURN NIL

//-------------------------------------------------------------------------------------------------------
METHOD EditRedo() CLASS Report
   LOCAL n, oObj, xVal, cProp, cProp2
   IF VALTYPE( ::aRedo[1][1] ) == "A" .AND. ::aRedo[1][2] == "__MOVESIZE"
      WITH OBJECT ::aRedo[1][3]
         AINS( ::aUndo, 1, { { :Left, :Top, :Width, :Height }, "__MOVESIZE", ::aRedo[1][3] }, .T. )
         :Left   := ::aRedo[1][1][1]
         :Top    := ::aRedo[1][1][2]
         :Width  := ::aRedo[1][1][3]
         :Height := ::aRedo[1][1][4]
      END
    ELSEIF ::aRedo[1][2] == "__DELETE"
      AINS( ::aUndo, 1, ACLONE( ::aRedo[1] ), .T. )
      ::aRedo[1][3]:Delete()
    ELSE
      cProp  := ::aRedo[1][4]
      cProp2 := ::aRedo[1][5]
      IF cProp2 != NIL
         xVal := ::aRedo[1][3]:&cProp2:&cProp
       ELSE
         xVal := __objSendMsg( ::aRedo[1][3], cProp )
      ENDIF
      AINS( ::aUndo, 1, { xVal, ::aRedo[1][2], ::aRedo[1][3], cProp, cProp2 }, .T. )
      oApp:Props:PropEditor:SetPropValue( ::aRedo[1][1], ::aRedo[1][2], ::aRedo[1][3], ::aRedo[1][4], ::aRedo[1][5] )
   ENDIF
   oApp:Props:PropEditor:ResetProperties( {{ IIF( ::aRedo[1][2]=="__MOVESIZE", ::aRedo[1][3]:Cargo, ::aRedo[1][3] ) }} )
   ::aRedo[1][3]:Parent:InvalidateRect()

   ADEL( ::aRedo, 1, .T. )
   oApp:Props:EditUndoBttn:Enabled := LEN( ::aUndo ) > 0
   oApp:Props:EditRedoBttn:Enabled := LEN( ::aRedo ) > 0
RETURN NIL

//-------------------------------------------------------------------------------------------------------
METHOD NewReport() CLASS Report
   LOCAL oPs

   IF ::VrReport != NIL .AND. ::Close() != NIL
      RETURN NIL
   ENDIF

   oApp:Props:ToolBox:Enabled       := .T.
   oApp:Props:SaveMenu:Enabled      := .T.
   oApp:Props:SaveAsMenu:Enabled    := .T.
   oApp:Props:CloseBttn:Enabled     := .T.
   oApp:Props:SaveBttn:Enabled      := .T.
   oApp:Props:PageSetupMenu:Enabled := .T.

   oApp:Props[ "CompObjects" ]      := {}

   oApp:Props:ToolBox:RedrawWindow( , , RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN )
   ::FileName := "Untitled.vrt"
   oApp:MainForm:Caption := "Visual Report [" + ::FileName + "]"
   ::VrReport := VrReport( NIL )
   oApp:Props:Components:AddButton( ::VrReport )

   ::VrReport:oPDF:ObjectAttribute( "Pages[1]", "PaperSize", ::VrReport:PaperSize )
   ::VrReport:oPDF:ObjectAttribute( "Pages[1]", "Landscape", ::VrReport:Orientation == __GetSystem():PageSetup:Landscape )

   ::SetScrollArea()

   oApp:Props:RepHeader:InvalidateRect()
   oApp:Props:Header:InvalidateRect()
   oApp:Props:Body:InvalidateRect()
   oApp:Props:Footer:InvalidateRect()
   oApp:Props:RepFooter:InvalidateRect()
   oApp:Props:ExtraPage:InvalidateRect()
RETURN Self

//-------------------------------------------------------------------------------------------------------

METHOD EditPaste( aProps ) CLASS Report
   LOCAL n, oObj, cProp, hPointer
   DEFAULT aProps TO ::aCopy
   hPointer := HB_FuncPtr( aProps[1][2] )
   oObj := HB_Exec( hPointer,, aProps[2][2] )
   oObj:__ClassInst := __ClsInst( oObj:ClassH )
   oObj:Create()
   FOR n := 3 TO LEN( aProps )
       cProp := aProps[n][1]
       IF cProp != "Name"
          IF VALTYPE( aProps[n][2] ) != "O"
             __objSendMsg( oObj, "_" + cProp, aProps[n][2] )
           ELSEIF UPPER( aProps[n][1] ) == "FONT"
             oObj:Font:FaceName  := aProps[n][2]:FaceName
             oObj:Font:PointSize := aProps[n][2]:PointSize
             oObj:Font:Italic    := aProps[n][2]:Italic
             oObj:Font:Bold      := aProps[n][2]:Bold
             oObj:Font:Underline := aProps[n][2]:Underline
          ENDIF
       ENDIF
   NEXT
   oObj:Configure()
   ::Modified := .T.
   oApp:Props:PropEditor:ResetProperties( {{ oObj }} )
   IF ! oObj:lUI
      oApp:Props:Components:AddButton( oObj )
   ENDIF
RETURN oObj

//-------------------------------------------------------------------------------------------------------
METHOD PageSetup() CLASS Report
   LOCAL oPs := PageSetup( oApp:MainForm )
   oPs:Orientation  := ::VrReport:Orientation
   oPs:PaperSize    := ::VrReport:PaperSize

   oPs:LeftMargin   := ::VrReport:LeftMargin
   oPs:TopMargin    := ::VrReport:TopMargin
   oPs:RightMargin  := ::VrReport:RightMargin
   oPs:BottomMargin := ::VrReport:BottomMargin

   IF oPs:Show()
      ::VrReport:Orientation  := oPs:Orientation
      ::VrReport:PaperSize    := oPs:PaperSize

      ::VrReport:LeftMargin   := oPs:LeftMargin
      ::VrReport:TopMargin    := oPs:TopMargin
      ::VrReport:RightMargin  := oPs:RightMargin
      ::VrReport:BottomMargin := oPs:BottomMargin

      ::VrReport:oPDF:ObjectAttribute( "Pages[1]", "PaperSize", oPs:PaperSize )
      ::VrReport:oPDF:ObjectAttribute( "Pages[1]", "Landscape", oPs:Orientation == __GetSystem():PageSetup:Landscape )

      ::SetScrollArea()

      oApp:Props:RepHeader:InvalidateRect()
      oApp:Props:Header:InvalidateRect()
      oApp:Props:Body:InvalidateRect()
      oApp:Props:Footer:InvalidateRect()
      oApp:Props:RepFooter:InvalidateRect()
      oApp:Props:ExtraPage:InvalidateRect()
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD GetName( cName, lExt ) CLASS Report
   LOCAL aName
   DEFAULT cName TO ::FileName
   DEFAULT lExt  TO .T.
   aName := hb_aTokens( cName, "\" )
   cName := ATAIL(aName)
   IF !lExt
      aName := hb_aTokens( ATAIL(aName), "." )
      cName := aName[1]
   ENDIF
RETURN cName

//-------------------------------------------------------------------------------------------------------
METHOD Close() CLASS Report
   LOCAL nClose
   IF ::Modified
       nClose := MessageBox( oApp:MainForm:hWnd, "Save changes to " + ::FileName, "Visual Report", MB_YESNOCANCEL )
       DO CASE
          CASE nClose == IDYES
               IF ! ::Save()
                  RETURN 0
               ENDIF
          CASE nClose == IDCANCEL
               RETURN 0
      END
   ENDIF
   ::oXMLDoc  := NIL
   IF ::VrReport != NIL
      ::VrReport:oPDF:Destroy()
      ::VrReport:oPDF := NIL
   ENDIF
   ::VrReport := NIL
   WITH OBJECT oApp
      :Props:Components:Reset()

      AEVAL( :Props:RepHeader:Objects, {|o|o:EditCtrl:Destroy()} )
      AEVAL( :Props:RepFooter:Objects, {|o|o:EditCtrl:Destroy()} )
      AEVAL( :Props:Header:Objects,    {|o|o:EditCtrl:Destroy()} )

      AEVAL( :Props:Body:Objects,      {|o|IIF( o:EditCtrl != NIL, o:EditCtrl:Destroy(),) } )

      AEVAL( :Props:Footer:Objects,    {|o|o:EditCtrl:Destroy()} )
      AEVAL( :Props:ExtraPage:Objects, {|o|o:EditCtrl:Destroy()} )
      :Props:RepHeader:Objects := {}
      :Props:RepFooter:Objects := {}
      :Props:Header:Objects    := {}
      :Props:Body:Objects      := {}
      :Props:Footer:Objects    := {}
      :Props:ExtraPage:Objects := {}

      :Props:CompObjects       := {}

      :Props:PropEditor:ActiveObject := NIL

      :Props:RepHeader:Visible := .F.
      :Props:Header:Visible    := .F.
      :Props:Body:Visible      := .F.
      :Props:Footer:Visible    := .F.
      :Props:RepFooter:Visible := .F.
      :Props:ExtraPage:Visible := .F.

      :Props:ToolBox:Enabled       := .F.
      :Props:SaveMenu:Enabled      := .F.
      :Props:SaveBttn:Enabled      := .F.
      :Props:SaveAsMenu:Enabled    := .F.
      :Props:CloseBttn:Enabled     := .F.
      :Props:RunBttn:Enabled       := .F.
      :Props:PageSetupMenu:Enabled := .F.

      :Props:ToolBox:RedrawWindow( , , RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN )
      :MainForm:Caption := "Visual Report"
      :Props:PropEditor:ResetProperties( {{ NIL }} )

      :Props:ReportPageTab:HorzScrollSize := 0
      :Props:ReportPageTab:VertScrollSize := 0
      :Props:ExtraTab:HorzScrollSize := 0
      :Props:ExtraTab:VertScrollSize := 0

      :aNames := {}

      dbCloseAll()
   END
RETURN NIL

//-------------------------------------------------------------------------------------------------------
METHOD SetScrollArea() CLASS Report
   LOCAL cx, cy, nX, nY, hDC := GetDC(0)
   nX := GetDeviceCaps( hDC, LOGPIXELSX )
   nY := GetDeviceCaps( hDC, LOGPIXELSY )
   ReleaseDC( 0, hDC )

   cx := Int( ( ::VrReport:oPDF:PageWidth / 1440 ) * nX )
   cy := Int( ( ::VrReport:oPDF:PageLength / 1440 ) * nY )

   oApp:Props:Header:Width    := cx
   oApp:Props:Body:Width      := cx
   oApp:Props:Footer:Width    := cx
   oApp:Props:RepHeader:Width := cx
   oApp:Props:RepFooter:Width := cx
   oApp:Props:ExtraPage:Width := cx
   oApp:Props:ExtraPage:Height := cy

   oApp:Props:ReportPageTab:HorzScrollSize := cx + 4

   oApp:Props:ExtraTab:HorzScrollSize := cx + 4
   oApp:Props:ExtraTab:VertScrollSize := cy + 4

   oApp:Props:ReportPageTab:HorzScroll := .T.

   oApp:Props:RepHeader:Visible := oApp:Props:ViewMenuRepHeader:Checked
   oApp:Props:Header:Visible    := oApp:Props:ViewMenuHeader:Checked
   oApp:Props:Body:Visible      := .T.
   oApp:Props:Footer:Visible    := oApp:Props:ViewMenuFooter:Checked
   oApp:Props:RepFooter:Visible := oApp:Props:ViewMenuRepFooter:Checked
   oApp:Props:ExtraPage:Visible := .T.
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD Open( cReport ) CLASS Report
   LOCAL oFile, pHrb, nX

   IF ::VrReport != NIL .AND. ::Close() != NIL
      RETURN NIL
   ENDIF

   IF cReport == NIL
      oFile := OpenFileDialog( oApp:MainForm )
      oFile:Multiselect := .F.
      oFile:Filter := "Visual Report Files (*.vrt)|*.vrt"
      IF !oFile:Show()
         RETURN NIL
      ENDIF
      cReport := oFile:FileName
   ENDIF

   oApp:Props:CompObjects        := {}
   oApp:Props:ToolBox:Enabled    := .T.
   oApp:Props:SaveMenu:Enabled   := .T.
   oApp:Props:SaveBttn:Enabled   := .T.
   oApp:Props:SaveAsMenu:Enabled := .T.
   oApp:Props:CloseBttn:Enabled  := .T.
   oApp:Props:RunBttn:Enabled    := .T.
   oApp:Props:PageSetupMenu:Enabled := .T.

   oApp:Props:ToolBox:RedrawWindow( , , RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN )
   ::FileName := cReport
   ::ResetQuickOpen( cReport )

   ::VrReport := VrReport( NIL )
   oApp:Props:Components:AddButton( ::VrReport )

   ::SetScrollArea()

   ::oXMLDoc := ::VrReport:Load( cReport )

   ::VrReport:oPDF:ObjectAttribute( "Pages[1]", "PaperSize", ::VrReport:PaperSize )
   ::VrReport:oPDF:ObjectAttribute( "Pages[1]", "Landscape", ::VrReport:Orientation == __GetSystem():PageSetup:Landscape )

   oApp:Props:RepHeader:InvalidateRect()
   oApp:Props:Header:InvalidateRect()
   oApp:Props:Body:InvalidateRect()
   oApp:Props:Footer:InvalidateRect()
   oApp:Props:RepFooter:InvalidateRect()
   oApp:Props:ExtraPage:InvalidateRect()
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD Generate( oCtrl, oXmlNode ) CLASS Report
   LOCAL aProps, oXmlValue, oXmlControl, oSub

   oXmlControl := TXmlNode():new( , "Control" )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "ClsName", NIL, oCtrl:ClassName )
      oXmlControl:addBelow( oXmlValue )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Name", NIL, oCtrl:Name )
      oXmlControl:addBelow( oXmlValue )

      TRY
         oCtrl:WriteProps( @oXmlControl )
      CATCH
      END

   oXmlNode:addBelow( oXmlControl )

   FOR EACH oSub IN oCtrl:Objects
       IF oSub:lUI
          ::Generate( oSub, @oXmlControl )
       ENDIF
   NEXT
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD Save( lSaveAs, cTemp ) CLASS Report
   LOCAL cHrb, cName, n, nHeight, cBuffer, aCtrls, i, pHrb, xhbPath, aCtrl
   LOCAL oFile, cFile
   LOCAL oXmlReport, oXmlProp, hAttr, oXmlSource, oXmlData, oXmlValue, oXmlHeader, oXmlBody, oXmlExtra, oXmlFooter, oRep, oXmlComp

   cFile := cTemp
   DEFAULT cFile TO ::FileName

   DEFAULT lSaveAs TO .F.

   IF cTemp == NIL
      IF ::FileName == "Untitled.vrt" .OR. lSaveAs
         IF ( cName := ::SaveAs() ) == NIL
            RETURN .F.
         ENDIF
         cFile := ::FileName := cName
      ENDIF
   ENDIF

   ::oXMLDoc := TXmlDocument():new()
      oXmlReport := TXmlNode():new( , "Report" )

         IF !EMPTY( aCtrl := oApp:Props:CompObjects )
            oXmlComp := TXmlNode():new( , "Components" )
            FOR n := 1 TO LEN( aCtrl )
                ::Generate( aCtrl[n], @oXmlComp )
            NEXT
            oXmlReport:addBelow( oXmlComp )
         ENDIF

         oXmlProp := TXmlNode():new( , "Properties" )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "FileName", NIL, cFile )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "RepHeaderHeight", NIL, XSTR( oApp:Props:RepHeader:ClientHeight ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "RepFooterHeight", NIL, XSTR( oApp:Props:RepFooter:ClientHeight ) )
            oXmlProp:addBelow( oXmlSource )

            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "HeaderHeight", NIL, XSTR( oApp:Props:Header:ClientHeight ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "FooterHeight", NIL, XSTR( oApp:Props:Footer:ClientHeight ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "Orientation", NIL, XSTR( ::VrReport:Orientation ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "PaperSize", NIL, XSTR( ::VrReport:PaperSize ) )
            oXmlProp:addBelow( oXmlSource )

            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "LeftMargin", NIL, XSTR( ::VrReport:LeftMargin ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "TopMargin", NIL, XSTR( ::VrReport:TopMargin ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "RightMargin", NIL, XSTR( ::VrReport:RightMargin ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "BottomMargin", NIL, XSTR( ::VrReport:BottomMargin ) )
            oXmlProp:addBelow( oXmlSource )

            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "PrintHeader", NIL, IIF( ::VrReport:PrintHeader, "1", "0" ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "PrintRepHeader", NIL, IIF( ::VrReport:PrintRepHeader, "1", "0" ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "PrintFooter", NIL, IIF( ::VrReport:PrintFooter, "1", "0" ) )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "PrintRepFooter", NIL, IIF( ::VrReport:PrintRepFooter, "1", "0" ) )
            oXmlProp:addBelow( oXmlSource )

            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "GroupBy1", NIL, ::VrReport:GroupBy1 )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "GroupBy2", NIL, ::VrReport:GroupBy2 )
            oXmlProp:addBelow( oXmlSource )
            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "GroupBy3", NIL, ::VrReport:GroupBy3 )
            oXmlProp:addBelow( oXmlSource )

            oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "DataSource", NIL, IIF( ::VrReport:DataSource != NIL, ::VrReport:DataSource:Name, "" ) )
         oXmlProp:addBelow( oXmlSource )
      oXmlReport:addBelow( oXmlProp )

      IF !EMPTY( aCtrl := oApp:Props:RepHeader:Objects )
         oXmlHeader := TXmlNode():new( , "RepHeader" )
         FOR n := 1 TO LEN( aCtrl )
             IF aCtrl[n]:lUI
                ::Generate( aCtrl[n], @oXmlHeader )
             ENDIF
         NEXT
         oXmlReport:addBelow( oXmlHeader )
      ENDIF

      IF !EMPTY( aCtrl := oApp:Props:RepFooter:Objects )
         oXmlHeader := TXmlNode():new( , "RepFooter" )
         FOR n := 1 TO LEN( aCtrl )
             IF aCtrl[n]:lUI
                ::Generate( aCtrl[n], @oXmlHeader )
             ENDIF
         NEXT
         oXmlReport:addBelow( oXmlHeader )
      ENDIF

      IF !EMPTY( aCtrl := oApp:Props:Header:Objects )
         oXmlHeader := TXmlNode():new( , "Header" )
         FOR n := 1 TO LEN( aCtrl )
             IF aCtrl[n]:lUI
                ::Generate( aCtrl[n], @oXmlHeader )
             ENDIF
         NEXT
         oXmlReport:addBelow( oXmlHeader )
      ENDIF

      IF !EMPTY( aCtrl := oApp:Props:Footer:Objects )
         oXmlFooter := TXmlNode():new( , "Footer" )
         aCtrl := oApp:Props:Footer:Objects
         FOR n := 1 TO LEN( aCtrl )
             IF aCtrl[n]:lUI
                ::Generate( aCtrl[n], @oXmlFooter )
             ENDIF
         NEXT
         oXmlReport:addBelow( oXmlFooter )
      ENDIF

      IF !EMPTY( aCtrl := oApp:Props:Body:Objects )
         oXmlBody := TXmlNode():new( , "Body" )
         FOR n := 1 TO LEN( aCtrl )
             IF aCtrl[n]:lUI
                ::Generate( aCtrl[n], @oXmlBody )
             ENDIF
         NEXT
         oXmlReport:addBelow( oXmlBody )
      ENDIF

      IF !EMPTY( aCtrl := oApp:Props:ExtraPage:Objects )
         oXmlExtra := TXmlNode():new( , "ExtraPage" )
         oXmlSource := TXmlNode():new( HBXML_TYPE_TAG, "PagePosition", NIL, XSTR(oApp:Props:ExtraPage:PagePosition) )
         oXmlExtra:addBelow( oXmlSource )
         FOR n := 1 TO LEN( aCtrl )
             IF aCtrl[n]:lUI
                ::Generate( aCtrl[n], @oXmlExtra )
             ENDIF
         NEXT
         oXmlReport:addBelow( oXmlExtra )
      ENDIF

   ::oXMLDoc:oRoot:addBelow( oXmlReport )
   ::oXMLDoc:Write( cFile, MXML_STYLE_INDENT | MXML_STYLE_THREESPACES )
   oApp:Props:RunBttn:Enabled    := .T.
   IF cTemp == NIL
      ::Modified := .F.
   ENDIF
RETURN .T.

//-------------------------------------------------------------------------------------------------------
METHOD Run() CLASS Report
   LOCAL oWait, oRep, lRun, cTemp := GetTempPath() + "vrr.xml"
   IF ::Save(, cTemp )
      oWait := oApp:MainForm:MessageWait( "Generating Report. Please wait...", "Visual Report", .T. )
      oRep  := VrReport()

      lRun := oRep:Run( ::oXMLDoc, oWait )
      oWait:Destroy()
      IF lRun
         oRep:Preview()
      ENDIF
      FERASE( cTemp )
   ENDIF
RETURN Self

//-------------------------------------------------------------------------------------------------------
METHOD SaveAs() CLASS Report
   LOCAL oFile
   WITH OBJECT ( oFile := SaveFileDialog( oApp:MainForm ) )
      :FileExtension   := "prg"
      :CheckPathExists := .T.
      :Filter          := "Visual Report Files (*.vrt)|*.vrt"
      IF !:Show() .OR. EMPTY( :FileName )
         RETURN NIL
      ENDIF
   END
RETURN oFile:FileName

//-------------------------------------------------------------------------------------------------------

METHOD ResetQuickOpen( cFile ) CLASS Report
   LOCAL lMembers, aEntries, n, cProject, oItem, nId, nBkHeight, oLink, x, oMenu

   // IniFile Recently open projects
   aEntries := oApp:IniFile:ReadArray( "Recent" )

   IF ! EMPTY( aEntries ) .AND. cFile != NIL .AND. aEntries[1] == cFile
      RETURN NIL
   ENDIF

   AEVAL( aEntries, {|c| oApp:IniFile:DelEntry( "Recent", c ) } )

   IF cFile != NIL .AND. ( n := ASCAN( aEntries, {|c| c == cFile } ) ) > 0
      ADEL( aEntries, n, .T. )
   ENDIF
   IF cFile != NIL .AND. FILE( cFile )
      aIns( aEntries, 1, cFile, .T. )
      IF LEN( aEntries )>=20
         ASIZE( aEntries, 20 )
      ENDIF
   ENDIF

   FOR n := 1 TO LEN( aEntries )
       WITH OBJECT oApp:Props[ "OpenBttn" ]
          IF :Children == NIL .OR. LEN( :Children ) < n
             oItem := MenuStripItem( :this )
             oItem:Create()
           ELSE
             oItem := :Children[n]
          ENDIF
       END
       oItem:Caption := aEntries[n]
       oItem:Action  := {|o| oApp:Report:Open( o:Caption ) }
   NEXT
   oApp:IniFile:Write( "Recent", aEntries )
RETURN Self

#endif