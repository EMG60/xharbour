#ifndef _DMUSICF_H
#define _DMUSICF_H

/* DirectMusic file format definitions */

#include <windows.h>

#define COM_NO_WINDOWS_H
#include <objbase.h>
#include <mmsystem.h>

#include <pshpack8.h>

#ifdef __cplusplus
extern "C" {
#endif

interface IDirectMusicCollection;
#ifndef __cplusplus
typedef interface IDirectMusicCollection IDirectMusicCollection;
#endif

#define DMUS_FOURCC_GUID_CHUNK  mmioFOURCC('g','u','i','d')
#define DMUS_FOURCC_INFO_LIST  mmioFOURCC('I','N','F','O')
#define DMUS_FOURCC_UNFO_LIST  mmioFOURCC('U','N','F','O')
#define DMUS_FOURCC_UNAM_CHUNK  mmioFOURCC('U','N','A','M')
#define DMUS_FOURCC_UART_CHUNK  mmioFOURCC('U','A','R','T')
#define DMUS_FOURCC_UCOP_CHUNK  mmioFOURCC('U','C','O','P')
#define DMUS_FOURCC_USBJ_CHUNK  mmioFOURCC('U','S','B','J')
#define DMUS_FOURCC_UCMT_CHUNK  mmioFOURCC('U','C','M','T')
#define DMUS_FOURCC_CATEGORY_CHUNK  mmioFOURCC('c','a','t','g')
#define DMUS_FOURCC_VERSION_CHUNK  mmioFOURCC('v','e','r','s')

#define DMUS_FOURCC_STYLE_FORM  mmioFOURCC('D','M','S','T')
#define DMUS_FOURCC_STYLE_CHUNK  mmioFOURCC('s','t','y','h')
#define DMUS_FOURCC_PART_LIST  mmioFOURCC('p','a','r','t')
#define DMUS_FOURCC_PART_CHUNK  mmioFOURCC('p','r','t','h')
#define DMUS_FOURCC_NOTE_CHUNK  mmioFOURCC('n','o','t','e')
#define DMUS_FOURCC_CURVE_CHUNK  mmioFOURCC('c','r','v','e')
#define DMUS_FOURCC_MARKER_CHUNK  mmioFOURCC('m','r','k','r')
#define DMUS_FOURCC_RESOLUTION_CHUNK  mmioFOURCC('r','s','l','n')
#define DMUS_FOURCC_ANTICIPATION_CHUNK  mmioFOURCC('a','n','p','n')
#define DMUS_FOURCC_PATTERN_LIST  mmioFOURCC('p','t','t','n')
#define DMUS_FOURCC_PATTERN_CHUNK  mmioFOURCC('p','t','n','h')
#define DMUS_FOURCC_RHYTHM_CHUNK  mmioFOURCC('r','h','t','m')
#define DMUS_FOURCC_PARTREF_LIST  mmioFOURCC('p','r','e','f')
#define DMUS_FOURCC_PARTREF_CHUNK  mmioFOURCC('p','r','f','c')
#define DMUS_FOURCC_STYLE_PERS_REF_LIST  mmioFOURCC('p','r','r','f')
#define DMUS_FOURCC_MOTIFSETTINGS_CHUNK  mmioFOURCC('m','t','f','s')

#define DMUS_VARIATIONF_MAJOR  0x0000007F
#define DMUS_VARIATIONF_MINOR  0x00003F80
#define DMUS_VARIATIONF_OTHER  0x001FC000
#define DMUS_VARIATIONF_ROOT_SCALE  0x00200000
#define DMUS_VARIATIONF_ROOT_FLAT  0x00400000
#define DMUS_VARIATIONF_ROOT_SHARP  0x00800000
#define DMUS_VARIATIONF_TYPE_TRIAD  0x01000000
#define DMUS_VARIATIONF_TYPE_6AND7  0x02000000
#define DMUS_VARIATIONF_TYPE_COMPLEX 0x04000000
#define DMUS_VARIATIONF_DEST_TO1  0x08000000
#define DMUS_VARIATIONF_DEST_TO5  0x10000000
#define DMUS_VARIATIONF_DEST_OTHER  0x40000000

#define DMUS_VARIATIONF_MODES  0xE0000000
#define DMUS_VARIATIONF_MODES_EX  (0x20000000|0x80000000)
#define DMUS_VARIATIONF_IMA25_MODE  0x00000000
#define DMUS_VARIATIONF_DMUS_MODE  0x20000000

#define DMUS_PARTF_USE_MARKERS  0x1
#define DMUS_PARTF_ALIGN_CHORDS  0x2

#define DMUS_MARKERF_START  0x1
#define DMUS_MARKERF_STOP  0x2
#define DMUS_MARKERF_CHORD_ALIGN  0x4

#define DMUS_PATTERNF_PERSIST_CONTROL 0x1

#define DMUS_FOURCC_PATTERN_FORM  mmioFOURCC('D','M','P','T')

#define DMUS_FOURCC_CHORDTRACK_LIST  mmioFOURCC('c','o','r','d')
#define DMUS_FOURCC_CHORDTRACKHEADER_CHUNK  mmioFOURCC('c','r','d','h')
#define DMUS_FOURCC_CHORDTRACKBODY_CHUNK  mmioFOURCC('c','r','d','b')

#define DMUS_FOURCC_COMMANDTRACK_CHUNK  mmioFOURCC('c','m','n','d')

#define DMUS_FOURCC_TOOLGRAPH_FORM  mmioFOURCC('D','M','T','G')
#define DMUS_FOURCC_TOOL_LIST  mmioFOURCC('t','o','l','l')
#define DMUS_FOURCC_TOOL_FORM  mmioFOURCC('D','M','T','L')
#define DMUS_FOURCC_TOOL_CHUNK  mmioFOURCC('t','o','l','h')

#define DMUS_FOURCC_AUDIOPATH_FORM  mmioFOURCC('D','M','A','P')

#define DMUS_FOURCC_PORTCONFIGS_LIST  mmioFOURCC('p','c','s','l')
#define DMUS_FOURCC_PORTCONFIG_LIST  mmioFOURCC('p','c','f','l')
#define DMUS_FOURCC_PORTCONFIG_ITEM  mmioFOURCC('p','c','f','h')
#define DMUS_FOURCC_PORTPARAMS_ITEM  mmioFOURCC('p','p','r','h')
#define DMUS_FOURCC_DSBUFFER_LIST  mmioFOURCC('d','b','f','l')
#define DMUS_FOURCC_DSBUFFATTR_ITEM  mmioFOURCC('d','d','a','h')
#define DMUS_FOURCC_PCHANNELS_LIST  mmioFOURCC('p','c','h','l')
#define DMUS_FOURCC_PCHANNELS_ITEM  mmioFOURCC('p','c','h','h')

#define DMUS_PORTCONFIGF_DRUMSON10  1
#define DMUS_PORTCONFIGF_USEDEFAULT 2

#define DMUS_BUFFERF_SHARED  1
#define DMUS_BUFFERF_DEFINED  2
#define DMUS_BUFFERF_MIXIN  8

#define DMUS_FOURCC_BANDTRACK_FORM  mmioFOURCC('D','M','B','T')
#define DMUS_FOURCC_BANDTRACK_CHUNK mmioFOURCC('b','d','t','h')
#define DMUS_FOURCC_BANDS_LIST  mmioFOURCC('l','b','d','l')
#define DMUS_FOURCC_BAND_LIST  mmioFOURCC('l','b','n','d')
#define DMUS_FOURCC_BANDITEM_CHUNK  mmioFOURCC('b','d','i','h')
#define DMUS_FOURCC_BANDITEM_CHUNK2 mmioFOURCC('b','d','2','h')

#define DMUS_FOURCC_BAND_FORM  mmioFOURCC('D','M','B','D')
#define DMUS_FOURCC_INSTRUMENTS_LIST  mmioFOURCC('l','b','i','l')
#define DMUS_FOURCC_INSTRUMENT_LIST  mmioFOURCC('l','b','i','n')
#define DMUS_FOURCC_INSTRUMENT_CHUNK  mmioFOURCC('b','i','n','s')

#define DMUS_IO_INST_PATCH  (1<<0)
#define DMUS_IO_INST_BANKSELECT  (1<<1)
#define DMUS_IO_INST_ASSIGN_PATCH  (1<<3)
#define DMUS_IO_INST_NOTERANGES  (1<<4)
#define DMUS_IO_INST_PAN  (1<<5)
#define DMUS_IO_INST_VOLUME  (1<<6)
#define DMUS_IO_INST_TRANSPOSE  (1<<7)
#define DMUS_IO_INST_GM  (1<<8)
#define DMUS_IO_INST_GS  (1<<9)
#define DMUS_IO_INST_XG  (1<<10)
#define DMUS_IO_INST_CHANNEL_PRIORITY (1<<11)
#define DMUS_IO_INST_USE_DEFAULT_GM_SET (1<<12)

#define DMUS_IO_INST_PITCHBENDRANGE (1<<13)

#define DMUS_FOURCC_WAVEHEADER_CHUNK  mmioFOURCC('w','a','v','h')

#define DMUS_FOURCC_WAVETRACK_LIST  mmioFOURCC('w','a','v','t')
#define DMUS_FOURCC_WAVETRACK_CHUNK  mmioFOURCC('w','a','t','h')
#define DMUS_FOURCC_WAVEPART_LIST  mmioFOURCC('w','a','v','p')
#define DMUS_FOURCC_WAVEPART_CHUNK  mmioFOURCC('w','a','p','h')
#define DMUS_FOURCC_WAVEITEM_LIST  mmioFOURCC('w','a','v','i')
#define DMUS_FOURCC_WAVE_LIST  mmioFOURCC('w','a','v','e')
#define DMUS_FOURCC_WAVEITEM_CHUNK  mmioFOURCC('w','a','i','h')

#define DMUS_WAVETRACKF_SYNC_VAR  0x1
#define DMUS_WAVETRACKF_PERSIST_CONTROL 0x2

#define DMUS_FOURCC_CONTAINER_FORM  mmioFOURCC('D','M','C','N')
#define DMUS_FOURCC_CONTAINER_CHUNK  mmioFOURCC('c','o','n','h')
#define DMUS_FOURCC_CONTAINED_ALIAS_CHUNK  mmioFOURCC('c','o','b','a')
#define DMUS_FOURCC_CONTAINED_OBJECT_CHUNK  mmioFOURCC('c','o','b','h')
#define DMUS_FOURCC_CONTAINED_OBJECTS_LIST  mmioFOURCC('c','o','s','l')
#define DMUS_FOURCC_CONTAINED_OBJECT_LIST  mmioFOURCC('c','o','b','l')

#define DMUS_CONTAINER_NOLOADS  (1<<1)

#define DMUS_CONTAINED_OBJF_KEEP  1

#define DMUS_FOURCC_SEGMENT_FORM  mmioFOURCC('D','M','S','G')
#define DMUS_FOURCC_SEGMENT_CHUNK  mmioFOURCC('s','e','g','h')
#define DMUS_FOURCC_TRACK_LIST  mmioFOURCC('t','r','k','l')
#define DMUS_FOURCC_TRACK_FORM  mmioFOURCC('D','M','T','K')
#define DMUS_FOURCC_TRACK_CHUNK  mmioFOURCC('t','r','k','h')
#define DMUS_FOURCC_TRACK_EXTRAS_CHUNK  mmioFOURCC('t','r','k','x')

#define DMUS_SEGIOF_REFLENGTH  1

#define DMUS_FOURCC_SONG_FORM  mmioFOURCC('D','M','S','O')
#define DMUS_FOURCC_SONG_CHUNK  mmioFOURCC('s','n','g','h')
#define DMUS_FOURCC_SONGSEGMENTS_LIST  mmioFOURCC('s','e','g','l')
#define DMUS_FOURCC_SONGSEGMENT_LIST  mmioFOURCC('s','s','g','l')
#define DMUS_FOURCC_TOOLGRAPHS_LIST  mmioFOURCC('t','l','g','l')
#define DMUS_FOURCC_SEGREFS_LIST  mmioFOURCC('s','r','s','l')
#define DMUS_FOURCC_SEGREF_LIST  mmioFOURCC('s','g','r','l')
#define DMUS_FOURCC_SEGREF_CHUNK  mmioFOURCC('s','g','r','h')
#define DMUS_FOURCC_SEGTRANS_CHUNK  mmioFOURCC('s','t','r','h')
#define DMUS_FOURCC_TRACKREFS_LIST  mmioFOURCC('t','r','s','l')
#define DMUS_FOURCC_TRACKREF_LIST  mmioFOURCC('t','k','r','l')
#define DMUS_FOURCC_TRACKREF_CHUNK  mmioFOURCC('t','k','r','h')

#define DMUS_SONG_MAXSEGID  0x7FFFFFFF
#define DMUS_SONG_ANYSEG  0x80000000
#define DMUS_SONG_NOSEG  0xFFFFFFFF
#define DMUS_SONG_NOFROMSEG  0x80000001

#define DMUS_FOURCC_REF_LIST  mmioFOURCC('D','M','R','F')
#define DMUS_FOURCC_REF_CHUNK  mmioFOURCC('r','e','f','h')
#define DMUS_FOURCC_DATE_CHUNK  mmioFOURCC('d','a','t','e')
#define DMUS_FOURCC_NAME_CHUNK  mmioFOURCC('n','a','m','e')
#define DMUS_FOURCC_FILE_CHUNK  mmioFOURCC('f','i','l','e')

#define DMUS_FOURCC_CHORDMAP_FORM  mmioFOURCC('D','M','P','R')
#define DMUS_FOURCC_IOCHORDMAP_CHUNK  mmioFOURCC('p','e','r','h')
#define DMUS_FOURCC_SUBCHORD_CHUNK  mmioFOURCC('c','h','d','t')
#define DMUS_FOURCC_CHORDENTRY_CHUNK  mmioFOURCC('c','h','e','h')
#define DMUS_FOURCC_SUBCHORDID_CHUNK  mmioFOURCC('s','b','c','n')
#define DMUS_FOURCC_IONEXTCHORD_CHUNK  mmioFOURCC('n','c','r','d')
#define DMUS_FOURCC_NEXTCHORDSEQ_CHUNK  mmioFOURCC('n','c','s','q')
#define DMUS_FOURCC_IOSIGNPOST_CHUNK  mmioFOURCC('s','p','s','h')
#define DMUS_FOURCC_CHORDNAME_CHUNK  mmioFOURCC('I','N','A','M')
#define DMUS_FOURCC_CHORDENTRY_LIST  mmioFOURCC('c','h','o','e')
#define DMUS_FOURCC_CHORDMAP_LIST  mmioFOURCC('c','m','a','p')
#define DMUS_FOURCC_CHORD_LIST  mmioFOURCC('c','h','r','d')
#define DMUS_FOURCC_CHORDPALETTE_LIST  mmioFOURCC('c','h','p','l')
#define DMUS_FOURCC_CADENCE_LIST  mmioFOURCC('c','a','d','e')
#define DMUS_FOURCC_SIGNPOSTITEM_LIST  mmioFOURCC('s','p','s','t')

#define DMUS_FOURCC_SIGNPOST_LIST  mmioFOURCC('s','p','s','q')

#define DMUS_SIGNPOSTF_A  1
#define DMUS_SIGNPOSTF_B  2
#define DMUS_SIGNPOSTF_C  4
#define DMUS_SIGNPOSTF_D  8
#define DMUS_SIGNPOSTF_E  0x10
#define DMUS_SIGNPOSTF_F  0x20
#define DMUS_SIGNPOSTF_LETTER  (DMUS_SIGNPOSTF_A|DMUS_SIGNPOSTF_B|DMUS_SIGNPOSTF_C|DMUS_SIGNPOSTF_D|DMUS_SIGNPOSTF_E|DMUS_SIGNPOSTF_F)
#define DMUS_SIGNPOSTF_1  0x100
#define DMUS_SIGNPOSTF_2  0x200
#define DMUS_SIGNPOSTF_3  0x400
#define DMUS_SIGNPOSTF_4  0x800
#define DMUS_SIGNPOSTF_5  0x1000
#define DMUS_SIGNPOSTF_6  0x2000
#define DMUS_SIGNPOSTF_7  0x4000
#define DMUS_SIGNPOSTF_ROOT  (DMUS_SIGNPOSTF_1|DMUS_SIGNPOSTF_2|DMUS_SIGNPOSTF_3|DMUS_SIGNPOSTF_4|DMUS_SIGNPOSTF_5|DMUS_SIGNPOSTF_6|DMUS_SIGNPOSTF_7)
#define DMUS_SIGNPOSTF_CADENCE  0x8000

#define DMUS_CHORDMAPF_VERSION8  1

#define DMUS_SPOSTCADENCEF_1  2
#define DMUS_SPOSTCADENCEF_2  4

#define DMUS_FOURCC_SCRIPT_FORM  mmioFOURCC('D','M','S','C')
#define DMUS_FOURCC_SCRIPT_CHUNK  mmioFOURCC('s','c','h','d')
#define DMUS_FOURCC_SCRIPTVERSION_CHUNK  mmioFOURCC('s','c','v','e')
#define DMUS_FOURCC_SCRIPTLANGUAGE_CHUNK  mmioFOURCC('s','c','l','a')
#define DMUS_FOURCC_SCRIPTSOURCE_CHUNK  mmioFOURCC('s','c','s','r')

#define DMUS_SCRIPTIOF_LOAD_ALL_CONTENT  (1<<0)
#define DMUS_SCRIPTIOF_DOWNLOAD_ALL_SEGMENTS  (1<<1)

#define DMUS_FOURCC_SIGNPOST_TRACK_CHUNK  mmioFOURCC( 's','g','n','p')

#define DMUS_FOURCC_MUTE_CHUNK  mmioFOURCC('m','u','t','e')

#define DMUS_FOURCC_TIME_STAMP_CHUNK  mmioFOURCC('s','t','m','p')

#define DMUS_FOURCC_STYLE_TRACK_LIST  mmioFOURCC('s','t','t','r')
#define DMUS_FOURCC_STYLE_REF_LIST  mmioFOURCC('s','t','r','f')

#define DMUS_FOURCC_PERS_TRACK_LIST mmioFOURCC('p','f','t','r')
#define DMUS_FOURCC_PERS_REF_LIST  mmioFOURCC('p','f','r','f')

#define DMUS_FOURCC_TEMPO_TRACK  mmioFOURCC('t','e','t','r')

#define DMUS_FOURCC_SEQ_TRACK  mmioFOURCC('s','e','q','t')
#define DMUS_FOURCC_SEQ_LIST  mmioFOURCC('e','v','t','l')
#define DMUS_FOURCC_CURVE_LIST  mmioFOURCC('c','u','r','l')

#define DMUS_FOURCC_SYSEX_TRACK  mmioFOURCC('s','y','e','x')

#define DMUS_FOURCC_TIMESIGNATURE_TRACK mmioFOURCC('t','i','m','s')

#define DMUS_FOURCC_TIMESIGTRACK_LIST  mmioFOURCC('T','I','M','S')
#define DMUS_FOURCC_TIMESIG_CHUNK  DMUS_FOURCC_TIMESIGNATURE_TRACK

#define DMUS_FOURCC_MARKERTRACK_LIST  mmioFOURCC('M','A','R','K')
#define DMUS_FOURCC_VALIDSTART_CHUNK  mmioFOURCC('v','a','l','s')
#define DMUS_FOURCC_PLAYMARKER_CHUNK  mmioFOURCC('p','l','a','y')

#define DMUS_FOURCC_SEGTRACK_LIST  mmioFOURCC('s','e','g','t')
#define DMUS_FOURCC_SEGTRACK_CHUNK  mmioFOURCC('s','g','t','h')
#define DMUS_FOURCC_SEGMENTS_LIST  mmioFOURCC('l','s','g','l')
#define DMUS_FOURCC_SEGMENT_LIST  mmioFOURCC('l','s','e','g')
#define DMUS_FOURCC_SEGMENTITEM_CHUNK  mmioFOURCC('s','g','i','h')
#define DMUS_FOURCC_SEGMENTITEMNAME_CHUNK  mmioFOURCC('s','n','a','m')

#define DMUS_SEGMENTTRACKF_MOTIF  1

#define DMUS_FOURCC_SCRIPTTRACK_LIST  mmioFOURCC('s','c','r','t')
#define DMUS_FOURCC_SCRIPTTRACKEVENTS_LIST  mmioFOURCC('s','c','r','l')
#define DMUS_FOURCC_SCRIPTTRACKEVENT_LIST  mmioFOURCC('s','c','r','e')
#define DMUS_FOURCC_SCRIPTTRACKEVENTHEADER_CHUNK  mmioFOURCC('s','c','r','h')
#define DMUS_FOURCC_SCRIPTTRACKEVENTNAME_CHUNK  mmioFOURCC('s','c','r','n')

#define DMUS_IO_SCRIPTTRACKF_PREPARE (1<<0)
#define DMUS_IO_SCRIPTTRACKF_QUEUE  (1<<1)
#define DMUS_IO_SCRIPTTRACKF_ATTIME  (1<<2)

#define DMUS_FOURCC_LYRICSTRACK_LIST  mmioFOURCC('l','y','r','t')
#define DMUS_FOURCC_LYRICSTRACKEVENTS_LIST  mmioFOURCC('l','y','r','l')
#define DMUS_FOURCC_LYRICSTRACKEVENT_LIST  mmioFOURCC('l','y','r','e')
#define DMUS_FOURCC_LYRICSTRACKEVENTHEADER_CHUNK  mmioFOURCC('l','y','r','h')
#define DMUS_FOURCC_LYRICSTRACKEVENTTEXT_CHUNK  mmioFOURCC('l','y','r','n')

#define DMUS_FOURCC_PARAMCONTROLTRACK_TRACK_LIST  mmioFOURCC('p','r','m','t')
#define DMUS_FOURCC_PARAMCONTROLTRACK_OBJECT_LIST  mmioFOURCC('p','r','o','l')
#define DMUS_FOURCC_PARAMCONTROLTRACK_OBJECT_CHUNK  mmioFOURCC('p','r','o','h')
#define DMUS_FOURCC_PARAMCONTROLTRACK_PARAM_LIST  mmioFOURCC('p','r','p','l')
#define DMUS_FOURCC_PARAMCONTROLTRACK_PARAM_CHUNK  mmioFOURCC('p','r','p','h')
#define DMUS_FOURCC_PARAMCONTROLTRACK_CURVES_CHUNK  mmioFOURCC('p','r','c','c')

#define DMUS_FOURCC_MELODYFORM_TRACK_LIST  mmioFOURCC( 'm','f','r','m')
#define DMUS_FOURCC_MELODYFORM_HEADER_CHUNK  mmioFOURCC( 'm','l','f','h')
#define DMUS_FOURCC_MELODYFORM_BODY_CHUNK  mmioFOURCC( 'm','l','f','b')

typedef struct _DMUS_IO_SEQ_ITEM {
    MUSIC_TIME mtTime;
    MUSIC_TIME mtDuration;
    DWORD dwPChannel;
    short nOffset;
    BYTE bStatus;
    BYTE bByte1;
    BYTE bByte2;
} DMUS_IO_SEQ_ITEM;

typedef struct _DMUS_IO_CURVE_ITEM {
    MUSIC_TIME mtStart;
    MUSIC_TIME mtDuration;
    MUSIC_TIME mtResetDuration;
    DWORD dwPChannel;
    short nOffset;
    short nStartValue;
    short nEndValue;
    short nResetValue;
    BYTE bType;
    BYTE bCurveShape;
    BYTE bCCData;
    BYTE bFlags;
    WORD wParamType;
    WORD wMergeIndex;
} DMUS_IO_CURVE_ITEM;

typedef struct _DMUS_IO_TEMPO_ITEM {
    MUSIC_TIME lTime;
    double dblTempo;
} DMUS_IO_TEMPO_ITEM;

typedef struct _DMUS_IO_SYSEX_ITEM {
    MUSIC_TIME mtTime;
    DWORD dwPChannel;
    DWORD dwSysExLength;
} DMUS_IO_SYSEX_ITEM;

typedef DMUS_CHORD_KEY DMUS_CHORD_PARAM;

typedef struct _DMUS_RHYTHM_PARAM {
    DMUS_TIMESIGNATURE TimeSig;
    DWORD dwRhythmPattern;
} DMUS_RHYTHM_PARAM;

typedef struct _DMUS_TEMPO_PARAM {
    MUSIC_TIME mtTime;
    double dblTempo;
} DMUS_TEMPO_PARAM;

typedef struct _DMUS_MUTE_PARAM {
    DWORD dwPChannel;
    DWORD dwPChannelMap;
    BOOL fMute;
} DMUS_MUTE_PARAM;

typedef enum enumDMUS_VARIATIONT_TYPES {
    DMUS_VARIATIONT_SEQUENTIAL = 0,
    DMUS_VARIATIONT_RANDOM = 1,
    DMUS_VARIATIONT_RANDOM_START = 2,
    DMUS_VARIATIONT_NO_REPEAT = 3,
    DMUS_VARIATIONT_RANDOM_ROW = 4
} DMUS_VARIATIONT_TYPES;

#include <pshpack2.h>

typedef struct _DMUS_IO_TIMESIG {
    BYTE bBeatsPerMeasure;
    BYTE bBeat;

    WORD wGridsPerBeat;
} DMUS_IO_TIMESIG;

typedef struct _DMUS_IO_STYLE {
    DMUS_IO_TIMESIG timeSig;
    double dblTempo;
} DMUS_IO_STYLE;

typedef struct _DMUS_IO_VERSION {
    DWORD dwVersionMS;
    DWORD dwVersionLS;
} DMUS_IO_VERSION;

typedef struct _DMUS_IO_PATTERN {
    DMUS_IO_TIMESIG timeSig;
    BYTE bGrooveBottom;
    BYTE bGrooveTop;
    WORD wEmbellishment;
    WORD wNbrMeasures;
    BYTE bDestGrooveBottom;
    BYTE bDestGrooveTop;
    DWORD dwFlags;
} DMUS_IO_PATTERN;

typedef struct _DMUS_IO_STYLEPART {
    DMUS_IO_TIMESIG timeSig;
    DWORD dwVariationChoices[32];
    GUID guidPartID;
    WORD wNbrMeasures;
    BYTE bPlayModeFlags;
    BYTE bInvertUpper;
    BYTE bInvertLower;
    BYTE bPad[3];
    DWORD dwFlags;
} DMUS_IO_STYLEPART;

typedef struct _DMUS_IO_PARTREF {
    GUID guidPartID;
    WORD wLogicalPartID;
    BYTE bVariationLockID;
    BYTE bSubChordLevel;
    BYTE bPriority;
    BYTE bRandomVariation;
    WORD wPad;
    DWORD dwPChannel;
} DMUS_IO_PARTREF;

typedef struct _DMUS_IO_STYLENOTE {
    MUSIC_TIME mtGridStart;
    DWORD dwVariation;
    MUSIC_TIME mtDuration;
    short nTimeOffset;
    WORD wMusicValue;
    BYTE bVelocity;
    BYTE bTimeRange;
    BYTE bDurRange;
    BYTE bVelRange;
    BYTE bInversionID;
    BYTE bPlayModeFlags;
    BYTE bNoteFlags;
} DMUS_IO_STYLENOTE;

typedef struct _DMUS_IO_STYLECURVE {
    MUSIC_TIME mtGridStart;
    DWORD dwVariation;
    MUSIC_TIME mtDuration;
    MUSIC_TIME mtResetDuration;
    short nTimeOffset;
    short nStartValue;
    short nEndValue;
    short nResetValue;
    BYTE bEventType;
    BYTE bCurveShape;
    BYTE bCCData;
    BYTE bFlags;
    WORD wParamType;
    WORD wMergeIndex;
} DMUS_IO_STYLECURVE;

typedef struct _DMUS_IO_STYLEMARKER {
    MUSIC_TIME mtGridStart;
    DWORD dwVariation;
    WORD wMarkerFlags;
} DMUS_IO_STYLEMARKER;

typedef struct _DMUS_IO_STYLERESOLUTION {
    DWORD dwVariation;
    WORD wMusicValue;
    BYTE bInversionID;
    BYTE bPlayModeFlags;
} DMUS_IO_STYLERESOLUTION;

typedef struct _DMUS_IO_STYLE_ANTICIPATION {
    MUSIC_TIME mtGridStart;
    DWORD dwVariation;
    short nTimeOffset;
    BYTE bTimeRange;
} DMUS_IO_STYLE_ANTICIPATION;

typedef struct _DMUS_IO_MOTIFSETTINGS {
    DWORD dwRepeats;
    MUSIC_TIME mtPlayStart;
    MUSIC_TIME mtLoopStart;
    MUSIC_TIME mtLoopEnd;
    DWORD dwResolution;
} DMUS_IO_MOTIFSETTINGS;

#include <poppack.h>

typedef enum enumDMUS_PATTERNT_TYPES {
    DMUS_PATTERNT_RANDOM = 0,
    DMUS_PATTERNT_REPEAT = 1,
    DMUS_PATTERNT_SEQUENTIAL = 2,
    DMUS_PATTERNT_RANDOM_START = 3,
    DMUS_PATTERNT_NO_REPEAT = 4,
    DMUS_PATTERNT_RANDOM_ROW = 5
} DMUS_PATTERNT_TYPES;

typedef struct _DMUS_IO_CHORD {
    WCHAR wszName[16];
    MUSIC_TIME mtTime;
    WORD wMeasure;
    BYTE bBeat;
    BYTE bFlags;
} DMUS_IO_CHORD;

typedef struct _DMUS_IO_SUBCHORD {
    DWORD dwChordPattern;
    DWORD dwScalePattern;
    DWORD dwInversionPoints;
    DWORD dwLevels;
    BYTE bChordRoot;
    BYTE bScaleRoot;
} DMUS_IO_SUBCHORD;

typedef struct _DMUS_IO_COMMAND {
    MUSIC_TIME mtTime;
    WORD wMeasure;
    BYTE bBeat;
    BYTE bCommand;
    BYTE bGrooveLevel;
    BYTE bGrooveRange;
    BYTE bRepeatMode;
} DMUS_IO_COMMAND;

typedef struct _DMUS_IO_TOOL_HEADER {
    GUID guidClassID;
    long lIndex;
    DWORD cPChannels;
    FOURCC ckid;
    FOURCC fccType;
    DWORD dwPChannels[1];
} DMUS_IO_TOOL_HEADER;

typedef struct _DMUS_IO_PORTCONFIG_HEADER {
    GUID guidPort;
    DWORD dwPChannelBase;
    DWORD dwPChannelCount;
    DWORD dwFlags;
} DMUS_IO_PORTCONFIG_HEADER;

typedef struct _DMUS_IO_PCHANNELTOBUFFER_HEADER {
    DWORD dwPChannelBase;
    DWORD dwPChannelCount;
    DWORD dwBufferCount;
    DWORD dwFlags;
} DMUS_IO_PCHANNELTOBUFFER_HEADER;

typedef struct _DMUS_IO_BUFFER_ATTRIBUTES_HEADER {
    GUID guidBufferID;
    DWORD dwFlags;
} DMUS_IO_BUFFER_ATTRIBUTES_HEADER;

typedef struct _DMUS_IO_BAND_TRACK_HEADER {
    BOOL bAutoDownload;
} DMUS_IO_BAND_TRACK_HEADER;

typedef struct _DMUS_IO_BAND_ITEM_HEADER {
    MUSIC_TIME lBandTime;
} DMUS_IO_BAND_ITEM_HEADER;

typedef struct _DMUS_IO_BAND_ITEM_HEADER2 {
    MUSIC_TIME lBandTimeLogical;
    MUSIC_TIME lBandTimePhysical;
} DMUS_IO_BAND_ITEM_HEADER2;

typedef struct _DMUS_IO_INSTRUMENT {
    DWORD dwPatch;
    DWORD dwAssignPatch;
    DWORD dwNoteRanges[4];
    DWORD dwPChannel;
    DWORD dwFlags;
    BYTE bPan;
    BYTE bVolume;
    short nTranspose;
    DWORD dwChannelPriority;
    short nPitchBendRange;
} DMUS_IO_INSTRUMENT;

typedef struct _DMUS_IO_WAVE_HEADER {
    REFERENCE_TIME rtReadAhead;
    DWORD dwFlags;
} DMUS_IO_WAVE_HEADER;

typedef struct _DMUS_IO_WAVE_TRACK_HEADER {
    long lVolume;
    DWORD dwFlags;
} DMUS_IO_WAVE_TRACK_HEADER;

typedef struct _DMUS_IO_WAVE_PART_HEADER {
    long lVolume;
    DWORD dwVariations;
    DWORD dwPChannel;
    DWORD dwLockToPart;
    DWORD dwFlags;
    DWORD dwIndex;
} DMUS_IO_WAVE_PART_HEADER;

typedef struct _DMUS_IO_WAVE_ITEM_HEADER {
    long lVolume;
    long lPitch;
    DWORD dwVariations;
    REFERENCE_TIME rtTime;
    REFERENCE_TIME rtStartOffset;
    REFERENCE_TIME rtReserved;
    REFERENCE_TIME rtDuration;
    MUSIC_TIME mtLogicalTime;
    DWORD dwLoopStart;
    DWORD dwLoopEnd;
    DWORD dwFlags;
} DMUS_IO_WAVE_ITEM_HEADER;

typedef struct _DMUS_IO_CONTAINER_HEADER {
    DWORD dwFlags;
} DMUS_IO_CONTAINER_HEADER;

typedef struct _DMUS_IO_CONTAINED_OBJECT_HEADER {
    GUID guidClassID;
    DWORD dwFlags;
    FOURCC ckid;
    FOURCC fccType;
} DMUS_IO_CONTAINED_OBJECT_HEADER;

typedef struct _DMUS_IO_SEGMENT_HEADER {
    DWORD dwRepeats;
    MUSIC_TIME mtLength;
    MUSIC_TIME mtPlayStart;
    MUSIC_TIME mtLoopStart;
    MUSIC_TIME mtLoopEnd;
    DWORD dwResolution;
    REFERENCE_TIME rtLength;
    DWORD dwFlags;
    DWORD dwReserved;
} DMUS_IO_SEGMENT_HEADER;

typedef struct _DMUS_IO_TRACK_HEADER {
    GUID guidClassID;
    DWORD dwPosition;
    DWORD dwGroup;
    FOURCC ckid;
    FOURCC fccType;
} DMUS_IO_TRACK_HEADER;

typedef struct _DMUS_IO_TRACK_EXTRAS_HEADER {
    DWORD dwFlags;
    DWORD dwPriority;
} DMUS_IO_TRACK_EXTRAS_HEADER;

typedef struct _DMUS_IO_SONG_HEADER {
    DWORD dwFlags;
    DWORD dwStartSegID;
} DMUS_IO_SONG_HEADER;

typedef struct _DMUS_IO_SEGREF_HEADER {
    DWORD dwID;
    DWORD dwSegmentID;
    DWORD dwToolGraphID;
    DWORD dwFlags;
    DWORD dwNextPlayID;
} DMUS_IO_SEGREF_HEADER;

typedef struct _DMUS_IO_TRACKREF_HEADER {
    DWORD dwSegmentID;
    DWORD dwFlags;
} DMUS_IO_TRACKREF_HEADER;

typedef struct _DMUS_IO_TRANSITION_DEF {
    DWORD dwSegmentID;
    DWORD dwTransitionID;
    DWORD dwPlayFlags;
} DMUS_IO_TRANSITION_DEF;

typedef struct _DMUS_IO_REFERENCE {
    GUID guidClassID;
    DWORD dwValidData;
} DMUS_IO_REFERENCE;

typedef struct _DMUS_IO_CHORDMAP {
    WCHAR wszLoadName[20];
    DWORD dwScalePattern;
    DWORD dwFlags;
} DMUS_IO_CHORDMAP;

typedef struct _DMUS_IO_CHORDMAP_SUBCHORD {
    DWORD dwChordPattern;
    DWORD dwScalePattern;
    DWORD dwInvertPattern;
    BYTE bChordRoot;
    BYTE bScaleRoot;
    WORD wCFlags;
    DWORD dwLevels;
} DMUS_IO_CHORDMAP_SUBCHORD;

typedef DMUS_IO_CHORDMAP_SUBCHORD DMUS_IO_PERS_SUBCHORD;

typedef struct _DMUS_IO_CHORDENTRY {
    DWORD dwFlags;
    WORD wConnectionID;
} DMUS_IO_CHORDENTRY;

typedef struct _DMUS_IO_NEXTCHORD {
    DWORD dwFlags;
    WORD nWeight;
    WORD wMinBeats;
    WORD wMaxBeats;
    WORD wConnectionID;
} DMUS_IO_NEXTCHORD;

typedef struct _DMUS_IO_CHORDMAP_SIGNPOST {
    DWORD dwChords;
    DWORD dwFlags;
} DMUS_IO_CHORDMAP_SIGNPOST;

typedef DMUS_IO_CHORDMAP_SIGNPOST DMUS_IO_PERS_SIGNPOST;

typedef struct _DMUS_IO_SCRIPT_HEADER {
    DWORD dwFlags;
} DMUS_IO_SCRIPT_HEADER;

typedef struct _DMUS_IO_SIGNPOST {
    MUSIC_TIME mtTime;
    DWORD dwChords;
    WORD wMeasure;
} DMUS_IO_SIGNPOST;

typedef struct _DMUS_IO_MUTE {
    MUSIC_TIME mtTime;
    DWORD dwPChannel;
    DWORD dwPChannelMap;
} DMUS_IO_MUTE;

typedef struct _DMUS_IO_TIMESIGNATURE_ITEM {
    MUSIC_TIME lTime;
    BYTE bBeatsPerMeasure;
    BYTE bBeat;

    WORD wGridsPerBeat;
} DMUS_IO_TIMESIGNATURE_ITEM;

typedef struct _DMUS_IO_VALID_START {
    MUSIC_TIME mtTime;
} DMUS_IO_VALID_START;

typedef struct _DMUS_IO_PLAY_MARKER {
    MUSIC_TIME mtTime;
} DMUS_IO_PLAY_MARKER;

typedef struct _DMUS_IO_SEGMENT_TRACK_HEADER {
    DWORD dwFlags;
} DMUS_IO_SEGMENT_TRACK_HEADER;

typedef struct _DMUS_IO_SEGMENT_ITEM_HEADER {
    MUSIC_TIME lTimeLogical;
    MUSIC_TIME lTimePhysical;
    DWORD dwPlayFlags;
    DWORD dwFlags;
} DMUS_IO_SEGMENT_ITEM_HEADER;

typedef struct _DMUS_IO_SCRIPTTRACK_EVENTHEADER {
    DWORD dwFlags;
    MUSIC_TIME lTimeLogical;
    MUSIC_TIME lTimePhysical;
} DMUS_IO_SCRIPTTRACK_EVENTHEADER;

typedef struct _DMUS_IO_LYRICSTRACK_EVENTHEADER {
    DWORD dwFlags;
    DWORD dwTimingFlags;
    MUSIC_TIME lTimeLogical;
    MUSIC_TIME lTimePhysical;
} DMUS_IO_LYRICSTRACK_EVENTHEADER;

typedef struct _DMUS_IO_PARAMCONTROLTRACK_OBJECTHEADER {
    DWORD dwFlags;
    GUID guidTimeFormat;
    DWORD dwPChannel;
    DWORD dwStage;
    DWORD dwBuffer;
    GUID guidObject;
    DWORD dwIndex;
} DMUS_IO_PARAMCONTROLTRACK_OBJECTHEADER;

typedef struct _DMUS_IO_PARAMCONTROLTRACK_PARAMHEADER {
    DWORD dwFlags;
    DWORD dwIndex;
} DMUS_IO_PARAMCONTROLTRACK_PARAMHEADER;

typedef struct _DMUS_IO_PARAMCONTROLTRACK_CURVEINFO {
    MUSIC_TIME mtStartTime;
    MUSIC_TIME mtEndTime;
    float fltStartValue;
    float fltEndValue;
    DWORD dwCurveType;
    DWORD dwFlags;
} DMUS_IO_PARAMCONTROLTRACK_CURVEINFO;

typedef DMUS_CONNECTION_RULE DMUS_IO_CONNECTION_RULE;

typedef DMUS_MELODY_FRAGMENT DMUS_IO_MELODY_FRAGMENT;

    typedef struct _DMUS_IO_MELFORM {
        DWORD dwPlaymode;
    } DMUS_IO_MELFORM;

#if (DIRECTSOUND_VERSION >= 0x0800)

#define DMUS_FOURCC_DSBC_FORM  mmioFOURCC('D','S','B','C')
#define DMUS_FOURCC_DSBD_CHUNK  mmioFOURCC('d','s','b','d')
#define DMUS_FOURCC_BSID_CHUNK  mmioFOURCC('b','s','i','d')
#define DMUS_FOURCC_DS3D_CHUNK  mmioFOURCC('d','s','3','d')
#define DMUS_FOURCC_DSBC_LIST  mmioFOURCC('f','x','l','s')
#define DMUS_FOURCC_DSFX_FORM  mmioFOURCC('D','S','F','X')
#define DMUS_FOURCC_DSFX_CHUNK  mmioFOURCC('f','x','h','r')
#define DMUS_FOURCC_DSFX_DATA  mmioFOURCC('d','a','t','a')

typedef struct _DSOUND_IO_DSBUFFERDESC {
    DWORD dwFlags;
    WORD nChannels;
    LONG lVolume;
    LONG lPan;
    DWORD dwReserved;
} DSOUND_IO_DSBUFFERDESC;

typedef struct _DSOUND_IO_DSBUSID {
    DWORD busid[1];
} DSOUND_IO_DSBUSID;

typedef struct _DSOUND_IO_3D {
    GUID guid3DAlgorithm;
    DS3DBUFFER ds3d;
} DSOUND_IO_3D;

typedef struct _DSOUND_IO_DXDMO_HEADER {
    DWORD dwEffectFlags;
    GUID guidDSFXClass;
    GUID guidReserved;
    GUID guidSendBuffer;
    DWORD dwReserved;
} DSOUND_IO_DXDMO_HEADER;

typedef struct _DSOUND_IO_DXDMO_DATA {
    DWORD data[1];
} DSOUND_IO_DXDMO_DATA;

#endif /* DIRECTSOUND_VERSION >= 0x0800 */

#ifdef __cplusplus
};
#endif

#include <poppack.h>

#endif /* _DMUSICF_H */
