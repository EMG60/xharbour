/*
 * $Id$
 */

//-----------------------------------------------------------------------------------------------
// Copyright   WinFakt! / SOCS BVBA  http://www.WinFakt.com
//
// This source file is an intellectual property of SOCS bvba.
// You may NOT forward or share this file under any conditions!
//-----------------------------------------------------------------------------------------------

#include "debug.ch"
#include "vxh.ch"
#include "hbxml.ch"

#define  acObjectTypeText           5

CLASS VrLabel INHERIT VrObject
   PROPERTY Text      READ xText WRITE SetText
   DATA AutoResize    EXPORTED  INIT .F.
   DATA Picture       EXPORTED  INIT ""
   DATA ClsName       EXPORTED  INIT "Label"
   DATA SysBackColor  EXPORTED  INIT GetSysColor( COLOR_WINDOW )
   DATA SysForeColor  EXPORTED  INIT GetSysColor( COLOR_BTNTEXT )
   DATA BackColor     EXPORTED  INIT GetSysColor( COLOR_WINDOW )
   DATA ForeColor     EXPORTED  INIT GetSysColor( COLOR_BTNTEXT )
   DATA EnumType      EXPORTED  INIT {{"Header","Record","Footer"},{1,2,3}}
   DATA TextAngle     EXPORTED  INIT 0
   DATA xSingleLine   EXPORTED  INIT .T.
   DATA Height        EXPORTED  INIT 16

   ACCESS SingleLine    INLINE ::xSingleLine
   ASSIGN SingleLine(l) INLINE ::xSingleLine := l, IIF( ::EditCtrl != NIL, ( ::EditCtrl:aSize := IIF( ! l, {.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.}, {.F.,.T.,.F.,.F.,.F.,.T.,.F.,.F.} ), ::EditCtrl:Redraw() ), )

   METHOD Init()  CONSTRUCTOR
   METHOD Create()
   METHOD SetText()
   METHOD Draw()
   METHOD WriteProps()
   METHOD Configure()
   METHOD GetFormulas()
ENDCLASS

//-----------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS VrLabel
   IF oParent != NIL
      Super:Init( oParent )
      AADD( ::aProperties, { "BackColor",  "Color"   } )
      AADD( ::aProperties, { "ForeColor",  "Color"   } )
      AADD( ::aProperties, { "Font",       "General" } )
      AADD( ::aProperties, { "Text",       "General" } )
      AADD( ::aProperties, { "TextAngle",  "General" } )
      AADD( ::aProperties, { "Picture",    "General" } )
      AADD( ::aProperties, { "SingleLine", "General" } )
      AADD( ::aProperties, { "Width",      "Size"    } )
      AADD( ::aProperties, { "Height",     "Size"    } )
      AADD( ::aProperties, { "AutoResize", "Size"    } )
      AADD( ::aProperties, { "Name",       "Object"  } )
   ENDIF
   DEFAULT ::Font TO Font()
   ::Font:AllowHandle := oParent != NIL
RETURN Self

METHOD Create() CLASS VrLabel
   DEFAULT ::Font TO Font()
   IF ::__ClsInst == NIL // Runtime
      RETURN ::Draw()
   ENDIF

   #ifndef VRDLL
      ::Font:Create()

      IF ::lUI
         WITH OBJECT ::EditCtrl := __VrLabel( IIF( ::Parent:ClsName == "PanelBox", ::Parent, ::Parent:EditCtrl ) )
            :Cargo   := Self
            :Caption := ::Text
            :Left    := ::Left
            :Top     := ::Top
            :Create()
         END
         ::Font:Set( ::EditCtrl )
         Super:Create()
         ::SetText( ::xText )
       ELSE
         Super:Create()
      ENDIF
   #endif
RETURN Self

METHOD Configure() CLASS VrLabel
   IF ::lUI
      WITH OBJECT ::EditCtrl
         :Text           := ::Text
         :ForeColor      := ::ForeColor     
         :BackColor      := ::BackColor     
         :Font:FaceName  := ::Font:FaceName 
         :Font:PointSize := ::Font:PointSize
         :Font:Italic    := ::Font:Italic   
         :Font:Underline := ::Font:Underline
         :Font:Weight    := ::Font:Weight   
      END
      ::SetText( ::xText )
   ENDIF
RETURN Self

