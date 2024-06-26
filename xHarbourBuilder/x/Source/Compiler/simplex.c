/*
 * $Id$
 */

/*
 * Copyright 2000 Ron Pinkas <ron@profit-master.com>
 * www - http://www.Profit-Master.com
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#ifndef BOOL
   #define BOOL int
   #define TRUE 1
   #define FALSE 0
#endif

/* NOT overidable (yet). */
#define MAX_MATCH 4

#ifndef TOKEN_SIZE
   #define TOKEN_SIZE 64
#endif

/* Language Definitions Readability. */
#define SELF_CONTAINED_WORDS_ARE static LEX_WORD aSelfs[] =
#define LANGUAGE_KEY_WORDS_ARE static LEX_WORD aKeys[] =
#define LANGUAGE_WORDS_ARE static LEX_WORD aWords[] =
#define LANGUAGE_RULES_ARE static int aiRules[][ MAX_MATCH + 2 ] =
#define ACCEPT_TOKEN_AND_DROP_DELIMITER_IF_ONE_OF_THESE(x) static char *szOmmit = x
#define ACCEPT_TOKEN_AND_RETURN_DELIMITERS static LEX_DELIMITER aDelimiters[] =
#define DELIMITER_BELONGS_TO_TOKEN_IF_ONE_OF_THESE(x) static char *szAppend = x
#define START_NEW_LINE_IF_ONE_OF_THESE(x) static char *szNewLine = x
#define IF_SEQUENCE_IS(a, b, c, d) {a, b, c, d
#define REDUCE_TO(x, y) ,x, y }
#define PASS_THROUGH() ,0, 0 }
#define LEX_DELIMITER(x) {x
#define LEX_WORD(x) {x
#define AS_TOKEN(x) ,x }

/* Streams ("Pairs"). */
#define DEFINE_STREAM_AS_ONE_OF_THESE LEX_PAIR aPairs[] =
#define START_WITH(x) { x,
#define END_WITH(x) x,
#define STOP_IF_ONE_OF_THESE(x) x,
#define TEST_LEFT(x) x,
#define AS_PAIR_TOKEN(x) x }
#define STREAM_EXCEPTION( sPair, chrPair) \
        if( chrPair ) \
        { \
           printf(  "Exception: %c for stream at: \"%s\"\n", chrPair, sPair ); \
        } \
        else \
        { \
           printf(  "Exception: <EOF> for stream at: \"%s\"\n", chrPair, sPair ); \
        } \

/* Pairs. */
#ifndef STREAM_ALLOC_SIZE
   #define STREAM_ALLOC_SIZE 2048
#endif
#ifndef MAX_STREAM_STARTER
   #define MAX_STREAM_STARTER 2
#endif
#ifndef MAX_STREAM_TERMINATOR
   #define MAX_STREAM_TERMINATOR 2
#endif
#ifndef MAX_STREAM_EXCLUSIONS
   #define MAX_STREAM_EXCLUSIONS 2
#endif

#ifndef YY_BUF_SIZE
   #define YY_BUF_SIZE 16384
#endif

static char sToken[TOKEN_SIZE];
static char szLexBuffer[ YY_BUF_SIZE ];

static char * sPair = NULL;
static char * sStart, * sTerm;
static char * sExclude;

static BOOL bTestLeft;
static BOOL bIgnoreWords = FALSE;

static int iPairToken = 0;
static int iPairAllocated = 0;

/* Self Contained Words. */
static char sSelf[ TOKEN_SIZE ];

typedef struct _LEX_DELIMITER
{
   char  cDelimiter;
   int   iToken;
} LEX_DELIMITER;                    /* support structure for KEYS and WORDS. */

typedef struct _LEX_WORD
{
   char  sWord[ TOKEN_SIZE ];
   int   iToken;
} LEX_WORD;                    /* support structure for KEYS and WORDS. */

typedef struct _LEX_PAIR
{
   char  sStart[MAX_STREAM_STARTER];
   char  sTerm[MAX_STREAM_TERMINATOR];
   char  sExclude[MAX_STREAM_EXCLUSIONS];
   BOOL  bTestLeft;
   int   iToken;
} LEX_PAIR;                    /* support structure for Streams (Pairs). */

#ifdef __cplusplus
   typedef struct yy_buffer_state *YY_BUFFER_STATE;
#endif

static unsigned int iLen = 0;
static char chr, cPrev = 0;
static unsigned int iLastToken = 0;
static char *s_szBuffer;
static unsigned int iSize = 0;

/* Look ahead Tokens. */
static int  iHold = 0;
static int  aiHold[4];

/* Pre-Checked Tokens. */
static int  iReturn = 0;
static int  aiReturn[4];

/* Rules matching. */
static unsigned int iRule, iMatched = 0;

static int  iRet;

/* Length of last [sequence of] acOmmit, acNewLine, 1 for acOmmit, or len of sSelf. */
static unsigned int iLastLen;

/* NewLine Support. */
static BOOL bNewLine = TRUE, bStart = TRUE;

/* Lex emulation */
char * yytext = (char *) sToken;
int yyleng;

#define RESET_LEX() { iLen = 0; iHold = 0; iReturn = 0; bNewLine = TRUE; bIgnoreWords = FALSE; iPairToken = 0; iLastToken = 0; }

/* Above are NOT overidable !!! Need to precede the Language Definitions. */

/* --------------------------------------------------------------------------------- */

/* Overidables. */
#define LEX_CUSTOM_ACTION -65
#define DONT_REDUCE 1024
#define MAX_RULES   1024

#define YY_INPUT( a, b, c )

/* Optional User Macros. */
#define LEX_USER_SETUP()
#define INIT_ACTION()
#define INTERCEPT_ACTION(x)
#define CUSTOM_ACTION(x)
#define NEW_LINE_ACTION()
#define ELEMENT_TOKEN(x,y) -1
#define DEBUG_INFO(x)
#define LEX_CASE(x)
#define STREAM_OPEN(x)
#define STREAM_APPEND(x) sPair[ iPairLen++ ] = x

#ifndef USING_CARGO
   #define USING_CARGO 0
   #define CARGO
   #define DEF_CARGO
#endif

void SimpLex_CheckWords( DEF_CARGO );

#include SLX_RULES

/* Declarations. */

FILE *yyin;      /* currently yacc parsed file */

extern void yyerror( char * ); /* parsing error management function */

#ifdef __cplusplus
   extern "C" int yywrap( void );
#else
   extern int yywrap( void );     /* manages the EOF of current processed file */
#endif

/* ---------------------------------------------------------------------------------------------- */

#define LEX_RULE_SIZE      ( sizeof( (int) iRet ) * ( MAX_MATCH + 2 ) )
#define LEX_WORD_SIZE      ( sizeof( LEX_WORD ) )
#define LEX_PAIR_SIZE      ( sizeof( LEX_PAIR ) )
#define LEX_DELIMITER_SIZE ( sizeof( LEX_DELIMITER ) )

