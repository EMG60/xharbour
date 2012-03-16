/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// CommonDialogs.prg                                                                                    *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "vxh.ch"
#include "debug.ch"
#include "commdlg.ch"

#define BIF_NONEWFOLDERBUTTON 0x0200
#define LPUNKNOWN        -4
#define LPPRINTPAGERANGE -4
#define HPROPSHEETPAGE   -4
#define OFN_EX_NOPLACESBAR         0x00000001


CLASS CommonDialogs INHERIT Component
   DATA Style EXPORTED
   METHOD SetStyle()
ENDCLASS

METHOD SetStyle( nStyle, lAdd ) CLASS CommonDialogs
   DEFAULT lAdd TO .T.
   IF lAdd
      ::Style := ::Style | nStyle
    ELSE
      ::Style := ::Style & NOT( nStyle )
   ENDIF
RETURN self

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS ColorDialog INHERIT CommonDialogs
   PROPERTY FullOpen        INDEX CC_FULLOPEN        READ xFullOpen        WRITE SetStyle DEFAULT .T. PROTECTED
   PROPERTY AnyColor        INDEX CC_ANYCOLOR        READ xAnyColor        WRITE SetStyle DEFAULT .T. PROTECTED
   PROPERTY SolidColor      INDEX CC_SOLIDCOLOR      READ xSolidColor      WRITE SetStyle DEFAULT .T. PROTECTED
   PROPERTY PreventFullOpen INDEX CC_PREVENTFULLOPEN READ xPreventFullOpen WRITE SetStyle DEFAULT .F. PROTECTED
   PROPERTY ShowHelp        INDEX CC_SHOWHELP        READ xShowHelp        WRITE SetStyle DEFAULT .F. PROTECTED

   DATA Color           INIT RGB(0,0,0) PUBLISHED

   DATA Colors          EXPORTED INIT {}
   DATA SysDefault      EXPORTED
   DATA Custom          EXPORTED
   DATA aCustom         EXPORTED

   METHOD Init() CONSTRUCTOR
   METHOD Show()
ENDCLASS

METHOD Init( oParent ) CLASS ColorDialog
   ::Style := CC_ANYCOLOR | CC_RGBINIT | CC_SOLIDCOLOR | CC_FULLOPEN
   ::__xCtrlName := "ColorDialog"
   ::ClsName     := "ColorDialog"
   ::ComponentType := "CommonDialog"
   Super:Init( oParent )
RETURN Self

METHOD Show() CLASS ColorDialog
   DEFAULT ::aCustom TO ARRAY(16)
   _ChooseColor( ::Owner:hWnd, @::Color, ::aCustom, ::Style )
RETURN Self

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS FolderBrowserDialog INHERIT CommonDialogs
   DATA Description     INIT ""                         PUBLISHED
   DATA RootFolder      INIT __GetSystem():RootFolders:Desktop PUBLISHED
   DATA SelectedPath    INIT ""                         PUBLISHED
   DATA SelectedId      INIT 0
   PROPERTY ShowNewFolderButton INDEX BIF_NONEWFOLDERBUTTON READ xShowNewFolderButton WRITE SetShowNewFolderButton DEFAULT .T. PROTECTED

   METHOD Init() CONSTRUCTOR
   METHOD Show()
   METHOD BrowseForFolderCallBack()
   METHOD SetShowNewFolderButton()
ENDCLASS

METHOD Init( oParent ) CLASS FolderBrowserDialog
   ::Style := BIF_NEWDIALOGSTYLE | BIF_BROWSEINCLUDEURLS
   ::__xCtrlName := "FolderBrowserDialog"
   ::ClsName     := "FolderBrowserDialog"
   ::ComponentType := "CommonDialog"
   Super:Init( oParent )
RETURN Self

METHOD Show() CLASS FolderBrowserDialog
   LOCAL pCallBack := WinCallBackPointer( HB_ObjMsgPtr( Self, "BrowseForFolderCallBack" ), Self )
   ::SelectedPath := SHBrowseForFolder( ::Owner:hWnd, ::Description, ::Style, ::RootFolder, pCallBack, @::SelectedId )
   FreeCallBackPointer( pCallBack )
RETURN ::SelectedPath

