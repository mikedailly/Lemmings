#include <stdio.h>
#include <algorithm>
#include <map>

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
void drawFrame(FILE* f, int offset, int index, int xBase, int yBase, int& xSize, int& ySize);
void drawStuff();
void drawRaw();
void drawVlemms();
void dumpTarga();

// depending on file format, some of these flags have to be set (note: files always have to be decompressed)
// if none of these below apply, define none of these symbols
// also take note whether to set flag RELAT (see below)
//#define IFF    // ignore palette offsets and calculate them according to IFF standards
//#define RAW  // for icons.dat and panel.dat format, use practice.iff with offset 0xABDE for the palette
            // and check to set the parameters RAW_... correctly below
//#define TRIBES    // for L2 tribes styles
#define VLEMMS  // for vlemms.dat, use a tribe for the palette

#define OUTFILE "vl_spo.tga"

#define GFX_FILE "../data/vlemms.dat" //"../styles/Medieval.dat"

// these have to be set if the file is neither IFF not TRIBES category
#define PAL_FILE_CUSTOM "../../styles/Sports.dat" // palette different from GFX file, when not IFF nor TRIBES file
#define PAL_OFF_CUSTOM 0x16 // vstyle: 0x6C1E, tribe style files: 0x16, practice: 0xABDE
#define PAL_SIZE_CUSTOM 0x80 // usually 0x80

#define IFF_PAL_ID 1    //only for IFF files: usually value 1, in introdat subfolder value 2

//#define RELAT   // flag for taking relative offsets in l2ss and shifting l2sf offsets by 4
                  // used by IFFs (automatically set) and vstyle (still has to be set in this case)

#ifdef IFF

  #ifndef RELAT
    #define RELAT
  #endif

    #define PAL_FILE GFX_FILE
    #define PAL_SIZE 0x100

    // only relevant for IFF files
    #define L2PD 4 // palette data section
    #define L2PI 5 // palette pointer section
    #define L2TM 6 // text section
    #define L2TI 7 // text pointer section

#else // not IFF

  #ifdef TRIBES
    #define PAL_FILE GFX_FILE
    #define PAL_OFF 0x16
    #define PAL_SIZE 0x80
  #else // not tribes
    #define PAL_FILE PAL_FILE_CUSTOM
    #define PAL_OFF PAL_OFF_CUSTOM
    #define PAL_SIZE PAL_SIZE_CUSTOM
  #endif

#endif

#ifdef TRIBES
    #define L2SS 1
    #define L2SF 2
    #define L2SA 3
    #define L2SI 4
#else // anything else
    #define L2SS 0
    #define L2SF 1
    #define L2SA 2
    #define L2SI 3
#endif

#ifdef VLEMMS
    #define MAX_SECTIONS 0x7A
#else
    #define MAX_SECTIONS 12
#endif

#ifdef RAW
    #define PAL_DIFF 0x80
#else
    #define PAL_DIFF 0
#endif

    #define RAW_X 32
    #define RAW_Y 32
    #define RAW_OFF 0x1590 // 0 for icons.dat, 0x1590 for panel.dat
    #define RAW_AMOUNT 0x1A // 0x36 for icons.dat, 0x1A for panel.dat



unsigned short pal[PAL_SIZE][3];
header sectionBuffer[MAX_SECTIONS];
// maps an l2sf pseudo offset to an index in l2ss
std::map<int, int> l2ssOffsets;

int tga_x, tga_y;
unsigned char* bigfattarga;

bool getSizeOnly;

#define IDX(y, x, i) ((y)*tga_x*3 + (x)*3 + (i))

int main(int argc, char* argv) {
          l2ssOffsets.clear();

          #ifndef RAW
            readSections();
          #endif

            readPalette();

            getSizeOnly = true;

          #ifdef RAW
            drawRaw();
          #elif defined VLEMMS
            drawVlemms();
          #else
            drawStuff();
          #endif

            bigfattarga = (unsigned char*) malloc(3 * tga_x * tga_y);
            for (int i = 0; i < 3 * tga_x * tga_y; i++)
                bigfattarga[i] = 0; //black

            getSizeOnly = false;

          #ifdef RAW
            drawRaw();
          #elif defined VLEMMS
            drawVlemms();
          #else
            drawStuff();
          #endif

            dumpTarga();

    return 0;
}