/* Using statics when we could use locals to eliminate Allocations and Deallocations each time yylex is called and returns. */

/* yylex */
static char * tmpPtr;
static BOOL bTmp, bRecursive = FALSE;

#ifdef USE_KEYWORDS
   static unsigned int iKeys  = (int) ( sizeof( aKeys   ) / LEX_WORD_SIZE );
#endif

static unsigned int iWords      = (int) ( sizeof( aWords      ) / LEX_WORD_SIZE      );
static unsigned int iSelfs      = (int) ( sizeof( aSelfs      ) / LEX_WORD_SIZE      );
static unsigned int iPairs      = (int) ( sizeof( aPairs      ) / LEX_PAIR_SIZE      );
static unsigned int iDelimiters = (int) ( sizeof( aDelimiters ) / LEX_DELIMITER_SIZE );
static unsigned int iRules      = (int) ( sizeof( aiRules     ) / LEX_RULE_SIZE      );

typedef struct _TREE_NODE
{
   int iMin;
   int iMax;
} TREE_NODE;                    /* support structure for Streams (Pairs). */

/* Indexing System. */
static TREE_NODE aPairNodes[256], aSelfNodes[256], aKeyNodes[256], aWordNodes[256], aRuleNodes[MAX_RULES];
static char acOmmit[256], acNewLine[256];
static int acReturn[256];

#if USING_CARGO
   static int Reduce( int iToken, DEF_CARGO );
#else
   static int Reduce( int iToken );
#endif
int SimpLex_GetNextToken( DEF_CARGO );
int SimpLex_CheckToken( DEF_CARGO );

/* Indexing System. */
static void GenTrees( void );
static int rulecmp( const void * pLeft, const void * pRight );

/* --------------------------------------------------------------------------------- */

/* MACROS. */

/* Readability Macros. */
#define LEX_RULE_SIZE ( sizeof( (int) iRet ) * ( MAX_MATCH + 2 ) )
#define LEX_WORD_SIZE ( sizeof( LEX_WORD ) )
#define LEX_PAIR_SIZE ( sizeof( LEX_PAIR ) )
#define IF_TOKEN_READY()  if( iReturn )
#define IF_TOKEN_ON_HOLD()  if( iHold )

#if USING_CARGO
   #define FORCE_REDUCE() Reduce( 0, CARGO )
#else
   #define FORCE_REDUCE() Reduce( 0 )
#endif

#define HOLD_TOKEN(x) PUSH_TOKEN(x)

#define IF_BEGIN_PAIR(chr) \
         if( aPairNodes[(int)chr].iMin == -1 ) \
         { \
            bTmp = FALSE; \
         } \
         else \
         { \
            register unsigned int i = aPairNodes[(int)chr].iMin, iMax = aPairNodes[(int)chr].iMax + 1, iStartLen = 0; \
            register unsigned char chrStart = 0; \
            unsigned int iLastPair = 0, iLastLen = 0; \
            \
            DEBUG_INFO( printf( "Checking %i Streams for %c At: >%s<\n", iPairs, chr, szBuffer - 1 ) ); \
            \
            while( i < iMax ) \
            { \
               iStartLen = 1; \
               \
               chrStart = LEX_CASE( *szBuffer ); \
               \
               while( aPairs[i].sStart[iStartLen] ) \
               { \
                  if( chrStart != aPairs[i].sStart[iStartLen] ) \
                  { \
                     break; \
                  } \
                  \
                  iStartLen++; \
                  \
                  chrStart = LEX_CASE( *( szBuffer + iStartLen - 1 ) ); \
               } \
               \
               /* Match */ \
               if( aPairs[i].sStart[iStartLen] == '\0' ) \
               { \
                  if( iStartLen > iLastLen ) \
                  { \
                     iLastPair = i + 1; \
                     iLastLen  = iStartLen; \
                  } \
               } \
               i++; \
            } \
            \
            bTmp = FALSE; \
            \
            if( iLastPair ) \
            { \
               iLastPair--; \
               STREAM_OPEN( aPairs[iLastPair].sStart )\
               { \
                  bTmp = TRUE; \
                  \
                  /* Last charcter read. */\
                  if( iStartLen > 1 ) chr = chrStart; \
                  \
                  /* Moving to next postion after the Stream Start position. */ \
                  szBuffer += ( iLastLen - 1 ); \
                  \
                  sStart     = (char *) aPairs[iLastPair].sStart; \
                  sTerm      = (char *) aPairs[iLastPair].sTerm; \
                  sExclude   = (char *) aPairs[iLastPair].sExclude; \
                  bTestLeft  =          aPairs[iLastPair].bTestLeft; \
                  iPairToken =          aPairs[iLastPair].iToken; \
                  \
                  DEBUG_INFO( printf( "Looking for Stream Terminator: >%s< Exclusions >%s<\n", sTerm, sExclude ) ); \
               } \
            } \
         } \
         /* Begin New Pair. */ \
         if( bTmp )

#define CHECK_SELF_CONTAINED(chr) \
         if( aSelfNodes[(int)chr].iMin != -1 ) \
         { \
            register unsigned int i = aSelfNodes[(int)chr].iMin, iMax = aSelfNodes[(int)chr].iMax + 1, iSelfLen; \
            register unsigned char chrSelf; \
            \
            DEBUG_INFO( printf( "Checking %i Selfs for %c At: >%s<\n", iSelfs, chr, szBuffer - 1 ) ); \
            \
            while( i < iMax ) \
            { \
               sSelf[0] = chr; \
               iSelfLen = 1; \
               chrSelf = LEX_CASE( *szBuffer ); \
               \
               while( aSelfs[i].sWord[iSelfLen] ) \
               { \
                  if( aSelfs[i].sWord[iSelfLen] == chrSelf ) \
                  { \
                     sSelf[ iSelfLen ] = chrSelf; \
                  } \
                  else \
                  { \
                     break; \
                  } \
                  \
                  iSelfLen++; \
                  \
                  chrSelf = LEX_CASE( *( szBuffer + iSelfLen - 1 ) ); \
               } \
               \
               /* Match */ \
               if( aSelfs[i].sWord[iSelfLen] == '\0' ) \
               { \
                  /* Moving to next postion after the Self Contained Word. */ \
                  szBuffer += ( iSelfLen - 1 ); \
                  s_szBuffer = szBuffer; \
                  \
                  sSelf[ iSelfLen ] = '\0'; \
                  iRet = aSelfs[i].iToken; \
                  \
                  iLastLen = iSelfLen; \
                  \
                  if( iLen ) \
                  { \
                     DEBUG_INFO( printf( "Holding Self >%s<\n", sSelf ) ); \
                     \
                     HOLD_TOKEN( iRet ); \
                     \
                     /* Terminate current token and check it. */ \
                     sToken[ iLen ] = '\0'; \
                     \
                     /* Last charcter read. */\
                     chr = chrSelf;\
                     \
                     return SimpLex_CheckToken( CARGO ); \
                  } \
                  else \
                  { \
                     DEBUG_INFO( printf( "Reducing Self >%s<\n", sSelf ) ); \
                     bIgnoreWords = FALSE;\
                     \
                     if( bNewLine )\
                     {\
                        bNewLine = FALSE;\
                        NEW_LINE_ACTION();\
                     }\
                     \
                     /* Last charcter read. */\
                     if( iSelfLen > 1 ) chr = chrSelf;\
                     \
                     return iRet; \
                  } \
               } \
               \
               i++; \
            } \
         }