METHOD BrowseForFolderCallBack( hWnd, nMsg, lp ) CLASS FolderBrowserDialog
   LOCAL cBuffer
   SWITCH nMsg
      CASE BFFM_INITIALIZED
         SendMessage( hWnd, BFFM_SETSELECTION, 1, ::SelectedPath )
         EXIT

      CASE BFFM_SELCHANGED
         cBuffer := SHGetPathFromIDList( lp )
         SendMessage( hWnd, BFFM_SETSTATUSTEXT, 0, cBuffer )
   END
RETURN 0

METHOD SetShowNewFolderButton( nStyle, lAdd ) CLASS FolderBrowserDialog
   DEFAULT lAdd TO .T.
   IF !lAdd
      ::Style := ::Style | nStyle
    ELSE
      ::Style := ::Style & NOT( nStyle )
   ENDIF
RETURN self

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS OpenFileDialog INHERIT CommonDialogs
   PROPERTY CheckFileExists  INDEX OFN_FILEMUSTEXIST      READ xCheckFileExists  WRITE SetStyle    DEFAULT .T. PROTECTED
   PROPERTY CheckPathExists  INDEX OFN_PATHMUSTEXIST      READ xCheckPathExists  WRITE SetStyle    DEFAULT .T. PROTECTED
   PROPERTY Multiselect      INDEX OFN_ALLOWMULTISELECT   READ xMultiselect      WRITE SetStyle    DEFAULT .T. PROTECTED
   PROPERTY DeferenceLinks   INDEX OFN_NODEREFERENCELINKS READ xDeferenceLinks   WRITE SetInvStyle DEFAULT .T. PROTECTED
   PROPERTY ReadOnlyChecked  INDEX OFN_READONLY           READ xReadOnlyChecked  WRITE SetStyle    DEFAULT .F. PROTECTED
   PROPERTY RestoreDirectory INDEX OFN_NOCHANGEDIR        READ xRestoreDirectory WRITE SetStyle    DEFAULT .F. PROTECTED
   PROPERTY ShowHelp         INDEX OFN_SHOWHELP           READ xShowHelp         WRITE SetStyle    DEFAULT .F. PROTECTED
   PROPERTY ShowReadOnly     INDEX OFN_HIDEREADONLY       READ xShowReadOnly     WRITE SetInvStyle DEFAULT .F. PROTECTED

   DATA AddExtension     INIT .T. PUBLISHED
   DATA CheckFileExists  INIT .T. PUBLISHED
   DATA FileName                  PUBLISHED
   DATA Filter           INIT ""  PUBLISHED
   DATA DefaultExt                PUBLISHED
   DATA FilterIndex      INIT 1   PUBLISHED
   DATA InitialDirectory INIT ""  PUBLISHED
   DATA Title                     PUBLISHED
   DATA ShowPlacesBar    INIT .T. PUBLISHED
   
   DATA __PrevName    PROTECTED
   DATA __PrevFilter  PROTECTED
   METHOD Init() CONSTRUCTOR
   METHOD Show()
   METHOD SetInvStyle( n, l ) INLINE ::SetStyle( n, !l )
ENDCLASS

METHOD Init( oParent ) CLASS OpenFileDialog
   ::Style := OFN_EXPLORER | OFN_ALLOWMULTISELECT | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY
   ::__xCtrlName := "OpenFileDialog"
   ::ClsName     := "OpenFileDialog"
   ::ComponentType := "CommonDialog"
   Super:Init( oParent )
   IF ::__ClassInst != NIL
      ::FileName := ::Name
   ENDIF
RETURN Self