void drawRaw() {
    FILE* f=fopen(GFX_FILE, "rb");

    int xPos=0, yPos=0;
    int xSize=0, ySize=0;  //get pseudo values

    for (int i = 0; i < RAW_AMOUNT; i++) {
        fseek(f, RAW_OFF + 2*i, SEEK_SET);
        int offset = rwl(f);

        drawFrame(f, RAW_OFF + offset, 0, xPos, yPos, xSize, ySize);

        xPos += xSize + 1;
    }

    tga_x = xPos;
    tga_y = ySize;

    fclose(f);
}

void drawVlemms() {
    FILE* f=fopen(GFX_FILE, "rb");

    int yMax;

    int xPos=0, yPos=0;
    int xSize=0, ySize=0;

    for (int anim = 0; anim < MAX_SECTIONS; anim++) {
        int frames = sectionBuffer[anim].entries;
        yMax = 0;
        xPos = 0;

        for (int frame = 0; frame < frames; frame++) {
            drawFrame(f, sectionBuffer[anim].offset, frame, xPos, yPos, xSize, ySize);

            yMax = std::max(yMax, ySize);
            xPos += xSize + 1;
        }
        yPos += yMax + 1;
        tga_x = std::max(tga_x, xPos);
    }

    tga_y = yPos;

    fclose(f);
}