#define IF_ABORT_PAIR(chrPair) \
                        tmpPtr = sExclude; \
                        while ( *tmpPtr && chrPair != *tmpPtr ) \
                        { \
                            tmpPtr++; \
                        } \
                        \
                        /* Exception. */ \
                        if( *tmpPtr )

#define IF_APPEND_DELIMITER(chr) \
            /* Delimiter to Append? */ \
            tmpPtr = (char*) szAppend; \
            while ( *tmpPtr && chr != *tmpPtr ) tmpPtr++; \
            \
            /* Delimiter to Append found. */ \
            if( *tmpPtr )

#ifndef IF_BELONG_LEFT
   #define IF_BELONG_LEFT(chr) \
            /* Give precedence to associate rules */ \
            DEBUG_INFO( printf(  "Checking Left for: '%c' cPrev: '%c'\n", chr, cPrev ) ); \
            \
            if( 0 )
#endif

#define RETURN_READY_TOKEN() \
            \
            iReturn--; \
            iRet = aiReturn[iReturn]; \
            \
            DEBUG_INFO( printf(  "Returning Ready: %i\n", iRet ) ); \
            \
            INTERCEPT_ACTION(iRet); \
            return iRet; \

#define RELEASE_TOKEN() \
            \
            /* Last in First Out. */ \
            iHold--; \
            iRet = aiHold[iHold]; \
            \
            DEBUG_INFO( printf(  "Released %i Now Holding %i Tokens: %i %i %i %i\n", iRet, iHold, aiHold[0], aiHold[1], aiHold[2], aiHold[3] ) ); \
            bIgnoreWords = FALSE;\
            \
            if( iRet < 256 ) \
            { \
               if( acNewLine[iRet] ) bNewLine = TRUE; \
            } \
            \
            DEBUG_INFO( printf(  "Reducing Held: %i Pos: %i\n", iRet, iHold ) ); \
            \
            LEX_RETURN( Reduce( iRet, CARGO ) ); \

#define LEX_RETURN(x) \
        \
        iRet = x;\
        \
        if( iRet < LEX_CUSTOM_ACTION ) \
        { \
           iRet = CUSTOM_ACTION(iRet); \
        } \
        \
        if( iRet ) \
        { \
           DEBUG_INFO( printf(  "Returning: %i\n", iRet ) ); \
           \
           INTERCEPT_ACTION(iRet); \
           \
           return iRet; \
        } \
        else \
        { \
           goto Start; \
        }

#define PUSH_TOKEN( iPushToken )\
{\
   aiHold[ iHold++ ] = iPushToken;\
   DEBUG_INFO( printf("Now Holding %i Tokens: %i %i %i %i\n", iHold, aiHold[0], aiHold[1], aiHold[2], aiHold[3] ) ); \
}

#ifndef YY_DECL
   #define YY_DECL int yylex( void )
#endif

YY_DECL
{
    LEX_USER_SETUP();

 Start :
    IF_TOKEN_READY()
    {
       RETURN_READY_TOKEN();
    }

    IF_TOKEN_ON_HOLD()
    {
       RELEASE_TOKEN();
    }

    if( iSize == 0 )
    {
       if( bStart )
       {
          bStart = FALSE;
          sPair = (char *) malloc( ( iPairAllocated = STREAM_ALLOC_SIZE ) );
          GenTrees();
          INIT_ACTION();
       }

       YY_INPUT( (char*) szLexBuffer, iSize, YY_BUF_SIZE );

       if( iSize )
       {
          s_szBuffer = (char*) szLexBuffer;

          DEBUG_INFO( printf(  "New Buffer: >%s<\n", szLexBuffer ) );
       }
       else
       {
          RESET_LEX();
          DEBUG_INFO( printf(  "1 - Returning: <EOF>\n" ) );
          return -1;
       }
    }

    #if USING_CARGO
       LEX_RETURN( Reduce( SimpLex_GetNextToken(CARGO), CARGO ) )
    #else
       LEX_RETURN( Reduce( SimpLex_GetNextToken() ) )
    #endif
}

