#ifndef __DLL_CH
   #define __DLL_CH

   #define DC_MICROSOFT           0x0000      // Default
   #define DC_BORLAND             0x0001      // Borland compat
   #define DC_CALL_CDECL          0x0010      // __cdecl
   #define DC_CALL_STD            0x0020      // __stdcall
   #define DC_RETVAL_MATH4        0x0100      // Return value in ST
   #define DC_RETVAL_MATH8        0x0200      // Return value in ST

   // Avoid xHarbour code when included by dllcall.c
   #ifdef __PLATFORM__Windows

      // FoxPro Syntax
      #xcommand DECLARE <!Type!> <!FuncName!> IN <(DllName)> [AS <(DllFuncName)>] [<ArgType> [@] [<ArgName>] [, <ArgTypeN> [@] [<ArgNameN>]]] => ;
          FUNCTION <FuncName>( ... );;
             STATIC cTemplate;;
             ;;
             IF cTemplate == NIL;;
                cTemplate := DllPrepareCall( <(DllName)>, DC_CALL_STD, IIF( <.DllFuncName.>, <(DllFuncName)>, #<FuncName> ) );;
                TraceLog( cTemplate );;
             ENDIF;;
             ;;
             SWITCH PCount();;
                CASE 0;;
                   RETURN DllExecuteCall( cTemplate );;
                CASE 1;;
                   RETURN DllExecuteCall( cTemplate, PValue(1) );;
                CASE 2;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2) );;
                CASE 3;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3) );;
                CASE 4;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3), PValue(4) );;
                CASE 5;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3), PValue(4), PValue(5) );;
                CASE 6;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3), PValue(4), PValue(5), PValue(6) );;
                CASE 7;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3), PValue(4), PValue(5), PValue(6), PValue(7) );;
                CASE 8;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3), PValue(4), PValue(5), PValue(6), PValue(7), PValue(8) );;
                CASE 9;;
                   RETURN DllExecuteCall( cTemplate, PValue(1), PValue(2), PValue(3), PValue(4), PValue(5), PValue(6), PValue(7), PValue(8), PValue(9) );;
             END;;
             ;;
          RETURN NIL

      // FWH
      #xcommand DLL [<Qualifier: STATIC>] FUNCTION <FuncName>( [ <ArgName> AS <ArgType> ] [, <ArgNameN> AS <ArgTypeN> ] ) AS <Type> [<pascal: PASCAL>] [ FROM <DllFuncName> ] LIB <(DllName)> => ;
          [<Qualifier>] FUNCTION <FuncName>( [<ArgName>] [, <ArgNameN>] );;
             STATIC cTemplate;;
             ;;
             IF cTemplate == NIL;;
                cTemplate := DllPrepareCall( <(DllName)>, IIF( <.pascal.>, DC_CALL_STD, DC_CALL_CDECL ), IIF( <.DllFuncName.>, <(DllFuncName)>, #<FuncName> ) );;
                TraceLog( cTemplate );;
             ENDIF;;
             ;;
          RETURN DllExecuteCall( cTemplate [, <ArgName>] [, <ArgNameN>] )

      #xcommand DLL32 [<Qualifier: STATIC>] FUNCTION <FuncName>( [ <ArgName> AS <ArgType> ] [, <ArgNameN> AS <ArgTypeN> ] ) AS <Type> [<pascal: PASCAL>] [ FROM <DllFuncName> ] LIB <(DllName)> => ;
          [<Qualifier>] FUNCTION <FuncName>( [<ArgName>] [, <ArgNameN>] );;
             STATIC cTemplate;;
             ;;
             IF cTemplate == NIL;;
                cTemplate := DllPrepareCall( <(DllName)>, IIF( <.pascal.>, DC_CALL_STD, DC_CALL_CDECL ), IIF( <.DllFuncName.>, <(DllFuncName)>, #<FuncName> ) );;
                TraceLog( cTemplate );;
             ENDIF;;
             ;;
          RETURN DllExecuteCall( cTemplate [, <ArgName>] [, <ArgNameN>] )

   #endif
#endif