void drawStuff() {
    int xPos=0, yPos=0, yMax=0;
    int xSize=0, ySize=0;

    int index, currOff;

    int off_ss=0, off_sf=0, off_sa=0;

    FILE* f=fopen(GFX_FILE, "rb");

    off_ss = sectionBuffer[L2SS].offset + 0x0A;
    off_sf = sectionBuffer[L2SF].offset + 0x0A;
    off_sa = sectionBuffer[L2SA].offset + 0x0A;

    currOff = 0;
    index = 0;
    fseek(f, off_ss, SEEK_SET);
    for (int e = 0; e < sectionBuffer[L2SS].entries; e++) {
        int size = rwl(f);
        l2ssOffsets[currOff] = index;
        currOff += size;
        fseek(f, size, SEEK_CUR);
        index++;
    }

    yPos=1;
    index = 0;

    for (int anim = 0; anim < sectionBuffer[L2SA].entries; anim++) { //sectionBuffer[L2SA].entries
        xPos = 0;
        yMax = 0;

        fseek(f, off_sa, SEEK_SET);
        int frames = rwl(f);
        off_sa += 2;

        for(int frame = 0; frame < frames; frame++)
        {
            fseek(f, off_sa, SEEK_SET);
            int off_frame = rwl(f);
            off_sa += 2;

            fseek(f, sectionBuffer[L2SF].offset + 0x0a + off_frame, SEEK_SET);
            int xOff = rwl(f);
            int yOff = rwl(f);
            int ByteOff = rwl(f);
          #ifdef RELAT
            ByteOff <<= 4;
          #endif
            off_sf += 6;

            drawFrame(f, ByteOff, l2ssOffsets[ByteOff], xPos + xOff, yPos + yOff, xSize, ySize);
            xPos += xSize + xOff + 1;
            yMax = std::max(yMax, yOff + ySize);

            index++;
        }
        yPos += yMax + 1;
        tga_x = std::max(tga_x, xPos);
    }

    tga_y = yPos;

    fclose(f);
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
    FILE* f=fopen(GFX_FILE, "rb");

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

void drawFrame(FILE* f, int offset, int index, int xBase, int yBase, int& xSize, int& ySize) {
  #ifdef RAW
    fseek(f, offset, SEEK_SET);
  #elif defined VLEMMS
    fseek(f, offset + 0x0a + 2*index, SEEK_SET);
    int suboff = rwl(f);
    fseek(f, offset + 0x08 + suboff, SEEK_SET);
  #else
    fseek(f, sectionBuffer[L2SS].offset + 0x0c + 2*(index-1) + offset, SEEK_SET);
  #endif

    int pointerList[4];
    int xPos = xBase, yPos = yBase;
    int xPosAdd = 0;

  #ifdef VLEMMS
    int xOff = rwl(f);
    int yOff = rwl(f);
  #endif

  #ifndef RAW
    rwl(f);
  #endif

    xSize = rwl(f);
    ySize = rwl(f);

  #ifdef RAW
    // give pseudo values
    xSize = RAW_X;
    ySize = RAW_Y;
  #endif

  #ifdef VLEMMS
    xSize += xOff;
    ySize += yOff;
    xBase += xOff;
    yBase += yOff;
  #endif

    if (getSizeOnly) return;

	for(int i=0; i<4; i++)
        pointerList[i] = rwl(f);

    for(int i=0; i<4; i++) {
      #ifdef RELAT
        fseek(f, sectionBuffer[L2SS].offset + 0x0c + 2*(index) + offset + pointerList[i], SEEK_SET);
      #elif defined RAW
        fseek(f, RAW_OFF + pointerList[i], SEEK_SET);
      #elif defined VLEMMS
        fseek(f, offset + 0x08 + pointerList[i], SEEK_SET);
      #else
        fseek(f, sectionBuffer[L2SS].offset + 0x0c + 2*(index) + pointerList[i], SEEK_SET);
      #endif
        xPos = xBase + i;
        unsigned char byte=0;
        int n = 0, m = 0, l = 0;
        bool reminderm = false, reminderl = false, reminderl2 = false;
        yPos = yBase;
        while(byte != 0xFF)
        {
            byte=fgetc(f);
            if(n || m || l)
            {
                byte -= PAL_DIFF;
                //SetPixel(hdc, xPos, yPos, RGB(4*pal[byte][0],4*pal[byte][1],4*pal[byte][2]));
                bigfattarga[IDX(yPos, xPos, 2)] = 4*pal[byte][0];
                bigfattarga[IDX(yPos, xPos, 1)] = 4*pal[byte][1];
                bigfattarga[IDX(yPos, xPos, 0)] = 4*pal[byte][2];
                xPos += 4;
                if(n)
                {
                    n--;
                    if(!n)
                    {
                        yPos++;
                        xPos = xBase + i;
                    }
                }
                if(m) m--;
                if(!m && reminderm)
                {
                    xPos += 4*xPosAdd;
                    reminderm = false;
                    xPosAdd = 0;
                }
                if(l) l--;
                if(!l && reminderl)
                {
                    if(reminderl2)
                    {
                        xPos += 4*xPosAdd;
                        xPosAdd = 0;
                    }
                    else
                    {
                        yPos++;
                        xPos = xBase + i;
                    }
                    reminderl = false;
                    reminderl2 = false;
                }
            }
            else
            {
                if(byte==0x00)
                {
                    yPos++;
                    xPos = xBase + i;
                }
                else if(byte>0x7F)
                {
                    if(((byte & 0x0F) > 0x07) && ((byte & 0xF0) == 0xE0))
                    {
                        xPos += 4*(byte & 0x0F) - 8;
                    }
                    else
                    {
                        l = (byte & 0x0F);
                        xPos += 4*((byte & 0xF0)/0x10 - 0x08);
                    }
                }
                else
                {
                    if(!(byte & 0x0F)) n = (byte & 0xF0)/0x10;
                    else if((byte & 0x0F) < 0x08) m = ((byte & 0x0F) + (byte & 0xF0)/0x10);
                    else
                    {
                        m = ((byte & 0xF0)/0x10);
                        xPosAdd += (byte & 0x0F) - 0x08;
                        reminderm = true;
                    }
                }
            }
        }
    }
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