int SimpLex_GetNextToken( DEF_CARGO )
{
    register char * szBuffer = s_szBuffer;

    iLen = 0;

    while( 1 )
    {
        if( iSize && *szBuffer )
        {
            if( iPairToken )
            {
               goto ProcessStream;
            }

            cPrev = chr;

            /* Get next character. */
            iSize--;
            chr = (*szBuffer++);

            /* Not using LEX_CASE() yet (white space)!!! */
            if( acOmmit[(int)chr] )
            {
               iLastLen = 1;

               while( iSize && acOmmit[(int)(*szBuffer)] )
               {
                  iSize--; szBuffer++; iLastLen++;
               }

               if( iLen )
               {
                  /* Terminate current token and check it. */
                  sToken[ iLen ] = '\0';

                  s_szBuffer = szBuffer;

                  DEBUG_INFO( printf(  "Token: \"%s\" Ommited: \'%c\'\n", sToken, chr ) );
                  return SimpLex_CheckToken( CARGO );
               }
               else
               {
                  continue;
               }
            }

            chr = LEX_CASE(chr);

            CHECK_SELF_CONTAINED(chr);

            /* New Pair ? */
            IF_BEGIN_PAIR( chr )
            {
               if( iLen )
               {
                  DEBUG_INFO( printf( "Holding Stream Mode: '%c' Buffer = >%s<\n", chr, szBuffer ) );

                  /* Terminate and Check Token to the left. */
                  sToken[ iLen ] = '\0';

                  s_szBuffer = szBuffer;

                  DEBUG_INFO( printf(  "Token: \"%s\" before New Pair at: \'%c\'\n", sToken, chr ) );
                  return SimpLex_CheckToken( CARGO );
               }

               ProcessStream :

               bIgnoreWords = FALSE;

               if( bTestLeft )
               {
                  IF_BELONG_LEFT( chr )
                  {
                     int iStartLen = (int) strlen( sStart );

                     /* Resetting. */
                     iPairToken = 0;

                     /* Rollingback. */
                     while( --iStartLen )
                     {
                        szBuffer--;
                     }

                     s_szBuffer = szBuffer;

                     DEBUG_INFO( printf(  "Reducing Left '%c'\n", chr ) );
                     return (int) chr ;
                  }
               }

               {
                  register int iPairLen = 0;
                  register char chrPair;

                  /* Look for the terminator. */
                  while( *szBuffer )
                  {
                     if( iPairLen + 1 >= iPairAllocated )
                     {
                        sPair = (char *) realloc( sPair, ( iPairAllocated += STREAM_ALLOC_SIZE ) );
                     }

                     if( iSize <= 0 )
                     {
                        int iRet = iPairToken;

                        sPair[ iPairLen ] = '\0';

                        STREAM_EXCEPTION( sPair, '\0' );

                        /* Reset */
                        iPairToken = 0;
                        s_szBuffer = szBuffer;

                        return iRet;
                     }

                     /* Next Character. */
                     iSize--;
                     chrPair = *szBuffer++ ;

                     /* Terminator ? */
                     if( chrPair == sTerm[0] )
                     {
                        register int iTermLen = 1;

                        if( sTerm[1] )
                        {
                           register char chrTerm = *szBuffer; /* Not using LEX_CASE() here !!! */

                           while( sTerm[iTermLen] )
                           {
                              if( chrTerm != sTerm[iTermLen] )
                              {
                                 /* Last charcter read. */
                                 chr = chrTerm;
                                 break;
                              }

                              iTermLen++;

                              chrTerm = *( szBuffer + iTermLen - 1 ); /* Not using LEX_CASE() here !!! */
                           }
                        }

                        /* Match */
                        if( sTerm[iTermLen] == '\0' )
                        {
                           /* Moving to next postion after the Stream Terminator. */
                           szBuffer += ( iTermLen - 1 );

                           sPair[ iPairLen ] = '\0';

                           if( bNewLine )
                           {
                              bNewLine = FALSE;
                              NEW_LINE_ACTION();
                           }

                           iRet = iPairToken;

                           /* Resetting. */
                           iPairToken = 0;

                           s_szBuffer = szBuffer;

                           DEBUG_INFO( printf(  "Returning Pair = >%s<\n", sPair ) );
                           return iRet;
                        }
                     }

                     /* Check if exception. */
                     IF_ABORT_PAIR( chrPair )
                     {
                        int iRet = iPairToken;

                        sPair[ iPairLen ] = '\0';

                        STREAM_EXCEPTION( sPair, chrPair );

                        /* Last charcter read. */
                        chr = chrPair;

                        /* Resetting. */
                        iPairToken = 0;
                        s_szBuffer = szBuffer;

                        return iRet;
                     }
                     else
                     {
                        STREAM_APPEND( chrPair );
                     }
                  }

                  /* EOF */

                  sPair[ iPairLen ] = '\0';

                  STREAM_EXCEPTION( sPair, (char) -1 );
               }

               {
                  int iRet = iPairToken;

                  /* Resetting. */
                  iPairToken = 0;
                  s_szBuffer = szBuffer;

                  return iRet;
               }
            }
            /* End Pairs. */

            /* NewLine ? */
            if( acNewLine[(int)chr] )
            {
               iLastLen = 1;

               while( iSize && acNewLine[(int)(*szBuffer)] )
               {
                  iSize--; szBuffer++; iLastLen++;
               }
               s_szBuffer = szBuffer;

               if( iLen )
               {
                   /* Will return NewLine on next call. */
                   HOLD_TOKEN( chr );

                   /* Terminate current token and check it. */
                   sToken[ iLen ] = '\0';

                   DEBUG_INFO( printf(  "Token: \"%s\" at <NewLine> Holding: \'%c\'\n", sToken, chr ) );
                   return SimpLex_CheckToken( CARGO );
               }
               else
               {
                   DEBUG_INFO( printf(  "Reducing NewLine '%c'\n", chr ) );
                   bIgnoreWords = FALSE;
                   bNewLine = TRUE;

                   return (int) chr;
               }
            }

            #ifdef USE_BELONGS
               IF_APPEND_DELIMITER( chr )
               {
                  /* Append and Terminate current token and check it. */
                  sToken[ iLen++ ] = chr;
                  sToken[ iLen ] = '\0';

                  iLastToken = iLen;

                  s_szBuffer = szBuffer;

                  DEBUG_INFO( printf(  "Token: \"%s\" Appended: \'%c\'\n", sToken, chr ) );
                  return SimpLex_CheckToken();
               }
            #endif

            if( acReturn[(int)chr] )
            {
                s_szBuffer = szBuffer;

                iLastLen = 1;

                if( iLen )
                {
                    /* Will be returned on next cycle. */

                    HOLD_TOKEN( acReturn[(int)chr] );

                    /* Terminate current token and check it. */
                    sToken[ iLen ] = '\0';

                    DEBUG_INFO( printf(  "Token: \"%s\" Holding: \'%c\' As: %i \n", sToken, chr, iRet ) );
                    return SimpLex_CheckToken( CARGO );
                }
                else
                {
                    bIgnoreWords = FALSE;

                    if( bNewLine )
                    {
                       bNewLine = FALSE;
                       NEW_LINE_ACTION();
                    }

                    DEBUG_INFO( printf(  "Reducing Delimiter: '%c' As: %i\n", chr, acReturn[(int)chr] ) );
                    return acReturn[(int)chr];
                }
            }

            /* Acumulate and scan next Charcter. */
            sToken[ iLen++ ] = chr;

            continue;
        }
        else
        {
            YY_INPUT( (char*) szLexBuffer, iSize, YY_BUF_SIZE );

            if( iSize )
            {
               szBuffer = (char*) szLexBuffer;

               continue;
            }
            else
            {
                if( iLen )
                {
                   /* <EOF> */
                   HOLD_TOKEN( -1 );

                   /* Terminate current token and check it. */
                   sToken[ iLen ] = '\0';

                   s_szBuffer = szBuffer;

                   DEBUG_INFO( printf(  "Token: \"%s\" at: \'<EOF>\'\n", sToken ) );
                   return SimpLex_CheckToken( CARGO );
                }
                else
                {
                   s_szBuffer = szBuffer;
                   RESET_LEX();
                   DEBUG_INFO( printf(  "2 - Returning: <EOF>\n", iRet ) );
                   return -1;
                }
            }
        }
    }

#ifdef NEED_DUMMY_RETURN
    return 0;  /* Some dumb compilers complain without this */
#endif
}