METHOD Show() CLASS OpenFileDialog
   LOCAL n, cFilter
   LOCAL ofn := (struct OPENFILENAME)

   IF VALTYPE( ::FileName ) == "A"
      ::FileName := ::__PrevName
   ENDIF
   IF ::__PrevFilter != NIL
      ::FilterIndex := ::__PrevFilter
   ENDIF
   
   ::__PrevName   := ::FileName
   ::__PrevFilter := ::FilterIndex

   DEFAULT ::Title TO ::Owner:Caption
   DEFAULT ::FileName TO ""
   
   ofn:lStructSize     := 76
   ofn:hInstance       := ::AppInstance
   ofn:nMaxFile        := 8192 + 1
   ofn:hwndOwner       := ::Owner:hWnd
   ofn:lpstrInitialDir := ::InitialDirectory
   ofn:lpstrFile       := PadR( ::FileName, 8192 )
   ofn:Flags           := ::Style
   ofn:nFilterIndex    := ::FilterIndex
   ofn:lpstrDefExt     := ::DefaultExt
   ofn:lpstrTitle      := ::Title
   
   cFilter := ::Filter
   IF VALTYPE( cFilter ) == "A"
      cFilter := ""
      FOR n := 1 TO LEN( ::Filter )
          cFilter += ::Filter[n][1] + chr( 0 ) + ::Filter[n][2] + chr( 0 )
      NEXT
    ELSE
      IF cFilter[-1] != "|"
         cFilter += "|"
      ENDIF
      cFilter := STRTRAN( cFilter, "|", chr( 0 ) )
   ENDIF

   ofn:lpstrFilter := cFilter
   ofn:FlagsEx     := 0
   IF !::ShowPlacesBar
      ofn:FlagsEx  := OFN_EX_NOPLACESBAR
      ofn:Flags := ofn:Flags | OFN_ENABLEHOOK 
   ENDIF
   IF GetOpenFileName( @ofn )
      ::FilterIndex := ofn:nFilterIndex
      IF ::MultiSelect
         ::FileName := hb_aTokens( ofn:lpstrFile, CHR(0) )
         ADEL( ::FileName, LEN(::FileName), .T. )
         ADEL( ::FileName, LEN(::FileName), .T. )
       ELSE
         ::FileName := Left( ofn:lpstrFile, At( Chr(0), ofn:lpstrFile ) - 1 )
      ENDIF
      RETURN .T.
   ENDIF
RETURN .F.

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS SaveFileDialog INHERIT CommonDialogs
   DATA AddExtension              PUBLISHED INIT .T.
   DATA DefaultExt                PUBLISHED
   DATA FileName                  PUBLISHED
   DATA Filter           INIT ""  PUBLISHED
   DATA FilterIndex      INIT 1   PUBLISHED
   DATA InitialDirectory INIT ""  PUBLISHED
   DATA Title                     PUBLISHED
   DATA ShowPlacesBar    INIT .T. PUBLISHED

   DATA __PrevName    PROTECTED
   DATA __PrevFilter  PROTECTED
   DATA FileExtension EXPORTED
   PROPERTY CheckPathExists  INDEX OFN_PATHMUSTEXIST      READ xCheckPathExists  WRITE SetStyle    DEFAULT .T. PROTECTED
   PROPERTY CheckFileExists  INDEX OFN_FILEMUSTEXIST      READ xCheckFileExists  WRITE SetStyle    DEFAULT .F. PROTECTED
   PROPERTY CreatePrompt     INDEX OFN_CREATEPROMPT       READ xCreatePrompt     WRITE SetStyle    DEFAULT .T. PROTECTED
   PROPERTY DeferenceLinks   INDEX OFN_NODEREFERENCELINKS READ xDeferenceLinks   WRITE SetInvStyle DEFAULT .T. PROTECTED
   PROPERTY RestoreDirectory INDEX OFN_NOCHANGEDIR        READ xRestoreDirectory WRITE SetStyle    DEFAULT .F. PROTECTED
   PROPERTY ShowHelp         INDEX OFN_SHOWHELP           READ xShowHelp         WRITE SetStyle    DEFAULT .F. PROTECTED

   METHOD Init() CONSTRUCTOR
   METHOD Show()
   METHOD SetInvStyle( n, l ) INLINE ::SetStyle( n, !l )
ENDCLASS

METHOD Init( oParent ) CLASS SaveFileDialog
   ::Style := OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_NODEREFERENCELINKS | OFN_CREATEPROMPT 
   ::__xCtrlName := "SaveFileDialog"
   ::ClsName     := "SaveFileDialog"
   ::ComponentType := "CommonDialog"
   Super:Init( oParent )
   IF ::__ClassInst != NIL
      ::FileName := ::Name
   ENDIF
RETURN Self

