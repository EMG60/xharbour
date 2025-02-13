#ifndef _SQLUCODE_H
#define _SQLUCODE_H

/* ODBC Core functions Unicode definitions */

#ifdef __cplusplus
extern "C" {
#endif

#include <sqlext.h>

#define SQL_WCHAR  (-8)
#define SQL_WVARCHAR  (-9)
#define SQL_WLONGVARCHAR  (-10)
#define SQL_C_WCHAR  SQL_WCHAR

#ifdef UNICODE
#define SQL_C_TCHAR SQL_C_WCHAR
#else
#define SQL_C_TCHAR SQL_C_CHAR
#endif

#define SQL_SQLSTATE_SIZEW  10

/* Unicode */
SQLRETURN SQL_API SQLColAttributeW(SQLHSTMT,SQLUSMALLINT,SQLUSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*,SQLPOINTER);
SQLRETURN SQL_API SQLColAttributesW(SQLHSTMT,SQLUSMALLINT,SQLUSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*,SQLLEN*);
SQLRETURN SQL_API SQLConnectW(SQLHDBC,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDescribeColW(SQLHSTMT,SQLUSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLSMALLINT*,SQLULEN*,SQLSMALLINT*,SQLSMALLINT*);
SQLRETURN SQL_API SQLErrorW(SQLHENV,SQLHDBC,SQLHSTMT,SQLWCHAR*,SQLINTEGER*,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLExecDirectW(SQLHSTMT,SQLWCHAR*,SQLINTEGER);
SQLRETURN SQL_API SQLGetConnectAttrW(SQLHDBC,SQLINTEGER,SQLPOINTER,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLGetCursorNameW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*);
#if (ODBCVER >= 0x0300)
SQLRETURN SQL_API SQLSetDescFieldW(SQLHDESC,SQLSMALLINT,SQLSMALLINT,SQLPOINTER,SQLINTEGER);
SQLRETURN SQL_API SQLGetDescFieldW(SQLHDESC,SQLSMALLINT,SQLSMALLINT,SQLPOINTER,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLGetDescRecW(SQLHDESC,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLSMALLINT*,SQLSMALLINT*,SQLLEN*,SQLSMALLINT*,SQLSMALLINT*,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetDiagFieldW(SQLSMALLINT,SQLHANDLE,SQLSMALLINT,SQLSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetDiagRecW(SQLSMALLINT,SQLHANDLE,SQLSMALLINT,SQLWCHAR*,SQLINTEGER*,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*);
#endif /* ODBCVER >= 0x0300 */
SQLRETURN SQL_API SQLPrepareW(SQLHSTMT,SQLWCHAR*,SQLINTEGER);
SQLRETURN SQL_API SQLSetConnectAttrW(SQLHDBC,SQLINTEGER,SQLPOINTER,SQLINTEGER);
SQLRETURN SQL_API SQLSetCursorNameW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLColumnsW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLGetConnectOptionW(SQLHDBC,SQLUSMALLINT,SQLPOINTER);
SQLRETURN SQL_API SQLGetInfoW(SQLHDBC,SQLUSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetTypeInfoW(SQLHSTMT,SQLSMALLINT);
SQLRETURN SQL_API SQLSetConnectOptionW(SQLHDBC,SQLUSMALLINT,SQLULEN);
SQLRETURN SQL_API SQLSpecialColumnsW(SQLHSTMT,SQLUSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLUSMALLINT,SQLUSMALLINT);
SQLRETURN SQL_API SQLStatisticsW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLUSMALLINT,SQLUSMALLINT);
SQLRETURN SQL_API SQLTablesW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDataSourcesW(SQLHENV,SQLUSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLDriverConnectW(SQLHDBC,SQLHWND,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLUSMALLINT);
SQLRETURN SQL_API SQLBrowseConnectW(SQLHDBC,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLColumnPrivilegesW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLGetStmtAttrW(SQLHSTMT,SQLINTEGER,SQLPOINTER,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLSetStmtAttrW(SQLHSTMT,SQLINTEGER,SQLPOINTER,SQLINTEGER);
SQLRETURN SQL_API SQLForeignKeysW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLNativeSqlW(SQLHDBC,SQLWCHAR*,SQLINTEGER,SQLWCHAR*,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLPrimaryKeysW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLProcedureColumnsW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLProceduresW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLTablePrivilegesW(SQLHSTMT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLWCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDriversW(SQLHENV,SQLUSMALLINT,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLWCHAR*,SQLSMALLINT,SQLSMALLINT*);
/* ANSI */
SQLRETURN SQL_API SQLColAttributeA(SQLHSTMT,SQLSMALLINT,SQLSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*,SQLPOINTER);
SQLRETURN SQL_API SQLColAttributesA(SQLHSTMT,SQLUSMALLINT,SQLUSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*,SQLINTEGER*);
SQLRETURN SQL_API SQLConnectA(SQLHDBC,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDescribeColA(SQLHSTMT,SQLUSMALLINT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLSMALLINT*,SQLUINTEGER*,SQLSMALLINT*,SQLSMALLINT*);
SQLRETURN SQL_API SQLErrorA(SQLHENV,SQLHDBC,SQLHSTMT,SQLCHAR*,SQLINTEGER*,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLExecDirectA(SQLHSTMT,SQLCHAR*,SQLINTEGER);
SQLRETURN SQL_API SQLGetConnectAttrA(SQLHDBC,SQLINTEGER,SQLPOINTER,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLGetCursorNameA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*);
#if (ODBCVER >= 0x0300)
SQLRETURN SQL_API SQLGetDescFieldA(SQLHDESC,SQLSMALLINT,SQLSMALLINT,SQLPOINTER,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLGetDescRecA(SQLHDESC,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLSMALLINT*,SQLSMALLINT*,SQLINTEGER*,SQLSMALLINT*,SQLSMALLINT*,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetDiagFieldA(SQLSMALLINT,SQLHANDLE,SQLSMALLINT,SQLSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetDiagRecA(SQLSMALLINT,SQLHANDLE,SQLSMALLINT,SQLCHAR*,SQLINTEGER*,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetStmtAttrA(SQLHSTMT,SQLINTEGER,SQLPOINTER,SQLINTEGER,SQLINTEGER*);
#endif /* ODBCVER >= 0x0300 */
SQLRETURN SQL_API SQLGetTypeInfoA(SQLHSTMT,SQLSMALLINT);
SQLRETURN SQL_API SQLPrepareA(SQLHSTMT,SQLCHAR*,SQLINTEGER);
SQLRETURN SQL_API SQLSetConnectAttrA(SQLHDBC,SQLINTEGER,SQLPOINTER,SQLINTEGER);
SQLRETURN SQL_API SQLSetCursorNameA(SQLHSTMT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLColumnsA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLGetConnectOptionA(SQLHDBC,SQLUSMALLINT,SQLPOINTER);
SQLRETURN SQL_API SQLGetInfoA(SQLHDBC,SQLUSMALLINT,SQLPOINTER,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLGetStmtOptionA(SQLHSTMT,SQLUSMALLINT,SQLPOINTER);
SQLRETURN SQL_API SQLSetConnectOptionA(SQLHDBC,SQLUSMALLINT,SQLULEN);
SQLRETURN SQL_API SQLSetStmtOptionA(SQLHSTMT,SQLUSMALLINT,SQLULEN);
SQLRETURN SQL_API SQLSpecialColumnsA(SQLHSTMT,SQLUSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLUSMALLINT,SQLUSMALLINT);
SQLRETURN SQL_API SQLStatisticsA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLUSMALLINT,SQLUSMALLINT);
SQLRETURN SQL_API SQLTablesA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDataSourcesA(SQLHENV,SQLUSMALLINT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLDriverConnectA(SQLHDBC,SQLHWND,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLUSMALLINT);
SQLRETURN SQL_API SQLBrowseConnectA(SQLHDBC,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*);
SQLRETURN SQL_API SQLColumnPrivilegesA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDescribeParamA(SQLHSTMT,SQLUSMALLINT,SQLSMALLINT*,SQLUINTEGER*,SQLSMALLINT*,SQLSMALLINT*);
SQLRETURN SQL_API SQLForeignKeysA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLNativeSqlA(SQLHDBC,SQLCHAR*,SQLINTEGER,SQLCHAR*,SQLINTEGER,SQLINTEGER*);
SQLRETURN SQL_API SQLPrimaryKeysA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLProcedureColumnsA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLProceduresA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLTablePrivilegesA(SQLHSTMT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT,SQLCHAR*,SQLSMALLINT);
SQLRETURN SQL_API SQLDriversA(SQLHENV,SQLUSMALLINT,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*,SQLCHAR*,SQLSMALLINT,SQLSMALLINT*);

#ifndef SQL_NOUNICODEMAP
#ifdef UNICODE
#define SQLColAttribute  SQLColAttributeW
#define SQLColAttributes  SQLColAttributesW
#define SQLConnect  SQLConnectW
#define SQLDescribeCol  SQLDescribeColW
#define SQLError  SQLErrorW
#define SQLExecDirect  SQLExecDirectW
#define SQLGetConnectAttr  SQLGetConnectAttrW
#define SQLGetCursorName  SQLGetCursorNameW
#define SQLGetDescField  SQLGetDescFieldW
#define SQLGetDescRec  SQLGetDescRecW
#define SQLGetDiagField  SQLGetDiagFieldW
#define SQLGetDiagRec  SQLGetDiagRecW
#define SQLPrepare  SQLPrepareW
#define SQLSetConnectAttr  SQLSetConnectAttrW
#define SQLSetCursorName  SQLSetCursorNameW
#define SQLSetDescField  SQLSetDescFieldW
#define SQLSetStmtAttr  SQLSetStmtAttrW
#define SQLGetStmtAttr  SQLGetStmtAttrW
#define SQLColumns  SQLColumnsW
#define SQLGetConnectOption SQLGetConnectOptionW
#define SQLGetInfo  SQLGetInfoW
#define SQLGetTypeInfo  SQLGetTypeInfoW
#define SQLSetConnectOption SQLSetConnectOptionW
#define SQLSpecialColumns  SQLSpecialColumnsW
#define SQLStatistics  SQLStatisticsW
#define SQLTables  SQLTablesW
#define SQLDataSources  SQLDataSourcesW
#define SQLDriverConnect  SQLDriverConnectW
#define SQLBrowseConnect  SQLBrowseConnectW
#define SQLColumnPrivileges SQLColumnPrivilegesW
#define SQLForeignKeys  SQLForeignKeysW
#define SQLNativeSql  SQLNativeSqlW
#define SQLPrimaryKeys  SQLPrimaryKeysW
#define SQLProcedureColumns SQLProcedureColumnsW
#define SQLProcedures  SQLProceduresW
#define SQLTablePrivileges  SQLTablePrivilegesW
#define SQLDrivers  SQLDriversW
#endif /* UNICODE */
#endif /* SQL_NOUNICODEMAP */

#ifdef __cplusplus
}
#endif

#endif /* _SQLUCODE_H */