int SimpLex_CheckToken( DEF_CARGO )
{
    if( bRecursive )
    {
       return 0;
    }
    else
    {
       bRecursive = TRUE;
    }

    if( bNewLine )
    {
       bIgnoreWords = FALSE;

       NEW_LINE_ACTION();

       #ifdef USE_KEYWORDS
          SimpLex_CheckWords( CARGO );
          if( iRet )
          {
              bRecursive = FALSE;
              /* bIgnoreWords and bNewLine were handled by SimpLex_CheckWords(). */
              return iRet;
          }
       #endif
    }

    if( bIgnoreWords )
    {
       DEBUG_INFO( printf(  "Skiped Words for Word: %s\n", (char*) sToken ) );
       bIgnoreWords = FALSE;
    }
    else
    {
       SimpLex_CheckWords( CARGO );
       if( iRet )
       {
          bRecursive = FALSE;
          return iRet;
       }
    }

    DEBUG_INFO( printf(  "Reducing Element: \"%s\"\n", (char*) sToken ) );

    iRet = ELEMENT_TOKEN( (char*)sToken, iLen );

    bRecursive = FALSE;

    return iRet;
}

#if USING_CARGO
static int Reduce( int iToken, DEF_CARGO )
#else
static int Reduce( int iToken )
#endif
{
  BeginReduce :

   if( iToken < LEX_CUSTOM_ACTION )
   {
      iToken = CUSTOM_ACTION( iToken );
   }

   if( iToken > DONT_REDUCE )
   {
      iLastToken = ( iToken - DONT_REDUCE );
      DEBUG_INFO( printf(  "Returning Dont Reduce %i\n", iLastToken ) );
      return iLastToken;
   }
   else if( iToken <= 0 || iToken >= MAX_RULES )
   {
      DEBUG_INFO( printf( "Passing through (out of range): %i\n", iToken ) );
      return iToken;
   }

   iLastToken = iToken;

   /* No Rules for this token. */
   if( aRuleNodes[ iToken ].iMin == -1 )
   {
      DEBUG_INFO( printf( "Passing through: %i\n", iToken ) );
      return iToken;
   }
   else
   {
      register unsigned int iMax = (unsigned int)(aRuleNodes[ iToken ].iMax);
      register unsigned int iTentative = 0;

      iRule = (unsigned int)(aRuleNodes[ iToken ].iMin);
      iMatched = 1;

      DEBUG_INFO( printf(  "Scaning Prospects %i-%i at Pos: 0 for Token: %i\n", iRule, iMax -1, iToken ) );

      {
        FoundProspect :

         DEBUG_INFO( printf( "Prospect of %i Tokens - Testing Token: %i\n", iMatched, iToken ) );

         if( iMatched == MAX_MATCH || aiRules[iRule][iMatched] == 0 )
         {
            DEBUG_INFO( printf( "Saving Tentative %i - Found match of %i Tokens at Token: %i\n", iRule, iMatched, iToken ) );
            iTentative = iRule;
         }
         else
         {
            DEBUG_INFO( printf( "Partial Match - Get next Token after Token: %i\n", iToken ) );

            if( iHold )
            {
                iHold--;
                iToken = aiHold[ iHold ];
                bIgnoreWords = FALSE;
                if( iToken < 256 )
                {
                   if( acNewLine[iToken] ) bNewLine = TRUE;
                }
            }
            else
            {
               iToken = SimpLex_GetNextToken( CARGO );
            }

            if( iToken < LEX_CUSTOM_ACTION )
            {
               iToken = CUSTOM_ACTION( iToken );
            }

            if( iToken > DONT_REDUCE )
            {
               DEBUG_INFO( printf( "Reduce Forced for Token: %i\n", iToken - DONT_REDUCE ) );
               aiHold[iHold++] = iToken;
               goto AfterScanRules;
            }
            else
            {
               iLastToken = iToken;
            }

            if( aiRules[iRule][iMatched] == iToken )
            {
               /* Continue... Still a prospect. */
               DEBUG_INFO( printf( "Accepted Token: %i - Continue with this Rule...\n", iToken ) );
               iMatched++;
               goto FoundProspect;
            }
            else if( aiRules[iRule][iMatched] > iToken )
            {
               DEBUG_INFO( printf( "Rejected Token: %i - Giving up...\n", iToken ) );
               aiHold[iHold++] = iToken;
               goto AfterScanRules;
            }
            else
            {
               DEBUG_INFO( printf( "Rejected Token: %i - Continue with next Rule...\n", iToken ) );
               aiHold[iHold++] = iToken;
            }
         }

         if( iRule < iMax )
         {
            register unsigned int j = 1;

            DEBUG_INFO( printf( "Checking if next rule is extension of last Rule\n" ) );

            while( j < iMatched )
            {
               if( aiRules[iRule][j] != aiRules[iRule + 1][j] )
               {
                  break;
               }
               j++;
            }
            if( j < iMatched )
            {
               DEBUG_INFO( printf( "Rejected Rule - Not an extension of previous - Giving up...\n" ) );
            }
            else
            {
               DEBUG_INFO( printf( "Accepted Next Rule...\n" ) );
               iRule++;
               goto FoundProspect;
            }
         }
         else
         {
            DEBUG_INFO( printf( "No More prospects...\n" ) );
         }
      }

     AfterScanRules :

      if( iTentative )
      {
         DEBUG_INFO( printf( "Processing Tentative: %i\n", iTentative ) );

         while( iMatched > 1 && aiRules[iRule][iMatched - 1] && aiRules[iTentative][iMatched - 1] == 0 )
         {
            DEBUG_INFO( printf( "Reclaimed Token: %i\n", aiRules[iRule][iMatched - 1] ) );
            aiHold[iHold++] = aiRules[iRule][iMatched - 1];
            iMatched--;
         }

         if( aiRules[iTentative][MAX_MATCH] )
         {
            DEBUG_INFO( printf( "Reducing Rule: %i Found %i Tokens\n", iTentative, iMatched ) );

            if( aiRules[iTentative][MAX_MATCH + 1] )
            {
               DEBUG_INFO( printf( "Pushing Reduction: %i\n", aiRules[iTentative][MAX_MATCH + 1] ) );
               aiHold[iHold++] = aiRules[iTentative][MAX_MATCH + 1];
            }

            DEBUG_INFO( printf( "Recycling Reduction: %i\n", aiRules[iTentative][MAX_MATCH] ) );
            iToken = aiRules[iTentative][MAX_MATCH];
            goto BeginReduce;
         }
         else
         {
            DEBUG_INFO( printf( "Passing Through %i Tokens\n", iMatched ) );
            while( iMatched > 1 )
            {
               iMatched--;
               DEBUG_INFO( printf( "Stacking Return: %i\n", aiRules[iTentative][iMatched] ) );
               aiReturn[iReturn++] = aiRules[iTentative][iMatched];
            }
            DEBUG_INFO( printf( "Returning: %i\n", aiRules[iTentative][0] ) );
            return aiRules[iTentative][0];
         }
      }
      else
      {
         while( iMatched > 1 )
         {
            iMatched--;
            DEBUG_INFO( printf( "Pushing: %i\n", aiRules[iRule][iMatched] ) );
            aiHold[iHold++] = aiRules[iRule][iMatched];
         }

         DEBUG_INFO( printf( "Returning Shifted Left: %i\n", aiRules[iRule][0] ) );
         return aiRules[iRule][0];
      }
   }
}