METHOD Show() CLASS SaveFileDialog
   LOCAL n, cFilter, aFilter, cExt
   LOCAL ofn := (struct OPENFILENAME)

   IF VALTYPE( ::FileName ) == "A"
      ::FileName := ::__PrevName
   ENDIF

   IF ::__PrevFilter != NIL
      ::FilterIndex := ::__PrevFilter
   ENDIF
   
   ::__PrevName   := ::FileName
   ::__PrevFilter := ::FilterIndex

   DEFAULT ::Title TO ::Owner:Caption
   DEFAULT ::FileName TO ""

   ofn:lStructSize     := 76
   ofn:hInstance       := ::AppInstance
   ofn:nMaxFile        := 8192 + 1
   ofn:hwndOwner       := ::Owner:hWnd
   ofn:lpstrInitialDir := ::InitialDirectory
   ofn:lpstrFile       := PadR( ::FileName, 8192 )
   ofn:Flags           := ::Style
   ofn:nFilterIndex    := ::FilterIndex
   ofn:lpstrDefExt     := ::DefaultExt
   ofn:lpstrTitle      := ::Title

   IF ::Filter[-1] != "|"
      ::Filter += "|"
   ENDIF

   cFilter := STRTRAN( ::Filter, "|", chr( 0 ) )

   ofn:lpstrFilter := cFilter

   IF !::ShowPlacesBar
      ofn:FlagsEx  := OFN_EX_NOPLACESBAR
      ofn:Flags := ofn:Flags | OFN_ENABLEHOOK 
   ENDIF

   IF GetSaveFileName( @ofn )
      ::FileName := Left( ofn:lpstrFile, At( Chr(0), ofn:lpstrFile ) - 1 )
      ::FilterIndex := ofn:nFilterIndex
      
      IF ::AddExtension .AND. ofn:nFileExtension == 0
         aFilter := __str2a( ::Filter, "|" )
         IF LEN( aFilter ) > 0 .AND. ::FilterIndex > 0
            cExt := SUBSTR( aFilter[ ::FilterIndex*2 ], 3 )
            n := AT( ";", cExt )
            ::FileExtension := LOWER( SUBSTR( cExt, 1, IIF( n > 0, n-1, LEN( cExt ) ) ) )
            ::FileName += ( "." + ::FileExtension )
         ENDIF
       ELSEIF ofn:nFileExtension > 0
         ::FileExtension := LOWER( SUBSTR( ::FileName, ofn:nFileExtension ) )
      ENDIF
      RETURN .T.
   ENDIF
RETURN .F.

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS PrintDialog INHERIT CommonDialogs
   PROPERTY AllowCurrentPage INDEX PD_NOCURRENTPAGE       READ xAllowCurrentPage WRITE SetInvStyle DEFAULT .F. PROTECTED
   PROPERTY AllowPrintFile   INDEX PD_DISABLEPRINTTOFILE  READ xAllowPrintFile   WRITE SetInvStyle DEFAULT .F. PROTECTED
   PROPERTY AllowSelection   INDEX PD_NOSELECTION         READ xAllowSelection   WRITE SetInvStyle DEFAULT .F. PROTECTED
   PROPERTY AllowSomePages   INDEX PD_NOPAGENUMS          READ xAllowSomePages   WRITE SetInvStyle DEFAULT .F. PROTECTED

   DATA FromPage         INIT 0 PUBLISHED
   DATA ToPage           INIT 0 PUBLISHED
   DATA Copies           INIT 1 PUBLISHED

   DATA PrinterName EXPORTED
   DATA Default     EXPORTED INIT .F.
   DATA DriverName  EXPORTED
   DATA Port        EXPORTED

   METHOD Init() CONSTRUCTOR
   METHOD Show()
   METHOD SetInvStyle( n, l ) INLINE ::SetStyle( n, !l )
ENDCLASS

METHOD Init( oParent ) CLASS PrintDialog
   ::Style := PD_NOCURRENTPAGE | PD_DISABLEPRINTTOFILE | PD_NOSELECTION | PD_NOPAGENUMS
   ::__xCtrlName := "PrintDialog"
   ::ClsName     := "PrintDialog"
   ::ComponentType := "CommonDialog"
   Super:Init( oParent )
RETURN Self

