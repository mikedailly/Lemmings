#include "general.h"
#include "compression.h"

namespace lemeditw {

  // Decompressor methods

  Decompressor::Decompressor(const compress_header_t &header, const byte_t *compressed_data, byte_t *decompressed_data_buffer) {
    m_bitcnt = header.num_bits_in_first_byte + 1;
    m_expectedchecksum = header.checksum;
    
    m_ci = header.compressed_size - 10 - 1;
    m_dsize = m_di = header.decompressed_size;
    m_cdata = compressed_data;
    m_ddata = decompressed_data_buffer;
  }

  void Decompressor::decompress() {
    if (m_ci < 0) {
      throw DECOMPRESSION_ERROR;
    }

    m_actualchecksum = m_curbits = m_cdata[m_ci];

    do {
      if (getnextbits(1) == 1) {
        switch (getnextbits(2)) {
          case 0:
            ref_prev_data(3, 9);
            break;
          case 1:
            ref_prev_data(4, 10);
            break;
          case 2:
            ref_prev_data(getnextbits(8) + 1, 12);
            break;
          case 3:
            decode_raw_data(getnextbits(8) + 9);
            break;
        }
      }
      else {
        switch (getnextbits(1)) {
          case 0:
            decode_raw_data(getnextbits(3) + 1);
            break;
          case 1:
            ref_prev_data(2, 8);
            break;
        }
      }
    } while (m_di > 0);

    m_ci = -1;
    if (m_actualchecksum != m_expectedchecksum) {
      throw CHECKSUM_MISMATCH;
    }
  }
  
  int Decompressor::getnextbits(int n) {
    int result = 0;
    do {
      if (--m_bitcnt == 0) {
        m_ci--;
        if (m_ci < 0) {
          m_ci = 0;
          throw DECOMPRESSION_ERROR;
        }
        m_curbits = m_cdata[m_ci];
        m_actualchecksum ^= m_curbits;
        m_bitcnt = 8;
      }
      result &= 0x07fffU;
      result <<= 1;
      result |= (m_curbits & 1);
      m_curbits >>= 1;
    } while(--n > 0);
    return result;
  }

  void Decompressor::ref_prev_data(int len, int offset_bitwidth) {
    int offset = getnextbits(offset_bitwidth) + 1;

    if (m_di - 1 + offset < m_dsize && m_di - len >= 0) {
      while (len > 0) {
        m_di--;
        m_ddata[m_di] = m_ddata[m_di + offset];
        len--;
      }
    }
    else {
      throw DECOMPRESSION_ERROR;
    }
  }

  void Decompressor::decode_raw_data(int len) {
    if (m_di - len < 0) {
      throw DECOMPRESSION_ERROR;
    }
    else {
      while(len > 0) {
        m_di--;
        m_ddata[m_di] = (byte_t)getnextbits(8);
        len--;
      }
    }
  }

  // Compressor methods

  Compressor::Compressor(byte_t *data, int len, Compressor::pAllocFunc_t myalloc) {
    m_len = len;
    m_ddata = data;
    alloc = myalloc;
  }

  compressed_data_section_t Compressor::compress() {
    list<refchunk_t> refchunklist = generate_refchunk_list();
    optimize_refchunks(refchunklist);
    return generate_compress_data(refchunklist, calculatenumbitsneeded(refchunklist));
  }