void SimpLex_CheckWords( DEF_CARGO )
{
   int iTentative = -1, iCompare;
   unsigned int i, iMax, iLenMatched, iBaseSize = 0, iKeyLen, iSavedLen = 0;
   char *pNextSpacer, *sKeys2Match = NULL, *szBaseBuffer = s_szBuffer, cSpacer = chr;
   LEX_WORD *aCheck;
   BOOL bOptionalSpacer;
   char sDelimiterString[2], *sWord2Check;

  #ifdef DEBUG_LEX
   char sKeyDesc[] = "Key", sWordDesc[] = "Word", *sDesc;
  #endif
  #ifdef LEX_ABBREVIATE
   unsigned int iLen2Match;
  #endif

  #ifdef USE_KEYWORDS
   if( bNewLine )
   {
      i      = aKeyNodes[ (int)(sToken[0]) ].iMin;
      iMax   = aKeyNodes[ (int)(sToken[0]) ].iMax + 1;
      aCheck = (LEX_WORD*) ( &(aKeys[0]) );
     #ifdef DEBUG_LEX
      sDesc  = (char*) sKeyDesc;
     #endif
   }
   else
  #endif
   {
      i      = aWordNodes[ (int)(sToken[0]) ].iMin;
      iMax   = aWordNodes[ (int)(sToken[0]) ].iMax + 1;
      aCheck = (LEX_WORD*) ( &( aWords[0] ) );
     #ifdef DEBUG_LEX
      sDesc  = (char*) sWordDesc;
     #endif
   }

   bNewLine = FALSE;

   DEBUG_INFO( printf( "Pre-Scaning %ss for Token: %s at Positions: %i-%i\n", sDesc, (char*) sToken, i, iMax -1 ) );

   sWord2Check = (char *) sToken;

   while( i < iMax )
   {
      if( sWord2Check[1] < aCheck[i].sWord[1] )
      {
         DEBUG_INFO( printf( "Gave-Up! Token [%s] < Pattern [%s]\n", sWord2Check, aCheck[i].sWord ) );
         iRet = 0;
         return;
      }
      else if( sWord2Check[1] > aCheck[i].sWord[1] )
      {
         DEBUG_INFO( printf( "Skip... %s [%s] < [%s]\n", sDesc, aCheck[i].sWord, sWord2Check ) );
         i++;
         DEBUG_INFO( printf( "Continue with larger: [%s]\n", aCheck[i].sWord ) );
         continue;
      }
      else
      {
         break;
      }
   }

   while( i < iMax )
   {
      if( sKeys2Match )
      {
         pNextSpacer = strstr( sKeys2Match, "{WS}" );
         if( pNextSpacer )
         {
            bOptionalSpacer = FALSE;
         }
         else
         {
            pNextSpacer = strstr( sKeys2Match, "?WS?" );
            bOptionalSpacer = TRUE;
         }
      }
      else
      {
         sKeys2Match = aCheck[ i ].sWord;
         pNextSpacer = strstr( sKeys2Match, "{WS}" );
         if( pNextSpacer )
         {
            bOptionalSpacer = FALSE;
         }
         else
         {
            pNextSpacer = strstr( sKeys2Match, "?WS?" );
            bOptionalSpacer = TRUE;
         }
      }

      if( sWord2Check[0] < sKeys2Match[0] )
      {
         DEBUG_INFO( printf( "Gave-Up! Token [%s] < Pattern [%s]\n", sWord2Check, sKeys2Match ) );
         break;
      }
      else if( sWord2Check[0] > sKeys2Match[0] )
      {
         DEBUG_INFO( printf( "Skip... %s [%s] < [%s]\n", sDesc, sKeys2Match, sWord2Check ) );
         i++;
         if( ( iLenMatched = (int) ( sKeys2Match - aCheck[i - 1].sWord ) ) == 0 )
         {
            sKeys2Match = NULL;
            DEBUG_INFO( printf( "Continue with larger: [%s]\n", aCheck[i].sWord ) );
            continue;
         }

         /* Is there a next potential Pattern. */
         if( i < iMax && strncmp( aCheck[i - 1].sWord, aCheck[i].sWord, iLenMatched ) == 0  )
         {
            /* Same relative position, in the next Pattern. */
            sKeys2Match = aCheck[i].sWord + iLenMatched;
            DEBUG_INFO( printf( "Continue with larger: [%s] at: [%s]\n", aCheck[i].sWord, sKeys2Match ) );
            continue;
         }
         else
         {
            DEBUG_INFO( printf( "Gave-Up! %i !< %i or Pattern [%s] not compatible with last match\n", i, iMax, aCheck[i].sWord ) );
            break;
         }
      }

      if( pNextSpacer )
      {
         /* Token not followed by white space - can't match this [or any latter] pattern! */
         if( bOptionalSpacer == FALSE && ! acOmmit[(int)cSpacer] )
         {
            DEBUG_INFO( printf( "Skip... Pattern [%s] requires {WS}, cSpacer: %c\n", sKeys2Match, cSpacer ) );

            i++;
            if( ( iLenMatched = (int) ( sKeys2Match - aCheck[i - 1].sWord ) ) == 0 )
            {
               sKeys2Match = NULL;
               DEBUG_INFO( printf( "Continue with: [%s]\n", aCheck[i].sWord ) );
               continue;
            }

            /* Is there a next potential Pattern. */
            if( i < iMax && strncmp( aCheck[i - 1].sWord, aCheck[i].sWord, iLenMatched ) == 0  )
            {
               /* Same relative position, in the next Pattern. */
               sKeys2Match = aCheck[i].sWord + iLenMatched;
               DEBUG_INFO( printf( "Continue with: [%s] at: [%s]\n", aCheck[i].sWord, sKeys2Match ) );
               continue;
            }
            else
            {
               DEBUG_INFO( printf( "Gave-Up! %i !< %i or Pattern [%s] not compatible with last match\n", i, iMax, aCheck[i].sWord ) );
               break;
            }
         }

         iKeyLen = (int) ( pNextSpacer - sKeys2Match );
      }
      else
      {
         iKeyLen = (int) strlen( sKeys2Match );
      }

     #ifdef LEX_ABBREVIATE
      iLen2Match = iLen;
      DEBUG_INFO( printf( "iLenMatch %i\n", iLen2Match ) );

      if( iLen2Match < LEX_ABBREVIATE && iLen2Match < iKeyLen )
      {
         iLen2Match = ( LEX_ABBREVIATE < iKeyLen ) ? LEX_ABBREVIATE : iKeyLen ;
         DEBUG_INFO( printf( "iLenMatch from %i to %i\n", iLen, iLen2Match ) );
      }

      if( iLen2Match > iKeyLen && i < iMax - 1 )
      {
         DEBUG_INFO( printf( "Trying Next... length mismatch - iKeyLen: %i iLen2Match: %i comparing: [%s] with: [%s]\n", iKeyLen, iLen2Match, sWord2Check, sKeys2Match ) );
         i++;

         if( ( iLenMatched = (int) ( sKeys2Match - aCheck[i - 1].sWord ) ) == 0 )
         {
            sKeys2Match = NULL;
            DEBUG_INFO( printf( "Continue with: [%s]\n", aCheck[i].sWord ) );
            continue;
         }

         /* Is there a next potential Pattern. */
         if( i < iMax && strncmp( aCheck[i - 1].sWord, aCheck[i].sWord, iLenMatched ) == 0  )
         {
            /* Same relative position, in the next Pattern. */
            sKeys2Match = aCheck[i].sWord + iLenMatched;
            DEBUG_INFO( printf( "Continue with: [%s] at: [%s]\n", aCheck[i].sWord, sKeys2Match ) );
            continue;
         }
         else
         {
            DEBUG_INFO( printf( "Gave-Up! %i !< %i or Pattern [%s] not compatible with last match\n", i, iMax, aCheck[i].sWord ) );
            break;
         }
      }

      DEBUG_INFO( printf( "iKeyLen: %i iLen2Match: %i comparing: [%s] with: [%s]\n", iKeyLen, iLen2Match, sWord2Check, sKeys2Match ) );

      iCompare = strncmp( (char*) sWord2Check, sKeys2Match, iLen2Match );
     #else
      iCompare = strcmp( (char*) sWord2Check, sKeys2Match );
     #endif

      if( iCompare == 0 ) /* Match found */
      {
         if( pNextSpacer == NULL ) /* Full Match! */
         {
            DEBUG_INFO( printf( "Saving Tentative %s [%s] == [%s]\n", sDesc, sWord2Check, sKeys2Match ) );

            iTentative  = i;
            iLenMatched = (int) strlen( aCheck[i].sWord );

            /* Saving this pointer of the input stream, we might have to get here again. */
            szBaseBuffer = s_szBuffer; iBaseSize = iSize;
            DEBUG_INFO( printf( "Saved Buffer Position: %i at: [%s]\n", iBaseSize, szBaseBuffer ) );

            /* No White Space after last Token! */
            if( iHold || iPairToken )
            {
               DEBUG_INFO( printf( "No White space after [%s] Holding: %i\n", sWord2Check, aiHold[0] ) );
               break;
            }

         IsExtendedMatch :
            i++;

            /* Is there a next potential Pattern, that is an extended version of the current Pattern. */
            if( i < iMax && strncmp( aCheck[i - 1].sWord, aCheck[i].sWord, iLenMatched ) == 0 )
            {
               pNextSpacer = strstr( aCheck[i].sWord + iLenMatched, "{WS}" );
               if( pNextSpacer )
               {
                  bOptionalSpacer = FALSE;
               }
               else
               {
                  pNextSpacer = strstr( sKeys2Match, "?WS?" );
                  bOptionalSpacer = TRUE;
               }

               if( strlen( aCheck[i].sWord ) > ( iLenMatched + 4 ) && pNextSpacer )
               {
                  /* Same relative position, in the next Pattern. */
                  sKeys2Match = pNextSpacer + 4;
                  DEBUG_INFO( printf( "Continue with: [%s] at: [%s]\n", aCheck[i].sWord, sKeys2Match ) );
               }
               else
               {
                  DEBUG_INFO( printf( "Skip... - Not Extended: [%s]\n", aCheck[i].sWord ) );
                  goto IsExtendedMatch;
               }
            }
            else
            {
               DEBUG_INFO( printf( "Gave-Up! %i !< %i or Pattern [%s] not extension of Pattern [%s]\n", i, iMax, aCheck[i].sWord, aCheck[iTentative].sWord ) );
               break;
            }
         }
         else
         {
            sKeys2Match = pNextSpacer + 4;
            DEBUG_INFO( printf( "Partial %s Match! [%s] == [%s] - Looking for: [%s]\n", sDesc, sWord2Check, aCheck[i].sWord, sKeys2Match ) );

            // Held Token at this point may only be acOmmit, acReturn, acNewLine, or sSelf.
            if( iHold )
            {
               iHold--;

               iLen = iLastLen;

               s_szBuffer -= iLen;
               iSize += iLen;

               DEBUG_INFO( printf( "Rewinded iLen:%i held: %i token [%s] to [%s]\n", iLen, iHold, sWord2Check, s_szBuffer ) );
            }

            /* Saving this pointer of the input stream, we might have to get here again. */
            szBaseBuffer = s_szBuffer; iBaseSize = iSize;

            /* Saving Token Length. */
            iSavedLen = iLen;

            DEBUG_INFO( printf( "Saved Buffer Position: %i at: [%s] Len: %i\n", iBaseSize, szBaseBuffer, iSavedLen ) );
         }

         /* i may have been increased above - don't want to read next token if it won't get used! */
         if( i < iMax )
         {
            int iNextToken;

            bRecursive = TRUE;
            cSpacer = chr;

            DEBUG_INFO( printf( "Getting next Token...\n" ) );

            iNextToken = SimpLex_GetNextToken( CARGO );

            if( iNextToken == 0 )
            {
               sWord2Check = (char *) sToken;
            }
            else if( iLastLen == 1 )
            {
               sDelimiterString[0] = *( s_szBuffer - 1 );
               sDelimiterString[1] = '\0';

               sWord2Check = (char *) sDelimiterString;
            }
            else
            {
               sWord2Check = (char *) sSelf;
            }

            DEBUG_INFO( printf( "sToken [%s] sWord2Check [%s] iRet: %i iHold: %i\n", (char *) sToken, (char *) sWord2Check, iRet, iLen ) );
            continue;
         }
      }
      else if( iCompare > 0 )
      {
         DEBUG_INFO( printf( "Trying Next %s Pattern... [%s] > [%s]\n", sDesc, sWord2Check, sKeys2Match ) );
         i++;

         if( ( iLenMatched =  (int) ( sKeys2Match - aCheck[i - 1].sWord ) ) == 0 )
         {
            sKeys2Match = NULL;
            DEBUG_INFO( printf( "Continue with: [%s]\n", aCheck[i].sWord ) );
            continue;
         }

         /* Is there a next potential Pattern. */
         if( i < iMax && strncmp( aCheck[i - 1].sWord, aCheck[i].sWord, iLenMatched ) == 0 )
         {
            /* Same relative position, in the next Pattern. */
            sKeys2Match = aCheck[i].sWord + iLenMatched;
            DEBUG_INFO( printf( "Continue with: [%s] at: [%s]\n", aCheck[i].sWord, sKeys2Match ) );
            continue;
         }
         else
         {
            DEBUG_INFO( printf( "Gave-Up! %i !< %i or Pattern [%s] not compatible with previous match.\n", i, iMax, aCheck[i].sWord ) );
            break;
         }
      }
      else
      {
         DEBUG_INFO( printf( "Gave-Up! [%s] < [%s]\n", sWord2Check, sKeys2Match ) );
         break;
      }
   }

   if( s_szBuffer != szBaseBuffer )
   {
      s_szBuffer = szBaseBuffer; iSize = iBaseSize; iHold = 0; iReturn = 0; iPairToken = 0;
      iLen = iSavedLen;
      DEBUG_INFO( printf( "Partial Match - Restored position: %i at: [%s] Len: %i\n", iSize, s_szBuffer, iLen ) );
   }

   if( iTentative > -1 )
   {
      DEBUG_INFO( printf(  "Reducing %s Pattern: %i [%s] as: %i\n", sDesc, iTentative, aCheck[iTentative].sWord, aCheck[ iTentative ].iToken ) );

      bIgnoreWords = TRUE;

      iRet = aCheck[ iTentative ].iToken;
      if( iRet < LEX_CUSTOM_ACTION )
      {
         iRet = CUSTOM_ACTION( iRet );
      }
   }
   else
   {
      iRet = 0;
   }
}