METHOD Show() CLASS PrintDialog
   LOCAL pd, nPtr, advnm, dn

   pd := (struct PRINTDLG)
   pd:hwndOwner           := ::Owner:hWnd
   pd:hInstance           := NIL
   pd:Flags               := ::Style
   pd:nFromPage           := ::FromPage
   pd:nToPage             := ::ToPage

   pd:nMinPage            := 0
   pd:nMaxPage            := 1000
   pd:nCopies             := 1

   IF PrintDlg( @pd )
      IF ! EMPTY( pd:hDevNames )
         IF ( nPtr  := GlobalLock( pd:hDevNames ) ) <> 0
            dn := (struct DEVNAMES)
            dn:Buffer( Peek( nPtr, dn:sizeof ) )
            advnm := Array( 4 )
            ::DriverName  := Peek( nPtr + dn:wDriverOffset )
            ::PrinterName := Peek( nPtr + dn:wDeviceOffset )
            ::Port        := Peek( nPtr + dn:wOutputOffset )
            ::Default     := dn:wDefault == 1
            GlobalUnlock( pd:hDevNames )
         ENDIF
         GlobalFree( pd:hDevNames )
      ENDIF

      ::FromPage  := pd:nFromPage
      ::ToPage    := pd:nToPage
      ::Copies    := pd:nCopies
      RETURN .T.
   ENDIF
RETURN .F.

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS FontDialog INHERIT CommonDialogs
   //DATA cf   EXPORTED
   DATA Font PUBLISHED
   METHOD Init() CONSTRUCTOR
   METHOD Show()
ENDCLASS

METHOD Init( oParent ) CLASS FontDialog
   ::Style          := CF_SCREENFONTS | CF_INITTOLOGFONTSTRUCT | CF_EFFECTS
   ::__xCtrlName    := "FontDialog"
   ::ClsName        := "FontDialog"
   ::ComponentType  := "CommonDialog"
   Super:Init( oParent )

   ::Font := Font()
   ::Font:Parent := Self
   IF ::__ClassInst != NIL
      ::Font:Create()
   ENDIF
RETURN Self

METHOD Show( oParent ) CLASS FontDialog
   LOCAL lRet
   ::Font:Create()
   lRet := ::Font:Choose( IIF( oParent != NIL, oParent, ::Owner ),, ::Style ) != NIL
   ::Font:Delete()
RETURN lRet

//------------------------------------------------------------------------------------------------
CLASS FontDialogFont
   DATA Name  PUBLISHED
   DATA Owner       EXPORTED
   DATA ClsName     EXPORTED INIT "FontDialogFont"
   DATA __ClassInst EXPORTED
   ACCESS Parent INLINE ::Owner
   METHOD Init() CONSTRUCTOR
   METHOD Choose() INLINE ::Owner:Show()
ENDCLASS

METHOD Init( oOwner ) CLASS FontDialogFont
   ::Owner     := oOwner
   ::__ClassInst := __ClsInst( ::ClassH )
RETURN Self

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS PageSetup INHERIT CommonDialogs
   PROPERTY ReturnDefault  INDEX PSD_RETURNDEFAULT  READ xReturnDefault  WRITE SetStyle DEFAULT .F. PROTECTED
   PROPERTY DisableMargins INDEX PSD_DISABLEMARGINS READ xDisableMargins WRITE SetStyle DEFAULT .T. PROTECTED

   DATA PaperSize       PUBLISHED INIT DMPAPER_LETTER
   DATA Orientation     PUBLISHED INIT DMORIENT_PORTRAIT
   DATA EnumPaperSize   EXPORTED
   DATA EnumOrientation EXPORTED INIT { { "Portrait", "Landscape" }, {__GetSystem():PageSetup:Portrait, __GetSystem():PageSetup:Landscape} }

   DATA PrinterName  EXPORTED
   DATA Default      EXPORTED INIT .F.
   DATA DriverName   EXPORTED
   DATA Port         EXPORTED
   
   DATA PageWidth    EXPORTED
   DATA PageHeight   EXPORTED

   DATA LeftMargin   EXPORTED INIT 1000
   DATA TopMargin    EXPORTED INIT 1000
   DATA RightMargin  EXPORTED INIT 1000
   DATA BottomMargin EXPORTED INIT 1000

   DATA psd          EXPORTED
   METHOD Init() CONSTRUCTOR
   METHOD Show()
   METHOD SetInvStyle( n, l ) INLINE ::SetStyle( n, !l )
ENDCLASS

