#include <stdio.h>
#include <stdlib.h>

struct header
{
     long offset;
     long size;
     int entries;
     char name[4];
};

// shorthand for read_long_be (big endian)
int rlb(FILE* f) {
    unsigned char charBuffer[4];
    fread(&charBuffer, sizeof(char), 4, f);
    return (charBuffer[3] + 0x100*charBuffer[2] + 0x10000*charBuffer[1] + 0x1000000*charBuffer[0]);
}

// shorthand for read_word_le (little endian)
int rwl(FILE* f) {
    unsigned char charBuffer[4];
    fread(&charBuffer, sizeof(char), 2, f);
    return (charBuffer[0] + 0x100*charBuffer[1]);
}

void readPalette();
void readSections();
void dumpTarga();

// depending on file format, some of these flags have to be set (note: files always have to be decompressed)
// if none of these below apply, define none of these symbols
// also take note whether to set flag RELAT (see below)
#define IFF    // ignore palette offsets and calculate them according to IFF standards
#define XMULTIPLE 16 // multiple sprites of this x size, instead of only one

#define OUTFILE "font.tga"

#define GFX_FILE "bitmaps/font.dat"
#define INIT_OFF 0

// these have to be set if the file is neither IFF not TRIBES category
#define PAL_FILE "../data/practiced.iff"
#define PAL_DIFF 0 // value to subtract from the palette entry ID, usually 0
// following two only used if IFF is not set
#define PAL_OFF 0xABDE // vstyle: 0x6C1E, tribe style files: 0x16, practice: 0xABDE
#define PAL_SIZE 0x80 // usually 0x80

#define IFF_PAL_ID 1    //only for IFF files as palette: usually value 1, in introdat subfolder value 2

// the files don't contain the palettes, so you have to choose the correct one
// below are working palettes, stated by file and IFF_PAL_ID
// fullscreen (320x200) if not otherwise stated
// you'll need to use INIT_OFF for the last 3 bitmaps of panel
//rockwall -> practice.iff (1)
//vilscene -> talis2.iff (2)
//award -> award.iff (1)
//end1-5 -> end.iff (1)
//map -> map.iff (1)
//menu -> menu.iff (1)
//cosyroom -> waking.iff (2)
//nightvil -> intro.iff (2)
//panel -> practice.iff (1), PAL_DIFF = 0x80
    // 1x32x30, 1x32x20, 59x8x8, 1x16x9, L2SS data
//pointer -> practice.iff (1), PAL_DIFF = 0x80
    // 18x16x16
//font -> practice.iff (1)
    // 102x16x11

int tga_x = 102*16;
int tga_y = 11;

    // only relevant for IFF files
    #define L2PD 4 // palette data section
    #define L2PI 5 // palette pointer section
    #define L2TM 6 // text section
    #define L2TI 7 // text pointer section

    #define MAX_SECTIONS 12

#ifdef IFF
    #define PAL_SIZE 0x100
#endif


unsigned short pal[PAL_SIZE][3];
header sectionBuffer[MAX_SECTIONS];

unsigned char* bigfattarga;

#define IDX(y, x, i) ((y)*tga_x*3 + (x)*3 + (i))

int main(int argc, char* argv) {
    readSections();

    readPalette();


    bigfattarga = (unsigned char*) malloc(3 * tga_x * tga_y);
    for (int i = 0; i < 3 * tga_x * tga_y; i++)
        bigfattarga[i] = 0; //black

    FILE* f = fopen(GFX_FILE, "rb");
    fseek(f, INIT_OFF, SEEK_SET);


    #ifndef XMULTIPLE
    for (int l = 0; l < 4; l++)
        for (int y = 0; y < tga_y; y++)
            for (int x = l; x < tga_x; x += 4) {
                unsigned char byte = fgetc(f) - PAL_DIFF;
                bigfattarga[IDX(y, x, 2)] = 4*pal[byte][0];
                bigfattarga[IDX(y, x, 1)] = 4*pal[byte][1];
                bigfattarga[IDX(y, x, 0)] = 4*pal[byte][2];
            }
    #else
    for (int c = 0; c < tga_x; c += XMULTIPLE)
        for (int l = 0; l < 4; l++)
            for (int y = 0; y < tga_y; y++)
                for (int x = l; x < XMULTIPLE; x += 4) {
                    unsigned char byte = fgetc(f) - PAL_DIFF;
                    bigfattarga[IDX(y, x + c, 2)] = 4*pal[byte][0];
                    bigfattarga[IDX(y, x + c, 1)] = 4*pal[byte][1];
                    bigfattarga[IDX(y, x + c, 0)] = 4*pal[byte][2];
                }
    #endif


    fclose(f);

    dumpTarga();

    return 0;
}

void readPalette() {
    FILE* f = fopen(PAL_FILE, "rb");

    /* store palette */
  #ifdef IFF
    //pal and gfx files are the same here, so access to section data is ok
    fseek(f, sectionBuffer[L2PI].offset + 0x0A + 2*IFF_PAL_ID, SEEK_SET);
    int pal_off2 = rwl(f);
    fseek(f, sectionBuffer[L2PD].offset + 0x0A + pal_off2 + 2*IFF_PAL_ID, SEEK_SET);
    int pal_size2 = rwl(f) / 3;
  #else
    fseek(f, PAL_OFF, SEEK_SET);
    int pal_size2 = PAL_SIZE;
  #endif

	for(int i=0; i<pal_size2; i++) {
		for(int j=0; j<3; j++) pal[i][j]=fgetc(f);
		// if(!feof(f)) SetPixel(hdc, i, 0, RGB(4*pal[i][0],4*pal[i][1],4*pal[i][2]));
	}
	fclose(f);
}

void readSections() {
    FILE* f=fopen(PAL_FILE, "rb");

  	fseek(f, 0x0c, SEEK_SET);
	int i = 0;
    while(!feof(f) && i<MAX_SECTIONS)
    {
          sectionBuffer[i].offset = ftell(f);
          fread(&(sectionBuffer[i].name), sizeof(unsigned char), 4, f);
          sectionBuffer[i].size = rlb(f);
          sectionBuffer[i].entries = rwl(f);
          fseek(f, sectionBuffer[i].size - 2, SEEK_CUR);
          i++;
    }
	fclose(f);
}

void dumpTarga() {
	FILE* tga = fopen(OUTFILE, "wb");

    putc(0,tga);
    putc(0,tga);
    putc(2,tga);                         /* uncompressed RGB */
    putc(0,tga); putc(0,tga);
    putc(0,tga); putc(0,tga);
    putc(0,tga);
    putc(0,tga); putc(0,tga);           /* X origin */
    putc(0,tga); putc(0,tga);           /* y origin */
    putc((tga_x & 0x00FF),tga);
    putc((tga_x & 0xFF00) / 256,tga);
    putc((tga_y & 0x00FF),tga);
    putc((tga_y & 0xFF00) / 256,tga);
    putc(24,tga);                        /* 24 bit bitmap */
    putc(0,tga);


    // this would be faster, but puts the image upside down
    //fwrite(bigfattarga, tga_y * tga_x * 3, 1, tga);

    for (int y = tga_y - 1; y >= 0; y--)
        for (int x = 0; x < tga_x; x++)
            for (int i = 0; i < 3; i++)
                fputc(bigfattarga[IDX(y, x, i)], tga);

    fclose(tga);
}