#ifdef __cplusplus
   YY_BUFFER_STATE yy_create_buffer( FILE * pFile, int iBufSize )
#else
   void * yy_create_buffer( FILE * pFile, int iBufSize )
#endif
{
   /* Avoid warning of unused symbols. */
   (void) pFile;
   (void) iBufSize;

   iSize = 0;

   #ifdef __cplusplus
      return (YY_BUFFER_STATE) szLexBuffer;
   #else
      return (void*) szLexBuffer;
   #endif
}

#ifdef __cplusplus
   #if USING_CARGO
      void yy_switch_to_buffer( YY_BUFFER_STATE pBuffer, DEF_CARGO )
   #else
      void yy_switch_to_buffer( YY_BUFFER_STATE pBuffer )
   #endif
#else
   #if USING_CARGO
       void yy_switch_to_buffer( void * pBuffer, DEF_CARGO )
   #else
       void yy_switch_to_buffer( void * pBuffer )
   #endif
#endif
{
   /* Avoid warning of unused symbols. */
   (void) pBuffer;
   FORCE_REDUCE();
   iSize = 0;
}

#ifdef __cplusplus
   #if USING_CARGO
      void yy_delete_buffer( YY_BUFFER_STATE pBuffer, DEF_CARGO )
   #else
      void yy_delete_buffer( YY_BUFFER_STATE pBuffer )
   #endif