METHOD Init( oParent ) CLASS PageSetup
   LOCAL n
   ::Style := PSD_DEFAULTMINMARGINS | PSD_MARGINS
   ::__xCtrlName := "PageSetup"
   ::ClsName     := "PageSetup"
   ::ComponentType := "CommonDialog"
   ::EnumPaperSize := {{},{}}
   ::psd := (struct PAGESETUPDLG)
   
   FOR n := 1 TO LEN( ::System:PaperSize )
       AADD( ::EnumPaperSize[1], ::System:PaperSize[n][1] )
       AADD( ::EnumPaperSize[2], ::System:PaperSize[n][2] )
   NEXT

   Super:Init( oParent )
RETURN Self

METHOD Show() CLASS PageSetup
   LOCAL nPtr, advnm, dn, nOrientation, nPaperSize, nWidth, nLenght
   nOrientation := ::Orientation
   nPaperSize   := ::PaperSize
   nLenght      := ::PageHeight
   nWidth       := ::PageWidth
   
   ::psd:hwndOwner       := ::Owner:hWnd
   ::psd:Flags           := ::Style
   ::psd:ptPaperSize:x   := ::PageWidth
   ::psd:ptPaperSize:y   := ::PageHeight

   ::psd:rtMargin:Left   := ::LeftMargin
   ::psd:rtMargin:Top    := ::TopMargin
   ::psd:rtMargin:Right  := ::RightMargin
   ::psd:rtMargin:Bottom := ::BottomMargin

   IF PageSetupDlg( @::psd, @nOrientation, @nPaperSize, @nWidth, @nLenght )
      IF ! EMPTY( ::psd:hDevNames )
         IF ( nPtr  := GlobalLock( ::psd:hDevNames ) ) <> 0
            dn := (struct DEVNAMES)
            dn:Buffer( Peek( nPtr, dn:sizeof ) )
            advnm := Array( 4 )
            ::DriverName  := Peek( nPtr + dn:wDriverOffset )
            ::PrinterName := Peek( nPtr + dn:wDeviceOffset )
            ::Port        := Peek( nPtr + dn:wOutputOffset )
            ::Default     := dn:wDefault == 1
            GlobalUnlock( ::psd:hDevNames )
         ENDIF
         GlobalFree( ::psd:hDevNames )
      ENDIF
      ::Orientation  := nOrientation
      ::PaperSize    := nPaperSize
      
      ::LeftMargin   := ::psd:rtMargin:Left
      ::TopMargin    := ::psd:rtMargin:Top
      ::RightMargin  := ::psd:rtMargin:Right
      ::BottomMargin := ::psd:rtMargin:Bottom
      
      ::PageWidth    := nWidth
      ::PageHeight   := nLenght
      RETURN .T.
   ENDIF
RETURN .F.

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

#define TDF_ENABLE_HYPERLINKS               0x0001
#define TDF_USE_HICON_MAIN                  0x0002
#define TDF_USE_HICON_FOOTER                0x0004
#define TDF_ALLOW_DIALOG_CANCELLATION       0x0008
#define TDF_USE_COMMAND_LINKS               0x0010
#define TDF_USE_COMMAND_LINKS_NO_ICON       0x0020
#define TDF_EXPAND_FOOTER_AREA              0x0040

#define TDF_EXPANDED_BY_DEFAULT             0x0080
#define TDF_VERIFICATION_FLAG_CHECKED       0x0100
#define TDF_SHOW_PROGRESS_BAR               0x0200
#define TDF_SHOW_MARQUEE_PROGRESS_BAR       0x0400
#define TDF_CALLBACK_TIMER                  0x0800
#define TDF_POSITION_RELATIVE_TO_WINDOW     0x1000
#define TDF_RTL_LAYOUT                      0x2000
#define TDF_NO_DEFAULT_RADIO_BUTTON         0x4000
#define TDF_CAN_BE_MINIMIZED                0x8000

#define TDCBF_OK_BUTTON                     0x0001
#define TDCBF_YES_BUTTON                    0x0002
#define TDCBF_NO_BUTTON                     0x0004
#define TDCBF_CANCEL_BUTTON                 0x0008
#define TDCBF_RETRY_BUTTON                  0x0010
#define TDCBF_CLOSE_BUTTON                  0x0020
   