  list<Compressor::refchunk_t> Compressor::generate_refchunk_list() {
    unsigned int *closestoccurrencetable = new unsigned int[65536];
    memset(closestoccurrencetable, 0, sizeof(closestoccurrencetable[0]) * 65536);

    byte_t prevbyte = m_ddata[m_len - 1];
    unsigned int i = m_len - 1;
    bool overlap = false;

    list<refchunk_t> refchunklist;
    list<refchunk_t>::iterator lastrefchunk = refchunklist.end();    

    while (i > 0) {
      byte_t curbyte = m_ddata[i - 1];
      word_t curword = (prevbyte << 8) | curbyte;
      int prevoccurrence = closestoccurrencetable[curword];
      closestoccurrencetable[curword] = i;
      if (prevoccurrence - i > MAX_OFFSET) {
        prevoccurrence = 0;
      }

      if (prevoccurrence != 0) {
        if (!overlap) {
          refchunk_t newchunk(i, prevoccurrence - i, 2);
          lastrefchunk = refchunklist.insert(refchunklist.end(), newchunk);
          overlap = true;
        }
        else if (lastrefchunk->srcoffset == prevoccurrence - i) {
          lastrefchunk->len++;
          overlap = true;
        }
        else {
          overlap = false;
        }
      }
      else {
        overlap = false;
      }

      i--;
      prevbyte = curbyte;
    }

    delete[] closestoccurrencetable;
    return refchunklist;
  }

  bool Compressor::checkintegrity(list<Compressor::refchunk_t> &refchunklist) {
    list<refchunk_t>::const_iterator currefchunk = refchunklist.begin();
    while (currefchunk != refchunklist.end()) {
        if (currefchunk->len < 2) {
            return false;
        }

        if (currefchunk->dest + currefchunk->srcoffset >= m_len) {
            return false;
        }
        for(int i = 0; i < currefchunk->len; i++) {
            if (m_ddata[currefchunk->dest - i] != m_ddata[currefchunk->dest - i + currefchunk->srcoffset])
                return false;
        }
        ++currefchunk;
    }
    return true;
  }

