#include "stdio.h"
#include "stdint.h"
#include "stdlib.h"
#include "string.h"
#include "ctype.h"


typedef uint8_t bool;
#define true 1
#define false 0

typedef struct
{
    unsigned char BS_jmpBoot[3];
    unsigned char BS_OEMName[8];
    unsigned short BPB_BytsPerSec;
    unsigned char BPB_SecPerClus;
    unsigned short BPB_RsvdSecCnt;
    unsigned char BPB_NumFATs;
    unsigned short BPB_RootEntCnt;
    unsigned short BPB_TotSec16;
    unsigned char BPB_Media;
    unsigned short BPB_FATSz16;
    unsigned short BPB_SecPerTrk;
    unsigned short BPB_NumHeads;
    unsigned int BPB_HiddSec;
    unsigned int BPB_TotSec32;
    unsigned int BPB_FATSz32;
    unsigned short BPB_ExtFlags;
    unsigned short BPB_FSVer;
    unsigned int BPB_RootClus;
    unsigned short BPB_FSInfo;
    unsigned short BPB_BkBootSec;
    unsigned char BPB_Reserved[12];
    unsigned char BS_DrvNum;
    unsigned char BS_Reserved1;
    unsigned char BS_BootSig;
    unsigned int BS_VolID;
    unsigned char BS_VolLab[11];
    unsigned char BS_FilSysType[8];

}__attribute__((packed)) FAT32BootSector;

typedef struct
{
    unsigned char DIR_Name[11];
    unsigned char DIR_Attr;
    unsigned char DIR_Res;
    unsigned char DIR_CrtTimeTenth;
    unsigned short DIR_CrtTime;
    unsigned short DIR_CrtDate;
    unsigned short DIR_LstAccDate;
    unsigned short DIR_FstClusHI;
    unsigned short DIR_WrtTime;
    unsigned short DIR_WrtDate;
    unsigned short DIR_FstClusLO;
    unsigned int DIR_FileSize;
}__attribute__((packed)) FAT32DirectoryEntry;


FAT32BootSector  g_FAT32BootSector;
FAT32BootSector *bs = NULL;
unsigned char* rFat = NULL;
unsigned char* dataRegion = NULL;



// typedef struct
bool readBootSector(FILE* fp, FAT32BootSector* bs){

    return ;
}

bool readSector(FILE* fp, FAT32BootSector* bs, unsigned int sectorNum, unsigned char* buffer){
    bool ok = true;
    ok = ok && (fseek(fp, sectorNum * bs->BPB_BytsPerSec, SEEK_SET) == 0);
    ok = ok && (fread(buffer, bs->BPB_BytsPerSec, 1, fp) == 1);

    return ok;
}

bool readFat(FILE* fp){
    rFat = (unsigned char*) malloc(bs->BPB_FATSz32 * bs->BPB_BytsPerSec);
}



int main(int argc, char** argv){

    if (argc <3) {
        printf("Usage: %s <filename>\n", argv[0]);
        return -1;
    }

    FILE* fp = fopen(argv[1], "r"); // open file in read mode
    if (fp == NULL){
        fprintf(stderr, "Error: Could not open file %s\n", argv[1]);
        return -1; // return -1 if error
    }

    if (!readBootSector(fp, NULL)){
        fprintf(stderr, "Error: Could not read boot sector\n");
        return -2;
    }





    return 0;
}