CLASS TaskDialog INHERIT CommonDialogs
   DATA __Flags         PROTECTED INIT 0
   DATA __ComBttns      PROTECTED INIT 0
   
   DATA ButtonPressed           EXPORTED
   DATA RadioButton             EXPORTED
   DATA VerificationFlagChecked EXPORTED
   
   DATA Buttons         PUBLISHED INIT ""
   DATA MainInstruction PUBLISHED INIT ""
   DATA Content         PUBLISHED INIT ""
   DATA WindowTitle     PUBLISHED INIT ""
   DATA Footer          PUBLISHED INIT ""

   PROPERTY EnableHyperlinks         INDEX TDF_ENABLE_HYPERLINKS           READ xEnableHyperlinks         WRITE __SetFlags DEFAULT .F.
   PROPERTY UseIconMain              INDEX TDF_USE_HICON_MAIN              READ xUseIconMain              WRITE __SetFlags DEFAULT .F.
   PROPERTY UseIconFooter            INDEX TDF_USE_HICON_FOOTER            READ xUseIconFooter            WRITE __SetFlags DEFAULT .F.
   PROPERTY AllowDialogCancellation  INDEX TDF_ALLOW_DIALOG_CANCELLATION   READ xAllowDialogCancellation  WRITE __SetFlags DEFAULT .F.
   PROPERTY UseCommandLinks          INDEX TDF_USE_COMMAND_LINKS           READ xUseCommandLinks          WRITE __SetFlags DEFAULT .F.
   PROPERTY UseCommandLinksNoIcon    INDEX TDF_USE_COMMAND_LINKS_NO_ICON   READ xUseCommandLinksNoIcon    WRITE __SetFlags DEFAULT .F.
   PROPERTY ExpandFooterArea         INDEX TDF_EXPAND_FOOTER_AREA          READ xExpandFooterArea         WRITE __SetFlags DEFAULT .F.
   PROPERTY ExpandedByDefault        INDEX TDF_EXPANDED_BY_DEFAULT         READ xExpandedByDefault        WRITE __SetFlags DEFAULT .F.
   PROPERTY VerificationFlagChecked  INDEX TDF_VERIFICATION_FLAG_CHECKED   READ xVerificationFlagChecked  WRITE __SetFlags DEFAULT .F.
   PROPERTY ShowProgressBar          INDEX TDF_SHOW_PROGRESS_BAR           READ xShowProgressBar          WRITE __SetFlags DEFAULT .F.
   PROPERTY ShowMarqueeProgressBar   INDEX TDF_SHOW_MARQUEE_PROGRESS_BAR   READ xShowMarqueeProgressBar   WRITE __SetFlags DEFAULT .F.
   PROPERTY CallbackTimer            INDEX TDF_CALLBACK_TIMER              READ xCallbackTimer            WRITE __SetFlags DEFAULT .F.
   PROPERTY PositionRelativeToWindow INDEX TDF_POSITION_RELATIVE_TO_WINDOW READ xPositionRelativeToWindow WRITE __SetFlags DEFAULT .F.
   PROPERTY RTLLayout                INDEX TDF_RTL_LAYOUT                  READ xRTLLayout                WRITE __SetFlags DEFAULT .F.
   PROPERTY NoDefaultRadioButton     INDEX TDF_NO_DEFAULT_RADIO_BUTTON     READ xNoDefaultRadioButton     WRITE __SetFlags DEFAULT .F.   
   PROPERTY CanBeMinimized           INDEX TDF_CAN_BE_MINIMIZED            READ xCanBeMinimized           WRITE __SetFlags DEFAULT .F.   

   PROPERTY OK_Button                INDEX TDCBF_OK_BUTTON                 READ xOK_Button                WRITE __SetBttns DEFAULT .F.   
   PROPERTY YES_Button               INDEX TDCBF_YES_BUTTON                READ xYES_Button               WRITE __SetBttns DEFAULT .F.   
   PROPERTY NO_Button                INDEX TDCBF_NO_BUTTON                 READ xNO_Button                WRITE __SetBttns DEFAULT .F.   
   PROPERTY CANCEL_Button            INDEX TDCBF_CANCEL_BUTTON             READ xCANCEL_Button            WRITE __SetBttns DEFAULT .F.   
   PROPERTY RETRY_Button             INDEX TDCBF_RETRY_BUTTON              READ xRETRY_Button             WRITE __SetBttns DEFAULT .F.   
   PROPERTY CLOSE_Button             INDEX TDCBF_CLOSE_BUTTON              READ xCLOSE_Button             WRITE __SetBttns DEFAULT .F.   

   METHOD Init() CONSTRUCTOR
   METHOD Show()
   METHOD __SetFlags()
   METHOD __SetBttns()
