#include "general.h"

namespace lemeditw {
	
	struct compress_header_t {
		byte_t num_bits_in_first_byte;
		byte_t checksum;
		byte_t unknown1[2];
    word_t decompressed_size;
    byte_t unknown2[2];
    word_t compressed_size;   // this size includes the 10-byte header
  };

  struct compressed_data_section_t {
    compress_header_t header;
    byte_t *data;
    size_t len;
  };

  class Decompressor {
  public:
    enum decompression_error_e {
      DECOMPRESSION_ERROR,
      CHECKSUM_MISMATCH,
    };

    Decompressor(const compress_header_t &header, const byte_t *compressed_data, byte_t *decompressed_data_buffer);
    static void decompress(const compress_header_t &header, const byte_t *compressed_data, byte_t *decompressed_data_buffer) {
      Decompressor d(header, compressed_data, decompressed_data);
      d.decompress();
    }
    void decompress();
  
  private:
	  int m_bitcnt;
    byte_t m_curbits;
    int m_ci;
    const byte *m_cdata;
    int m_dsize;
    int m_di
    byte *m_ddata;
    int m_actualchecksum;
    int m_expectedchecksum;
    
    int getnextbits(int n);
    void ref_prev_data(int len, int offset_bitwidth);
    void decode_raw_data(int len);    
  };


  class Compressor {

  public:
    typedef byte_t *(*pAllocFunc_t)(size_t numbytes);

    Compressor(byte_t *data, int len, pAllocFunc_t myalloc = &Compressor::newalloc);
    compressed_data_section_t compress();

  private:
    const byte_t *m_ddata;
    byte_t *m_ci;
    int m_len, m_bitcnt;
    pAllocFunc_t myalloc;

    struct refchunk_t {
      unsigned int dest;
      unsigned int srcoffset;
      unsigned int len;

      refchunk_t(unsigned int dest, unsigned int srcoffset, unsigned int len) : dest(dest), srcoffset(srcoffset), len(len) {}
    };  

    static byte_t *newalloc(size_t numbytes) {return new byte_t[numbytes];}

    list<refchunk_t> generate_refchunk_list();
    void optimize_refchunks(list<refchunk_t> &refchunklist);
    bool checkintegrity(list<refchunk_t> &refchunklist);

    static inline unsigned int overhead(unsigned int rawchunklen) {
      unsigned int result = 0;
      if (rawchunklen > MAXRAWCHUNKLEN) {
        result = (rawchunklen / MAXRAWCHUNKLEN) * 11;
        rawchunklen %= MAXRAWCHUNKLEN;
      }

      if (rawchunklen == 0)
        return result;
      else if (rawchunklen <= 8)
        return result + 5;
      else if (rawchunklen <= 16)
        return result + 10;
      else
        return result + 11;
    }

    static inline unsigned int addoneoverhead(unsigned int oldrlen) {
      unsigned int n = oldrlen % MAXRAWCHUNKLEN;
      if (n == 0 || n == 8)
        return 5;
      else if (n == 16)
        return 1;
      else
        return 0;
    }

    size_t calculatenumbitsneeded(const list<refchunk_t> &refchunklist);
    compressed_data_section_t generate_compress_data(const list<refchunk_t> &refchunklist, size_t numbits);

    void pushnextbits(int n, unsigned int bits);
    void generaterawchunk(int loc, unsigned int len);
    void generaterefchunk(const refchunk_t &refchunk);
  };

};