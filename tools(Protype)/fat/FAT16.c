#include "stdio.h"
#include "stdint.h"
#include "stdbool.h"
#include "stdlib.h"
#include "string.h"

#include "structs.h"

//Bios Parameter Block functions
//First root sector is = BPB_RsvdSecCnt + (BPB_NumFATs * BPB_FATSz16)
//root directory sectors = (BPB_RootEntCnt * 32) / BPB_BytsPerSec(512)
//First data sector = First root sector + root directory sectors
//cluster count = (BPB_TotSec32 - First data sector) / BPB_SecPerClus

uint32_t BPB_FAT_addr(struct bpbType *bpb) {
    return bpb->BPB_RsvdSecCnt * bpb->BPB_BytsPerSec;
}

uint32_t BPB_Root_addr(struct bpbType *bpb) {
    return BPB_FAT_addr(bpb) + bpb->BPB_NumFATs * bpb->BPB_FATSz16 * bpb->BPB_BytsPerSec;
}

uint32_t BPB_Data_addr(struct bpbType *bpb) {
    return BPB_Root_addr(bpb) + bpb->BPB_RootEntCnt * 32;
}
uint32_t BPB_Cluster_addr(struct bpbType *bpb, uint32_t cluster){
    return ((cluster - 2) * bpb->BPB_SecPerClus * bpb->BPB_BytsPerSec) + BPB_Data_addr(bpb);

}

//Read functions
bool readBytes(FILE *fp, uint32_t offset, uint32_t size, void *buffer){
    if (fseek(fp, offset, SEEK_SET) != 0) {
        return false;
    }
    if (fread(buffer, size, 1, fp) != 1) {
        return false;
    }
    return true;
}

bool readBPB(FILE *fp, struct bpbType *bpb) {
    return readBytes(fp, 0, sizeof(struct bpbType), bpb);
}

bool readDirEntry(FILE *fp, uint32_t offset, struct dirEntryType *dirEntry) {
    return readBytes(fp, offset, sizeof(struct dirEntryType), dirEntry);
}

bool readCluster(FILE *fp, struct bpbType *bpb, uint32_t cluster, void *buffer) {
    return readBytes(fp, BPB_Cluster_addr(bpb, cluster), bpb->BPB_SecPerClus * bpb->BPB_BytsPerSec, buffer);
}

#define LEN_BOOT 446
#define LEN_PARTITION 16
#define NUM_PARTITIONS 4
#define BEGIN_LBA 8
#define SIZE_LBA 4
#define STG 0xAA55


bool checkSig(FILE *fp){
    uint16_t sig;
    if (!readBytes(fp, LEN_BOOT + LEN_PARTITION * NUM_PARTITIONS, sizeof(uint16_t), &sig)) {
        return false;
    }
    return sig == STG;
}

uint16_t getNextCLus(FILE *fp, struct bpbType *bpb, uint16_t cluster){
    uint32_t FAT_addr = BPB_FAT_addr(bpb);
    uint32_t FAT_offset = cluster * 2;
    uint16_t nextCluster;
    if (!readBytes(fp, FAT_addr + FAT_offset, sizeof(uint16_t), &nextCluster)) {
        return 0;
    }
    return nextCluster;
}

#define MIN(a, b) ((a) < (b) ? (a) : (b))
//
void printClus(FILE *fp, struct bpbType *bpb, struct dirEntryTpye *dirEntry){
    const uint32_t clusterSize = bpb->BPB_SecPerClus * bpb->BPB_BytsPerSec;
    struct dirEntryType *dir = dirEntry;

    for (uint16_t i = dir->DIR_FstClusLO; i != 0xFFFF; i = getNextCLus(fp, bpb, i)) {
        char buffer[clusterSize];
        readBytes(fp, BPB_Cluster_addr(bpb, i), clusterSize, buffer);

        printf("%.*s", MIN(dir->DIR_FileSize, clusterSize), buffer);
    }
}

int main(int argc, char *argv[]){

    char *filename = argc < 2 ? "fat32.im" : argv[1];

    FILE *fp = fopen(filename, "r");

    if (fp == NULL) {
        fprintf(stderr, "Error: Could not open file %s\n", filename);
        return 1;
    }
    if (!checkSig(fp)) {
        fprintf(stderr, "Error: Invalid boot sector signature\n");
        return 1;
    }

    struct bpbType bpb;
    readBytes(fp, 0x0, sizeof(struct bpbType), &bpb);

    if (bpb.BPB_BytsPerSec != 512 || bpb.BPB_NumFATs != 2) {
        fprintf(stderr, "Error: Bytes per sector is not 512\n");
        return 1;
    }

    for (int i = 0; i < bpb.BPB_RootEntCnt; i++){
        struct dirEntryType dir;
        uint32_t offset = BPB_Root_addr(&bpb) + i *32;
        readBytes(fp, offset, sizeof(dir) , &dir);
        if (dir.DIR_Name[0] == 0x00) {
            break;
        }
        else if (dir.DIR_Name[0] == 0xE5) {
            printf("Deleted file: %.*s\n", 11, dir.DIR_Name);
            continue;
        }
        else if (dir.DIR_Attr == 0x0F) {
            printf("LFN entry: %.*s\n", 11, dir.DIR_Name);
            continue;
        }
        else if (dir.DIR_Attr == 0x08) {
            printf("Volume ID: %.*s\n", 11, dir.DIR_Name);
            continue;
        }
        else if (dir.DIR_Attr == 0x10) {
            printf("Directory: %.*s\n", 11, dir.DIR_Name);
        }
        else {
            printf("File: %.*s\n", 11, dir.DIR_Name);
            printClus(fp, &bpb, &dir);
        }

        if (dir.DIR_Attr & DIR_ATTR_LFN){
            printf("LFN entry: %.*s\n", 11, dir.DIR_Name);
        }
        else if (dir.DIR_Attr & DIR_ATTR_VOLUMEID){
            printf("Volume ID: %.*s\n", 11, dir.DIR_Name);
        }
        else if (dir.DIR_Attr & DIR_ATTR_DIRECTORY){
            printf("Directory: %.*s\n", 11, dir.DIR_Name);
        }

        else {
            printf("File: %.*s\n", 11, dir.DIR_Name);
            printClus(fp, &bpb, &dir);
        }


    }
    fclose(fp);
    return 0;
}


