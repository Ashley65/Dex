#pragma pack(push, 1)

#include <stdint.h>

struct bpbType {
    uint8_t BS_jmpBoot[3];
    unsigned char BS_OEMName[8];
    uint16_t BPB_BytsPerSec;
    uint8_t BPB_SecPerClus;
    uint16_t BPB_RsvdSecCnt;

    uint8_t BPB_NumFATs;
    uint16_t BPB_RootEntCnt;
    uint16_t BPB_TotSec16;
    uint8_t BPB_Media;
    uint16_t BPB_FATSz16;

    uint16_t BPB_SecPerTrk;
    uint16_t BPB_NumHeads;
    uint32_t BPB_HiddSec;
    uint32_t BPB_TotSec32;
};

struct dirEntryType {
    unsigned char DIR_Name[11];
    uint8_t DIR_Attr;
    uint8_t DIR_NTRes;
    uint8_t DIR_CrtTimeTenth;

    uint16_t DIR_CrtTime;
    uint16_t DIR_CrtDate;
    uint16_t DIR_LstAccDate;
    uint16_t DIR_FstClusHI;

    uint16_t DIR_WrtTime;
    uint16_t DIR_WrtDate;
    uint16_t DIR_FstClusLO;
    uint32_t DIR_FileSize;
};
#pragma pack(pop)

enum dirarrType {
    DIR_ATTR_READONLY = 1 << 0,
    DIR_ATTR_HIDDEN   = 1 << 1,
    DIR_ATTR_SYSTEM   = 1 << 2,
    DIR_ATTR_VOLUMEID = 1 << 3,
    DIR_ATTR_DIRECTORY= 1 << 4,
    DIR_ATTR_ARCHIVE  = 1 << 5,
    DIR_ATTR_LFN      = 0xF

};