#else
   #if USING_CARGO
      void yy_delete_buffer( void * pBuffer, DEF_CARGO )
   #else
      void yy_delete_buffer( void * pBuffer )
   #endif
#endif
{
   /* Avoid warning of unused symbols. */
   (void) pBuffer;
   FORCE_REDUCE();
   iSize = 0;
}

void * yy_bytes_buffer( char * pBuffer, int iBufSize )
{
   s_szBuffer = pBuffer;
   iSize = iBufSize;

   if( bStart )
   {
      bStart = FALSE;
      GenTrees();
      INIT_ACTION();
   }

   return s_szBuffer;
}

static void GenTrees( void )
{
   register unsigned int i;
   register unsigned int iIndex;

   i = 0;
   while( i < 256 )
   {
      acOmmit[i]         = 0;
      acNewLine[i]       = 0;
      acReturn[i]        = 0;
      aPairNodes[i].iMin = -1;
      aPairNodes[i].iMax = -1;
      aSelfNodes[i].iMin = -1;
      aSelfNodes[i].iMax = -1;
      aKeyNodes[i].iMin  = -1;
      aKeyNodes[i].iMax  = -1;
      aWordNodes[i].iMin = -1;
      aWordNodes[i].iMax = -1;
      aRuleNodes[i].iMin = -1;
      aRuleNodes[i].iMax = -1;
      i++;
   }

   while( i < MAX_RULES )
   {
      aRuleNodes[i].iMin = -1;
      aRuleNodes[i].iMax = -1;
      i++;
   }

   i = 0;
   while ( szOmmit[i] )
   {
      acOmmit[ (int)(szOmmit[i]) ] = 1;
      i++;
   }

   i = 0;
   while ( szNewLine[i] )
   {
      acNewLine[ (int)(szNewLine[i]) ] = 1;
      i++;
   }

   i = 0;
   while ( i < iDelimiters )
   {
      acReturn[ (int)(aDelimiters[i].cDelimiter) ] = aDelimiters[i].iToken;
      i++;
   }

   i = 0;
   while ( i < iPairs )
   {
      iIndex = aPairs[i].sStart[0];
      if( aPairNodes[ iIndex ].iMin == -1 )
      {
         aPairNodes[ iIndex ].iMin = i;
      }
      aPairNodes[ iIndex ].iMax = i;
      i++;
   }

   i = 0;
   while ( i < iSelfs )
   {
      iIndex = aSelfs[i].sWord[0];
      if( aSelfNodes[ iIndex ].iMin == -1 )
      {
         aSelfNodes[ iIndex ].iMin = i;
      }
      aSelfNodes[ iIndex ].iMax = i;
      i++;
   }

   #ifdef USE_KEYWORDS
      i = 0;
      while ( i < iKeys )
      {
         iIndex = aKeys[i].sWord[0];
         if( aKeyNodes[ iIndex ].iMin == -1 )
         {
            aKeyNodes[ iIndex ].iMin = i;
         }
         aKeyNodes[ iIndex ].iMax = i;
         i++;
      }
   #endif

   i = 0;
   while ( i < iWords )
   {
      iIndex = aWords[i].sWord[0];
      if( aWordNodes[ iIndex ].iMin == -1 )
      {
         aWordNodes[ iIndex ].iMin = i;
      }
      aWordNodes[ iIndex ].iMax = i;
      i++;
   }

   /* Reduce logic excpects the Rules to be sorted.  */
   qsort( ( void * ) aiRules, iRules, LEX_RULE_SIZE, rulecmp );

   i = 0;
   while ( i < iRules )
   {
      iIndex = (unsigned int) aiRules[i][0];
      if( iIndex > 1023 )
      {
         printf( "ERROR! Primary Token: %i out of range.\n", (int) iIndex );
         exit( EXIT_FAILURE );
      }
      if( aRuleNodes[ iIndex ].iMin == -1 )
      {
         aRuleNodes[ iIndex ].iMin = i;
      }
      aRuleNodes[ iIndex ].iMax = i;
      i++;
   }
}

static int rulecmp( const void * pLeft, const void * pRight )
{
   int *iLeftRule  = (int*)( pLeft );
   int *iRightRule = (int*)( pRight );
   register unsigned int i = 0;

   while( iLeftRule[i] == iRightRule[i] )
   {
      i++;
      if ( i >= LEX_RULE_SIZE )
      {
         return 0;
      }
   }

   if( iLeftRule[i] < iRightRule[i] )
   {
      return -1;
   }
   else
   {
      return 1;
   }
}