ENDCLASS

METHOD Init( oParent ) CLASS TaskDialog
   ::__xCtrlName   := "TaskDialog"
   ::ClsName       := "TaskDialog"
   ::ComponentType := "CommonDialog"
   Super:Init( oParent )
RETURN Self

METHOD Show() CLASS TaskDialog
   LOCAL n, nRet, nButton := 0, nRadio := 0, lChecked := .F.
   IF VALTYPE( ::Buttons ) == "C"
      ::Buttons := hb_aTokens( ::Buttons, "|" )
      FOR n := 1 TO LEN( ::Buttons )
          ::Buttons[n] := hb_aTokens( ::Buttons[n], "," )
          ::Buttons[n][1] := VAL(::Buttons[n][1])
      NEXT
   ENDIF
   nRet := TaskDialogProc( ::Form:hWnd,;
                           ::Form:AppInstance,;
                           ::Buttons,;
                           ::MainInstruction,;
                           ::Content,;
                           ::__Flags,;
                           ::__ComBttns,;
                           ::WindowTitle,;
                           ::Footer,;
                           @nButton, @nRadio, @lChecked )
   ::ButtonPressed := nButton
   ::RadioButton   := nRadio
   ::VerificationFlagChecked := lChecked
RETURN nButton != IDCANCEL

METHOD __SetFlags( nFlags, lAdd ) CLASS TaskDialog
   DEFAULT lAdd TO .T.
   IF lAdd
      ::__Flags := ::__Flags | nFlags
    ELSE
      ::__Flags := ::__Flags & NOT( nFlags )
   ENDIF
RETURN self

METHOD __SetBttns( nButton, lAdd ) CLASS TaskDialog
   DEFAULT lAdd TO .T.
   IF lAdd
      ::__ComBttns := ::__ComBttns | nButton
    ELSE
      ::__ComBttns := ::__ComBttns & NOT( nButton )
   ENDIF
RETURN self

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS FindTextDialog INHERIT CommonDialogs
   DATA pfr EXPORTED
   METHOD Init() CONSTRUCTOR
   METHOD Show()
ENDCLASS

METHOD Init( oOwner ) CLASS FindTextDialog
   ::__xCtrlName    := "FindTextDialog"
   ::ClsName        := "FindTextDialog"
   ::ComponentType  := "CommonDialog"
   Super:Init( oOwner )
   ::pfr := (struct FINDREPLACE)
RETURN Self

METHOD Show( oOwner ) CLASS FindTextDialog
   DEFAULT oOwner TO ::Owner
   ::pfr:hwndOwner     := oOwner:hWnd
   ::pfr:lStructSize   := ::pfr:sizeOf()
   ::pfr:lpstrFindWhat := ""
   ::pfr:wFindWhatLen  := 255
   ::pfr:Flags         := 0
RETURN FindText( @::pfr )

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

CLASS ReplaceTextDialog INHERIT CommonDialogs
   DATA pfr EXPORTED
   METHOD Init() CONSTRUCTOR
   METHOD Show()
ENDCLASS

METHOD Init( oOwner ) CLASS ReplaceTextDialog
   ::__xCtrlName    := "ReplaceTextDialog"
   ::ClsName        := "ReplaceTextDialog"
   ::ComponentType  := "CommonDialog"
   Super:Init( oOwner )
   ::pfr := (struct FINDREPLACE)
RETURN Self

METHOD Show( oOwner ) CLASS ReplaceTextDialog
   DEFAULT oOwner TO ::Owner
   ::pfr:hwndOwner        := oOwner:hWnd
   ::pfr:lStructSize      := ::pfr:sizeOf()
   ::pfr:lpstrFindWhat    := ""
   ::pfr:lpstrReplaceWith := ""
   ::pfr:wFindWhatLen     := 255
   ::pfr:wReplaceWithLen  := 255
   ::pfr:Flags            := 0
RETURN ReplaceText( @::pfr )