  void Compressor::optimize_refchunks(list<Compressor::refchunk_t> &refchunklist) {
    int prev_refchunk_end = m_len - 1;
    list<refchunk_t>::iterator nextrefchunk = refchunklist.begin();
    while (nextrefchunk != refchunklist.end()) {
      list<refchunk_t>::iterator currefchunk = nextrefchunk;
      ++nextrefchunk;
      int cur_refchunk_end = currefchunk->dest - currefchunk->len;
      int nextrawchunk_end = (nextrefchunk != refchunklist.end() ? nextrefchunk->dest : -1);
      unsigned int clen = currefchunk->len;
      

      if (clen < 5) {
        int prevrlen = (prev_refchunk_end - currefchunk->dest) % MAXRAWCHUNKLEN;
        int nextrlen = (cur_refchunk_end -  nextrawchunk_end) % MAXRAWCHUNKLEN;

        switch (clen) {
          case 2:
            if (currefchunk->srcoffset > LEN2MAXOFFSET || 
                overhead(prevrlen + nextrlen + 2) < overhead(prevrlen) + overhead(nextrlen) - (8*2 - 10)) {
              refchunklist.erase(currefchunk);
              cur_refchunk_end = prev_refchunk_end;
            }
            break;
          case 3:
            if (currefchunk->srcoffset > LEN3MAXOFFSET &&
                overhead(prevrlen + nextrlen + 3) < overhead(prevrlen) + overhead(nextrlen) - (8*3 - 23)) {
              refchunklist.erase(currefchunk);
              cur_refchunk_end = prev_refchunk_end;
            }
            break;
          case 4:
            if (currefchunk->srcoffset > LEN4MAXOFFSET &&
                overhead(prevrlen + nextrlen + 4) < overhead(prevrlen) + overhead(nextrlen) - (8*4 - 23)) {
              refchunklist.erase(currefchunk);
              cur_refchunk_end = prev_refchunk_end;
            }
            break;
        }
      }
      else if (clen > MAXREFCHUNKLEN) {
        clen %= MAXREFCHUNKLEN;
        if (clen == 1) {
          
          int maxaddoneoverhead, leftover_len;

          if (currefchunk->srcoffset <= LEN2MAXOFFSET) {
            maxaddoneoverhead = (10 - 8); leftover_len = 2;
          }
          else if (currefchunk->srcoffset <= LEN3MAXOFFSET) {
            maxaddoneoverhead = (12 - 8); leftover_len = 3;
          }
          else if (currefchunk->srcoffset <= LEN4MAXOFFSET) {
            maxaddoneoverhead = (13 - 8); leftover_len = 4;
          }
          else {
            maxaddoneoverhead = (23 - 8); leftover_len = 5;
          }

          unsigned int addtoprev_overhead = addoneoverhead(prev_refchunk_end - currefchunk->dest);
          unsigned int addtonext_overhead = addoneoverhead(cur_refchunk_end -  nextrawchunk_end);
          
          if (addtoprev_overhead < maxaddoneoverhead && addtoprev_overhead <= addtonext_overhead) {
            currefchunk->len--;
            currefchunk->dest--;
          }
          else if (addtonext_overhead < maxaddoneoverhead && addtonext_overhead < addtoprev_overhead) {
            currefchunk->len--;
            cur_refchunk_end++;
          }
          else {
            currefchunk->len -= leftover_len;
            refchunk_t newchunk(cur_refchunk_end + leftover_len, currefchunk->srcoffset, leftover_len);
            refchunklist.insert(nextrefchunk, newchunk);
          }
        }
        else if (clen == 2 && currefchunk->srcoffset > LEN2MAXOFFSET) {
          if (currefchunk->srcoffset <= LEN3MAXOFFSET) {
            currefchunk->len -= 3;
            refchunk_t newchunk(cur_refchunk_end + 3, currefchunk->srcoffset, 3);
            refchunklist.insert(nextrefchunk, newchunk);
          }
          else if (currefchunk->srcoffset <= LEN4MAXOFFSET) {
            currefchunk->len -= 4;
            refchunk_t newchunk(cur_refchunk_end + 4, currefchunk->srcoffset, 4);
            refchunklist.insert(nextrefchunk, newchunk);
          }
          else {
            currefchunk->len -= 2;
            int prevrlen = prev_refchunk_end - currefchunk->dest;
            int nextrlen = cur_refchunk_end - nextrawchunk_end;
            unsigned int addprevprev_overhead = addoneoverhead(prevrlen) + addoneoverhead(prevrlen + 1);
            unsigned int addprevnext_overhead = addoneoverhead(prevrlen) + addoneoverhead(nextrlen);
            unsigned int addnextnext_overhead = addoneoverhead(nextrlen) + addoneoverhead(nextrlen + 1);
            if (addprevprev_overhead <= addprevnext_overhead && addprevprev_overhead <= addnextnext_overhead) {
              currefchunk->dest -= 2;
            }
            else if (addprevnext_overhead < addprevprev_overhead && addprevnext_overhead <= addnextnext_overhead) {
              currefchunk->dest--;
              cur_refchunk_end++;
            }
            else {
              cur_refchunk_end += 2;
            }
          }
        }
      }
      prev_refchunk_end = cur_refchunk_end;
    }
  }

  size_t Compressor::calculatenumbitsneeded(const list<Compressor::refchunk_t> &refchunklist) {
    size_t numbits = 0;
    int prev_refchunk_end = m_len - 1;
    list<refchunk_t>::const_iterator currefchunk = refchunklist.begin();
    while (currefchunk != refchunklist.end()) {
      unsigned int prevrlen = prev_refchunk_end - currefchunk->dest;
      numbits += (overhead(prevrlen) + prevrlen * 8);

      numbits += (currefchunk->len / MAXREFCHUNKLEN) * 23;
      switch (currefchunk->len % MAXREFCHUNKLEN) {
        case 2:
          if (currefchunk->srcoffset <= LEN2MAXOFFSET)
            numbits += 10;
          else
            numbits += 23;
          break;
        case 3:
          if (currefchunk->srcoffset <= LEN3MAXOFFSET)
            numbits += 12;
          else
            numbits += 23;
          break;
        case 4:
          if (currefchunk->srcoffset <= LEN4MAXOFFSET)
            numbits += 13;
          else
            numbits += 23;
          break;
        default:
          numbits += 23;
      }
      prev_refchunk_end = currefchunk->dest - currefchunk->len;
      ++currefchunk;
    }

    unsigned int prevrlen = prev_refchunk_end + 1;
    numbits += (overhead(prevrlen) + prevrlen * 8);
    return numbits;
  }