METHOD SetText( cText ) CLASS VrLabel
   LOCAL aSize, aRect
   IF ::EditCtrl != NIL
      WITH OBJECT ::EditCtrl
         IF :hWnd != NIL 
            aRect := :GetRectangle()
            aRect := {aRect[1]-1, aRect[2]-1, aRect[3]+1, aRect[4]+1}
            :Parent:InvalidateRect( aRect, .F. )

            IF VALTYPE( cText ) == "C"
               SetWindowText( :hWnd, cText )
            ENDIF
            
            aSize  := :Drawing:GetTextExtentPoint32( cText )
            :xWidth  := ::Width //aSize[1]+4
            :xHeight := MAX( ::Height, aSize[2]+2 )
            :MoveWindow()

            aRect := :GetRectangle()
            aRect := {aRect[1]-1, aRect[2]-1, aRect[3]+1, aRect[4]+1}
            :Parent:InvalidateRect( aRect, .F. )
         ENDIF
      END
   ENDIF
RETURN Self

METHOD WriteProps( oXmlControl ) CLASS VrLabel
   LOCAL oXmlValue, oXmlFont
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Text", NIL, ::Text )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "TextAngle", NIL, xStr(::TextAngle) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Picture", NIL, ::Picture )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "ForeColor", NIL, XSTR( ::ForeColor ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "BackColor", NIL, XSTR( ::BackColor ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Left", NIL, XSTR( ::Left ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Top", NIL, XSTR( ::Top ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Width", NIL, XSTR( ::Width ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Height", NIL, XSTR( ::Height ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Alignment", NIL, XSTR( ::Alignment ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "AutoResize", NIL, IIF( ::AutoResize, "True", "False" ) )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "SingleLine", NIL, IIF( ::SingleLine, "True", "False" ) )
   oXmlControl:addBelow( oXmlValue )

   oXmlFont := TXmlNode():new( , "Font" )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "FaceName", NIL, XSTR( ::Font:FaceName ) )
      oXmlFont:addBelow( oXmlValue )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "PointSize", NIL, XSTR( ::Font:PointSize ) )
      oXmlFont:addBelow( oXmlValue )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Italic", NIL, IIF( ::Font:Italic, "True", "False" ) )
      oXmlFont:addBelow( oXmlValue )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Underline", NIL, IIF( ::Font:Underline, "True", "False" ) )
      oXmlFont:addBelow( oXmlValue )
      oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Weight", NIL, XSTR( ::Font:Weight ) )
      oXmlFont:addBelow( oXmlValue )
   oXmlControl:addBelow( oXmlFont )
RETURN Self

METHOD GetFormulas( cText ) CLASS VrLabel
   LOCAL i, n, cFormula, nFormula, cValue, nVal, nFilter
   WHILE ValType( cText ) == "C" .AND. ( n := AT( "@", cText ) ) > 0
      cFormula := ""
      FOR i := n+1 TO LEN( cText )
          IF i == LEN( cText )
             cFormula += cText[i]
          ENDIF
          IF ! ( UPPER(cText[i]) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_[]" ) .OR. i == LEN( cText )
             IF ( nFormula := ASCAN( ::Parent:aComponents, {|h| UPPER(h:Name) == UPPER(cFormula) } ) ) > 0
                IF "@"+cFormula IN ::Parent:aComponents[nFormula]:Value
                   cText := STRTRAN( cText, "@"+cFormula, "RECURSION DETECTED" )
                 ELSE
                   cText := STRTRAN( cText, "@"+cFormula, ::Parent:aComponents[nFormula]:Value,,, 1 )
                ENDIF
              ELSEIF UPPER( LEFT( cFormula, LEN(cFormula)-1 ) ) == "FILTER"
                IF ( nFilter := ASCAN( ::Parent:aComponents, {|h| UPPER(h:Name) == UPPER(::Parent:DataSource:xName) } ) ) > 0 .AND. HGetPos( ::Parent:aComponents[nFilter]:Filter, "Expressions" ) > 0
                   cValue := ::Parent:aComponents[nFilter]:Filter:Expressions[ VAL(cFormula[-1]) ]:Value
                   cText := STRTRAN( cText, "@"+cFormula, cValue )
                 ELSE
                   cText := STRTRAN( cText, "@"+cFormula, "Filter not found "+cFormula )
                ENDIF
              ELSEIF UPPER( LEFT( cFormula, LEN(cFormula)-4 ) ) == "FILTER"
                nVal := cFormula[-2]
                IF ( nFilter := ASCAN( ::Parent:aComponents, {|h| UPPER(h:Name) == UPPER(::Parent:DataSource:xName) } ) ) > 0 .AND. HGetPos( ::Parent:aComponents[nFilter]:Filter, "Expressions" ) > 0
                   cValue := ::Parent:aComponents[nFilter]:Filter:Expressions[ VAL(cFormula[-4]) ]:Exp&nVal
                   cText := STRTRAN( cText, "@"+cFormula, cValue )
                 ELSE
                   cText := STRTRAN( cText, "@"+cFormula, "Filter not found "+cFormula )
                ENDIF
              ELSE
                // we remove the pointer to @cFormula so it can stop processing
                cText := STRTRAN( cText, "@"+cFormula, "Formula not found "+cFormula )
             ENDIF
             cFormula := ""
             EXIT
          ENDIF
          cFormula += cText[i]
      NEXT
   ENDDO
RETURN cText

METHOD Draw( hDC, hTotal, hCtrl ) CLASS VrLabel
   LOCAL nX, nY, hFont, hPrevFont, nWidth, x, y, cUnderline, cText, cItalic, cName := "Text" + AllTrim( Str( ::Parent:nText++ ) )
   LOCAL xText, lAuto, lf := (struct LOGFONT), aTxSize, n

   lAuto := ::AutoResize

   IF ::Text != NIL
      nX := GetDeviceCaps( hDC, LOGPIXELSX )
      nY := GetDeviceCaps( hDC, LOGPIXELSY )

      x  := ( ::nPixPerInch / nX ) * ::Left
      y  := ::Parent:nRow + ( ( ::nPixPerInch / nY ) * ::Top )
      
      cItalic    := IIF( ::Font:Italic, "1", "0" )
      cUnderline := IIF( ::Font:Underline, "1", "0" )

      ::Parent:oPDF:CreateObject( acObjectTypeText, cName )
      ::PDFCtrl := ::Parent:oPDF:GetObjectByName( cName )
      WITH OBJECT ::PDFCtrl

         cText := ::GetFormulas( ::Text )

         IF ::ClsName == "VRTOTAL" .AND. !EMPTY(::Value)
            IF !EMPTY( ::Value )
               TRY
                  cText := &( ::GetFormulas( ::Value ) )
               CATCH
                  cText := ::GetFormulas( ::Value )
               END
            ENDIF
            IF VALTYPE( cText ) == "B"
               cText := EVAL( cText, ::Parent )
            ENDIF

            IF hTotal != NIL
               IF EMPTY( hTotal:Value )
                  hTotal:Value := 0
               ENDIF
               hTotal:Value += cText
            ENDIF
            cText := ALLTRIM( xStr( cText ) )
            hCtrl:Text := cText
          ELSE
            xText := cText
            TRY
               cText := &cText
            CATCH
            END
            TRY
               IF VALTYPE( cText ) == "B"
                  cText := EVAL( cText, ::Parent )
               ENDIF
            CATCH
               IF ValType(cText) != ValType(xText)
                  cText := xText
               ENDIF
            END

            IF hTotal != NIL
               IF EMPTY( hTotal:Value )
                  hTotal:Value := 0
               ENDIF
               hTotal:Value += cText
            ENDIF
         ENDIF
         IF !EMPTY( ::Picture )
            cText := TRANSFORM( cText, ::Picture )
         ENDIF
         cText := ALLTRIM( xStr( cText ) )
         IF ::Alignment > 1
            :Attribute( "HorzAlign", ::Alignment )
            lAuto := .F.
         ENDIF
         IF ! lAuto
            lf:lfFaceName:Buffer( Alltrim( ::Font:FaceName ) )
            lf:lfHeight         := -MulDiv( ::Font:PointSize, nY, 72 )
            lf:lfWeight         := IIF( ::Font:Bold, 700, 400 )
            lf:lfItalic         := IIF( ::Font:Italic, 1, 0 )
            lf:lfUnderline      := IIF( ::Font:Underline, 1, 0 )
            lf:lfStrikeOut      := IIF( ::Font:StrikeOut, 1, 0 )
            hFont     := CreateFontIndirect( lf )
            hPrevFont := SelectObject( hDC, hFont )
            
            aTxSize := _GetTextExtentPoint32( hDC, cText )
            DEFAULT aTxSize TO {0,0}
            IF ::SingleLine .AND. aTxSize[1] > ::Width
               WHILE aTxSize[1] > ::Width
                  cText := LEFT( cText, LEN(cText)-1 )
                  aTxSize := _GetTextExtentPoint32( hDC, cText + "..." )
               ENDDO
               cText += "..."
            ENDIF
            
            SelectObject( hDC, hPrevFont )
            DeleteObject( hFont )
            :Attribute( "Right",   x + ( (::nPixPerInch / nX) * ::Width ) )
            :Attribute( "Bottom",  y + ( (::nPixPerInch / nY) * IIF( ::SingleLine, (aTxSize[2]+2), ::Height ) ) )

          ELSE
            :Attribute( "AutoResize", 1 )
         ENDIF
         :Attribute( "Single Line", IIF( ::SingleLine, 1, 0 ) )
         :Attribute( "Left",   x )
         :Attribute( "Top",    y )
         :Attribute( "TextFont", Alltrim( ::Font:FaceName ) + "," +Alltrim( Str( ::Font:PointSize ) ) + "," + Alltrim( Str( ::Font:Weight ) ) +","+cItalic+","+cUnderline )
         

         :Attribute( "Text", cText )
         IF ::ForeColor != ::SysForeColor
            :Attribute( "TextColor", PADL( DecToHexa( ::ForeColor ), 6, "0" ) )
         ENDIF
         IF ::BackColor != ::SysBackColor
            :Attribute( "BackColor", PADL( DecToHexa( ::BackColor ), 6, "0" ) )
         ENDIF
         
         IF ::TextAngle <> 0
            :Attribute( "TextAngle", ::TextAngle*10 )
         ENDIF
      END
   ENDIF
RETURN Self

//-----------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------------

#ifndef VRDLL
   CLASS __VrLabel INHERIT Label
      DATA aSize EXPORTED INIT {.F.,.T.,.F.,.F.,.F.,.T.,.F.,.F.}
      METHOD OnLButtonDown()
      METHOD OnMouseMove(n,x,y) INLINE MouseMove( Self, n, x, y )
      METHOD OnMouseLeave()     INLINE ::Parent:Cursor := NIL, NIL
      METHOD OnKeyDown(n)       INLINE KeyDown( Self, n )
      METHOD OnGetDlgCode()     INLINE DLGC_WANTMESSAGE + DLGC_WANTCHARS + DLGC_WANTARROWS + DLGC_HASSETSEL
   ENDCLASS

   //-----------------------------------------------------------------------------------------------------------------------------------
   METHOD OnLButtonDown(n,x,y) CLASS __VrLabel 
      LOCAL aRect, oCtrl
      ::Parent:SetCapture()
      IF ::Application:Props:PropEditor:ActiveObject != NIL
         oCtrl := ::Application:Props:PropEditor:ActiveObject:EditCtrl
         TRY
            IF oCtrl != NIL
               aRect := oCtrl:GetRectangle()
               aRect := {aRect[1]-1, aRect[2]-1, aRect[3]+1, aRect[4]+1}
               oCtrl:Parent:InvalidateRect( aRect, .F. )
               aRect := ::GetRectangle()
               aRect := {aRect[1]-1, aRect[2]-1, aRect[3]+1, aRect[4]+1}
               ::Parent:InvalidateRect( aRect, .F. )
               ::Parent:nDownPos := {x,y}

               AINS( ::Application:Report:aUndo, 1, { { oCtrl:Left, oCtrl:Top, oCtrl:Width, oCtrl:Height }, "__MOVESIZE", oCtrl }, .T. )
               ::Application:Props:EditUndoBttn:Enabled := .T.

            ENDIF
         CATCH
         END
         ::SetFocus()
      ENDIF
      Super:OnLButtonDown()
   RETURN NIL
#endif
//-----------------------------------------------------------------------------------------------------------------------------------
FUNCTION GetPoints( oCtrl )
   LOCAL aRect, aPoints, n := 6
   aRect := _GetClientRect( oCtrl:hWnd )
   aPoints := { { 0, 0,          n, n },; // left top
                { 0, (aRect[4]-n)/2, n, (aRect[4]+n)/2 },; // left
                { 0, aRect[4]-n, n, aRect[4] },; // left bottom
                { (aRect[3]-n)/2, aRect[4]-n, (aRect[3]+n)/2, aRect[4] },; // bottom
                { aRect[3]-n, aRect[4]-n, aRect[3], aRect[4] },; // right bottom
                { aRect[3]-n, (aRect[4]-n)/2, aRect[3], (aRect[4]+n)/2 },; // right
                { aRect[3]-n, 0, aRect[3], n },; // right top
                { (aRect[3]-n)/2, 0, (aRect[3]+n)/2, n } } // top
RETURN aPoints

FUNCTION MouseMove( oCtrl, n, x, y )
   LOCAL i, aPoint, aPoints, nCursor := 0
   IF n != MK_LBUTTON 
      oCtrl:Parent:nMove := 0
      aPoints := GetPoints( oCtrl )
      FOR i := 1 TO LEN( aPoints )
          IF oCtrl:aSize[i] .AND. _PtInRect( aPoints[i], {x,y} )
             oCtrl:Parent:nMove := i
             nCursor := i - IIF( i > 4, 4, 0 )
             EXIT
          ENDIF
      NEXT
      oCtrl:Parent:Cursor := IIF( nCursor > 0, oCtrl:Parent:aCursor[ nCursor ], NIL )
   ENDIF
RETURN NIL

FUNCTION PaintMarkers( hDC, oCtrl )
   LOCAL nColor, i, aPt, hBrush, aPts := GetPoints( oCtrl )
   local r,g,b, hOld, lDC := hDC != NIL
   
   IF !lDC
      hDC := GetDCEx( oCtrl:Parent:hWnd )
   ENDIF
   r = 255-GetRValue( oCtrl:BackColor )
   g = 255-GetGValue( oCtrl:BackColor )
   b = 255-GetBValue( oCtrl:BackColor )
            
   hBrush := CreateSolidBrush( RGB(r,g,b) )
   hOld := SelectObject( hDC, hBrush )
   FOR i := 1 TO LEN( aPts )
       IF oCtrl:aSize[i]
          aPt := {aPts[i][1], aPts[i][2]}
          _ClientToScreen( oCtrl:hWnd, @aPt )
          _ScreenToClient( oCtrl:Parent:hWnd, @aPt )
          aPts[i][1] := aPt[1]
          aPts[i][2] := aPt[2]
          aPt := {aPts[i][3], aPts[i][4]}
          _ClientToScreen( oCtrl:hWnd, @aPt )
          _ScreenToClient( oCtrl:Parent:hWnd, @aPt )
          aPts[i][3] := aPt[1]
          aPts[i][4] := aPt[2]
          Rectangle( hDC, aPts[i][1], aPts[i][2], aPts[i][3], aPts[i][4] )
       ENDIF
   NEXT
   SelectObject( hDC, hOld )
   DeleteObject( hBrush )
   IF !lDC
      ReleaseDC( oCtrl:Parent:hWnd, hDC )
   ENDIF
RETURN NIL

FUNCTION DecToHexa(nNumber)
   local cNewString := ""
   local nTemp := 0
   WHILE nNumber > 0
      nTemp      := nNumber % 16
      cNewString := SubStr( "0123456789ABCDEF", (nTemp+1), 1 ) + cNewString
      nNumber    := Int( (nNumber-nTemp)/16 )
   ENDDO
RETURN cNewString

//-----------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------------------

CLASS VrTotal INHERIT VrLabel
   DATA ClsName EXPORTED INIT "Total"
   DATA Column  EXPORTED INIT ""
   DATA Value   EXPORTED INIT ""
   METHOD Init() CONSTRUCTOR
   METHOD WriteProps()
ENDCLASS

//-----------------------------------------------------------------------------------------------------------------------------------
METHOD Init( oParent ) CLASS VrTotal
   Super:Init( oParent )
   AADD( ::aProperties, { "Column",      "Data"  } )
RETURN Self

METHOD WriteProps( oXmlControl ) CLASS VrTotal
   LOCAL oXmlValue, oXmlFont
   Super:WriteProps( oXmlControl )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Column", NIL, ::Column )
   oXmlControl:addBelow( oXmlValue )
   oXmlValue := TXmlNode():new( HBXML_TYPE_TAG, "Value", NIL, ::Value )
   oXmlControl:addBelow( oXmlValue )
RETURN Self