  compressed_data_section_t Compressor::generate_compress_data(const list<Compressor::refchunk_t> &refchunklist, size_t numbits) {
    compressed_data_section_t cds;
    size_t numbytes = (numbits + 7) / 8;

    if ((cds.data = m_ci = alloc(numbytes)) != NULL) {
      cds.header.num_bits_in_first_byte = numbits % 8;
      if (cds.header.num_bits_in_first_byte == 0)
        cds.header.num_bits_in_first_byte = 8;
      cds.header.unknown1[0] = cds.header.unknown1[1] = cds.header.unknown2[0] = cds.header.unknown2[1] = 0;
      cds.header.decompressed_size = (word_t)m_len;
      cds.header.compressed_size = (word_t)(numbytes + 10);
      cds.len = numbytes;

      m_bitcnt = 8;

      int prev_refchunk_end = 0;
      list<refchunk_t>::const_iterator currefchunk = refchunklist.end();
      while (--currefchunk != refchunklist.end()) {
        generaterawchunk(prev_refchunk_end, currefchunk->dest + 1 - currefchunk->len - prev_refchunk_end);
        generaterefchunk(*currefchunk);
        prev_refchunk_end = currefchunk->dest + 1;
      }
      generaterawchunk(prev_refchunk_end, m_len - prev_refchunk_end);

      cds.header.checksum = 0;
      for(byte_t *cdata = cds.data, *ci = cdata; ci < cdata + numbytes; cds.header.checksum ^= *ci, ci++)
        ;
    }

    return cds;
  }

  void Compressor::pushnextbits(int n, unsigned int bits) {
    do {
      if (m_bitcnt == 0) {
        ++m_ci;
        m_bitcnt = 8;
      }

      *m_ci <<= 1;
      *m_ci |= (bits & 1);
      bits >>= 1;
      m_bitcnt--;
    } while(--n > 0);
  }

  void Compressor::generaterawchunk(int loc, unsigned int len) {
    if (len == 0)
      return;

    const byte_t *di = m_ddata + loc;
    while (len > MAXRAWCHUNKLEN) {
      len -= MAXRAWCHUNKLEN;
      for(int i = 0; i < MAXRAWCHUNKLEN; i++, di++)
        pushnextbits(8, *di);
      pushnextbits(11, (7 << 8) | 255);
    }

    if (len > 16) {
      for(int i = 0; i < len; i++, di++)
        pushnextbits(8, *di);
      pushnextbits(11, (7 << 8) | (len - 9));
    }
    else {
      if (len > 8) {
        len -= 8;
        for(int i = 0; i < 8; i++, di++)
          pushnextbits(8, *di);
        pushnextbits(5, (0 << 3) | 7);
      }

      for(int i = 0; i < len; i++, di++)
        pushnextbits(8, *di);
      pushnextbits(5, (0 << 3) | (len - 1));
    }
  }

  void Compressor::generaterefchunk(const Compressor::refchunk_t &refchunk) {
    unsigned int len = refchunk.len, srcoffset = refchunk.srcoffset - 1;
    while (len > MAXREFCHUNKLEN) {
      len -= MAXREFCHUNKLEN;
      pushnextbits(23, (6 << 20) | (255 << 12) | srcoffset);
    }

    switch (len) {
      case 2:
        if (srcoffset < LEN2MAXOFFSET) {
          pushnextbits(10, (1 << 8) | srcoffset);
          return;
        }
        break;
      case 3:
        if (srcoffset < LEN3MAXOFFSET) {
          pushnextbits(12, (4 << 9) | srcoffset);
          return;
        }
        break;
      case 4:
        if (srcoffset < LEN4MAXOFFSET) {
          pushnextbits(13, (5 << 10) | srcoffset);
          return;
        }
        break;
    }

    pushnextbits(23, (6 << 20) | ((len - 1) << 12) | srcoffset);
  }

};
