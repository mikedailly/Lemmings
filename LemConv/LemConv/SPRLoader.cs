// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			SPRLoader.cs
// Created:			30/10/2017
// Author:			Mike
// Project:			LemConv
// Description:		Loads in Windows lemmings .SPR files
//                  Also generates Z80 code for rendering the lemmings
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 30/10/2017		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

//  SPR file loader details found here
//  http://www.lemmingsforums.net/index.php?PHPSESSID=9704fd70d8738012c7510891784e0c51&topic=439.msg14762#msg14762
//

namespace LemConv
{
    // ####################################################################################
    /// <summary>Read in a SPR file and decompress</summary>
    // ####################################################################################
    public class SPRLoader
    {
        static long BankAnd = (BankSize - 1);             // 0x3FFF
        static long BankMask = (~BankAnd);    // 0xfffc0000
        static int ms_BankSize = 8192;
        static public int BankSize
        {
            get
            {
                return ms_BankSize;
            }
            set
            {
                ms_BankSize = value;
                BankAnd = value - 1;
                BankMask = BankAnd ^ 0xffffffff;
            }
        }

        public List<Sprite> m_Sprites = new List<Sprite>();
        public int Frames = 0;
        public List<int> ImageOffsets = new List<int>();

        byte[] buffer;
        Palette pal;

        public static bool SaveCode = false;
        // ####################################################################################
        /// <summary>
        ///     Crate container. Load in SPR file, decompress and extract all sprites
        /// </summary>
        /// <param name="_filename">SPR file to load</param>
        /// <param name="_palette">Palette to use</param>
        // ####################################################################################
        public SPRLoader(string _filename, Palette _palette)
        {
            pal = _palette;
            buffer = System.IO.File.ReadAllBytes(_filename);

            if (buffer[0] != 0x53 || buffer[1] != 0x52 || buffer[2] != 0x4c || buffer[3] != 0x45) return;    // 'SRLE' signature
            Frames = (int)buffer[4] | ((int)buffer[5] << 8);

            int index = 6;
            for (int i = 0; i < Frames; i++)
            {
                int GFXOffset = (int)buffer[index] | ((int)buffer[index + 1] << 8) | ((int)buffer[index + 2] << 16) | ((int)buffer[index + 3] << 24);
                index += 4;
                ImageOffsets.Add(GFXOffset);
            }

            // convert all sprites int this file
            foreach (int offset in ImageOffsets)
            {
                Sprite spr = GrabSprite(offset);
            }
            //if(SaveCode) ConvertToCode(m_Sprites[2]);
            //GenerateSimpleTextuepage(@"c:\temp\tpage.png");
        }


        // ####################################################################################
        /// Function:   <summary>
        ///                 Grab a comressed sprite
        ///             </summary>
        /// In:         <param name="_offset">offset to sprite data</param>
        /// Out:        <returns>
        ///                 The grabbed sprite
        ///             </returns>
        // ####################################################################################
        public Sprite GrabSprite(int _offset)
        {            
            int xoff = buffer[_offset] | ((int)buffer[_offset + 1] << 8);
            _offset += 2;
            int yoff = buffer[_offset] | ((int)buffer[_offset + 1] << 8);
            _offset += 2;
            int maxDataWidth = buffer[_offset] | ((int)buffer[_offset + 1] << 8);
            _offset += 2;
            int dataHeight = buffer[_offset] | ((int)buffer[_offset + 1] << 8);
            _offset += 2;
            int imageWidth = buffer[_offset] | ((int)buffer[_offset + 1] << 8);
            _offset += 2;
            int imageHeight = buffer[_offset] | ((int)buffer[_offset + 1] << 8);
            _offset += 2;

            Sprite spr = new Sprite(maxDataWidth, dataHeight);
            spr.FullWidth = imageWidth;
            spr.FullHeight = imageHeight;
            spr.XOff = xoff;
            spr.YOff = yoff;
            for (int y = 0; y < dataHeight; y++)
            {
                int x = 0;
                // Basic compression
                //
                //  0x84 0xAA 0xBB 0xCC 0xDD 0x80
                //  represents four bytes image data(AA, BB, CC, DD) starting at offset 0.
                //
                //  0x03 0x85 0xAA 0xBB 0xCC 0xDD 0xEE 0x80
                //  represents 5 bytes image data(AA, BB, CC, DD, EE) starting at offset 3.
                //
                //  Each line can have many "sub" lines
                //  05 84 30 2C 2C 2C ## 02 84 30 30 2C 2C 80
                //
                // 7F 0B 94 1A 0B 18...
                // The offset here is not 0x7f, but 0x7f + 0x0b, the following 0x94 is the start character for a data line of 0x14 elements.
                while (buffer[_offset] != 0x80)
                {
                    int len = buffer[_offset++];
                    if ((len & 0x80) == 0)
                    {
                        if (len == 0x7f)
                        {
                            int o = buffer[_offset++];
                            if ((o & 0x80) != 0)
                            {
                                x += len;
                                len = o;
                            }
                            else
                            {
                                len += o;
                                x += len;
                                len = buffer[_offset++];
                            }
                        }
                        else
                        {
                            x += len;
                            len = buffer[_offset++];
                        }
                    } 
                    int counter = (len & 0x7f);
                    while (counter > 0)
                    {
                        spr[x, y] = pal[buffer[_offset++]];
                        counter--;
                        x++;
                    }
                }
                _offset++;          // skip $80 at the end of a line
            }
            //spr.Crop(xoff, yoff, maxDataWidth, dataHeight);
            //spr.Save(@"c:\temp\style.png", pal);
            m_Sprites.Add(spr);

            return spr;
        }

        // ####################################################################################
        /// <summary>
        ///     Build a very simple TPage of all sprites
        /// </summary>
        /// <param name="_filename">The name of the file to save as</param>
        /// <returns></returns>
        // ####################################################################################
        public Image GenerateSimpleTextuepage(string _filename)
        {
            int w = -1;
            int h = -1;
            foreach (Sprite spr in m_Sprites)
            {
                if (w < spr.Width) w = spr.Width;
                if (h < spr.Height) h = spr.Height;
            }

            int row = (int)Math.Floor(Math.Sqrt((double)m_Sprites.Count));
            if ((row * row) < m_Sprites.Count) row++;

            int pw = row * w;
            int ph = row * h;
            Image img = new Image(pw, ph);

            int counter = 0;
            foreach (Sprite spr in m_Sprites)
            {
                int xx = (counter % row) * w;
                int yy = (counter / row) * h;
                spr.Draw(img, xx, yy);
                counter++;
            }
            img.Save(_filename);
            return img;
        }


        // ####################################################################################
        /// Function:   <summary>
        ///                 Save sprites
        ///             </summary>
        /// in:         <param name="_filename"></param>
        // ####################################################################################
        public void SaveSprites(string _filename, bool _ascode)
        {
            Console.WriteLine("{0} saved to {1}", m_Sprites.Count, _filename);
            byte[] buffer = new byte[1024 * 1024];
            List<int> sprites_offsets = new List<int>();
            List<int> offsets = new List<int>();

            // reserve space for the sprite index table
            int index = 0;
            foreach (Sprite sp in m_Sprites)
            {
                buffer[index++] = 0;
                buffer[index++] = 0;
                buffer[index++] = 0;
                buffer[index++] = 0;
                if (_ascode) buffer[index++] = 0;        // in the code mode, we use 2 bytes here as the origin offset
            }

            int sp_index = 0;
            // write out sprites
            foreach (Sprite sp in m_Sprites)
            {
                if (sp_index == 9) sp_index = 9;
                if (_ascode)
                {
                    //if (sp_index == 94) sp_index++;
                    if (sp_index == 352) sp_index = 352;        // "4"
                    Buffer buff = ConvertToCode(sp, sp_index,0);
                    int size = (int)buff.Length;


                    // while this sprite cross a bank boundary? if so pad to next bank
                    //int crossbank = (index & (int)BankAnd) + size;
                    //if ((crossbank & BankMask) != 0)
                    //{
                    //    // round up to nearest bank
                    //    while (((index & BankAnd) != 0))
                    //    {
                    //        buffer[index++] = 0;
                    //    }
                   // }
                    // Now convert again, but this time we know where the code will START
                    buff = ConvertToCode(sp, sp_index, 0x4000 | (index&0x1fff));

                    //offsets.Add( (sp.FullWidth-sp.Width)- sp.XOff);
                    //offsets.Add((sp.FullHeight - sp.Height) - sp.YOff);
                    offsets.Add(sp.FullWidth - sp.XOff);
                    offsets.Add(sp.FullHeight - sp.YOff);
                    sprites_offsets.Add(index);

                    buff.Seek(0, System.IO.SeekOrigin.Begin);
                    for (int i = 0; i < buff.Length; i++)
                    {
                        buffer[index++] = (byte)buff.ReadByte();
                    }
                }
                else
                {
                    // while this sprite cross a bank boundary? if so pad to next bank
                    //int crossbank = (index & (int)BankAnd) + ((sp.Height * sp.Width) + 6);
                    //if ((crossbank & BankMask) != 0)
                    //{
                    //    // round up to nearest bank
                    //    while (((index & BankAnd) != 0))
                    //    {
                    //        buffer[index++] = 0;
                    //    }
                    //}

                    sprites_offsets.Add(index);

                    buffer[index++] = (byte)sp.XOff;
                    buffer[index++] = (byte)sp.YOff;
                    buffer[index++] = (byte)sp.Width;
                    buffer[index++] = (byte)sp.Height;
                    buffer[index++] = (byte)((sp.Height * sp.Width) & 0xff);
                    buffer[index++] = (byte)(((sp.Height * sp.Width) >> 8) & 0xff);

                    for (int yy = 0; yy < sp.Height; yy++)
                    {
                        for (int xx = 0; xx < sp.Width; xx++)
                        {
                            uint col = sp[xx, yy];
                            byte c = (byte)((((col & 0xe00000) >> 16) | ((col & 0xe000) >> 11) | ((col & 0xc0) >> 6)) & 0xff);
                            // we need to move "black" as it'll show sprites behind the back ground through them.
                            if (c == 0x00) c = 1;
                            // if (c == 0xe3) c = 0;
                            buffer[index++] = c;
                        }
                    }
                }
                sp_index++;
            }



            // first write offsets (int)
            int fileindex = 0;
            int offindex = 0;
            foreach (int i in sprites_offsets)
            {
                // 8k banks?
                if (BankAnd == 0x1fff)
                {
                    // first 2 bytes are offset into bank - with bank base added on
                    int off = i & 0x1fff;
                    buffer[fileindex++] = (byte)(off & 0xff);
                    buffer[fileindex++] = (byte)((off>>8) | 0x40);

                    // next byte is bank offset from loaded base
                    // top 2 bits of bank offset + any other size
                    buffer[fileindex++] = (byte)((i >> 13) & 0xff);

                    // store X,Y origin offsets
                    if (_ascode)
                    {
                        buffer[fileindex++] = (byte)offsets[offindex++];
                        buffer[fileindex++] = (byte)offsets[offindex++];
                    }
                    else
                    {
                        // unused (4 byte size for ease of calculation)
                        buffer[fileindex++] = 0;
                    }
                }
                else
                {
                    // first 2 bytes are offset into bank - with bank base added on
                    buffer[fileindex++] = (byte)(i & 0xff);
                    buffer[fileindex++] = (byte)(((i >> 8) & ((int)BankAnd >> 8)) | 0x40);

                    // next byte is bank offset from loaded base
                    // top 2 bits of bank offset + any other size
                    buffer[fileindex++] = (byte)((i >> 14) & 0xff);

                    // unused (4 byte size for ease of calculation)
                    buffer[fileindex++] = 0;
                }


            }



            // Create file bundle
            byte[] File = new byte[index];

            // copy sprites
            fileindex = 0;
            for (int i = 0; i < index; i++)
            {
                File[fileindex++] = buffer[i];
            }

            System.IO.File.WriteAllBytes(_filename, File);

        }

        // ####################################################################################
        /// <summary>
        ///     Convert a 32bit colour to RRRGGGBB format
        /// </summary>
        /// <param name="_colour"></param>
        /// <returns></returns>
        // ####################################################################################
        public byte ConvertPixel(UInt32 _colour)
        {
            return (byte)((((_colour & 0xe00000) >> 16) | ((_colour & 0xe000) >> 11) | ((_colour & 0xc0) >> 6)) & 0xff);
        }


        // ####################################################################################
        /// <summary>
        ///     Search the provided sprite for the 2 most common colours
        /// </summary>
        /// <param name="_sp">Sprite to scan</param>
        /// <returns>
        ///     INT = 0_0_NEXT_MOST
        /// </returns>
        // ####################################################################################
        int FindMostCommponColours(Sprite _sp)
        {
            byte[] ColourCounter = new byte[256];
            for (int yy = _sp.Height - 1; yy >= 0; yy--)
            {
                for (int xx = 0; xx < _sp.Width; xx++)
                {
                    // Get pixel
                    uint col = _sp[xx, yy];
                    byte c = ConvertPixel(col);
                    ColourCounter[c]++;
                }
            }
            ColourCounter[0xe3] = 0;

            // now find the top 2 colours
            int col1_cnt = 0;
            int col1 = 0xe3;
            int col2_cnt = 0;
            int col2 = 0;

            for (int i = 0; i < 256; i++)
            {
                if (ColourCounter[i] > col1_cnt)
                {
                    col2_cnt = col1_cnt;
                    col2 = col1;
                    col1_cnt = ColourCounter[i];
                    col1 = i;
                }
                else if (ColourCounter[i] > col2_cnt)
                {
                    col2_cnt = ColourCounter[i];
                    col2 = i;
                }
            }
            return (col2 << 8) | col1;
        }



        // ####################################################################################
        /// <summary>
        ///     Convert a bitmap into direct drawing code
        /// </summary>
        /// <param name="_sp">The sprite to convert</param>
        /// <returns>
        ///     The code in a buffer
        /// </returns>
        // ####################################################################################
        public Buffer ConvertToCode(Sprite _sp, int _sprite_number, int _StartingOffset)
        {
            bool LR = true;         // plot Left to Right

            StringBuilder sb = new StringBuilder(1024);
            Buffer buff = new Buffer();

            int bc = 0;
            int a = 0x100;
            int tstates = 0;
            int tstates_max = 0;
            int bytes = 0;

            int de = FindMostCommponColours(_sp);
            int e = de & 0xff;
            int d = (de >> 8) & 0xff;

            // setup port
            sb.AppendLine("\t\t; Sprite Number " + _sprite_number.ToString());
            sb.AppendLine("\t\t; Common code = 59 T-States (outside function)");
            sb.AppendLine("\t\t; HL = screen address [y,x]");
            
            sb.AppendLine("\t\tld\tde," + de.ToString() + "\t\t;Most common 2 colours"); tstates += 10; bytes += 3; buff.Write(0x11 | (uint)(de << 8), 3);
            sb.AppendLine();

            bool SkipInitialAdds = false;

            // read through all pixels....
            for (int yy = _sp.Height - 1; yy >= 0; yy--)
            {
                a = 0x100;
                int xx, delta, end;
                if (LR)
                {
                    xx = 0;
                    delta = 1;
                    end = _sp.Width;
                }else
                {
                    xx = _sp.Width - 1;
                    delta = -1;
                    end = -1;
                }
                while(xx!=end)
                //for (int xx = 0; xx < _sp.Width; xx++)
                {
                    // Get pixel
                    uint col = _sp[xx, yy];
                    byte c = ConvertPixel(col);

                    bool SetA = false;
                    int xl = xx + 1;
                    int cnt = 1;

                    // detect "runs" of colour
                    if (LR)
                    {
                        while (xl < _sp.Width)
                        {
                            uint colchk = _sp[xl, yy];
                            byte c2 = ConvertPixel(colchk);
                            if (c2 == 0xe3)
                            {
                                xl++;
                            }
                            else if (c == c2)
                            {
                                cnt++;
                                xl++;
                            }
                            else
                            {
                                break;
                            }
                        }
                    }else
                    {
                        while (xl >= 0)
                        {
                            uint colchk = _sp[xl, yy];
                            byte c2 = ConvertPixel(colchk);
                            if (c2 == 0xe3)
                            {
                                xl--;
                            }
                            else if (c == c2)
                            {
                                cnt++;
                                xl--;
                            }
                            else
                            {
                                break;
                            }
                        }

                    }
                    if (cnt >= 3) SetA = true;



                    // transaprent?
                    if (c == 0xe3)
                    {
                        bc++;
                    }
                    else
                    {
                        if (!SkipInitialAdds)
                        {
                            if (LR)
                            {
                                switch (bc)
                                {
                                    case 0: break;
                                    case 1: sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1); break;
                                    case 2:
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        break;
                                    case 3:
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        break;
                                    default:
                                        // "HL" never crosses a 256 byte boundary here, so just add to L. 15 Tstates, 4 bytes (1 T-State faster than add hl,$0000)
                                        sb.AppendLine("\t\tld\ta," + (bc & 0xff).ToString()); tstates += 7; bytes += 2; buff.Write(0x3E | (((uint)(bc & 0xff)) << 8), 2);
                                        sb.AppendLine("\t\tadd\ta,l"); tstates += 4; bytes += 1; buff.Write(0x85, 1);
                                        sb.AppendLine("\t\tld\tl,a"); tstates += 4; bytes += 1; buff.Write(0x6f, 1);
                                        a = bc & 0xff;
                                        break;
                                }
                            }else
                            {
                                switch (bc)
                                {
                                    case 0: break;
                                    case 1: sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1); break;
                                    case 2:
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        break;
                                    case 3:
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        break;
                                    default:
                                        // "HL" never crosses a 256 byte boundary here, so just add to L. 15 Tstates, 4 bytes (1 T-State faster than add hl,$0000)
                                        sb.AppendLine("\t\tld\ta,l"); tstates += 4; bytes += 1; buff.Write(0x7D, 1);
                                        sb.AppendLine("\t\tsub\t"+ (bc & 0xff).ToString()); tstates += 7; bytes += 2; buff.Write(0xD6 | (((uint)(bc & 0xff)) << 8), 2); 
                                        sb.AppendLine("\t\tld\tl,a"); tstates += 4; bytes += 1; buff.Write(0x6f, 1);
                                        a = bc & 0xff;
                                        break;
                                }

                            }
                        }
                        bc = 0;
                        SkipInitialAdds = false;

                        bool skipstore = false;
                        if (c == e)
                        {
                            sb.AppendLine("\t\tld\t(hl),e"); tstates += 7; bytes += 1; buff.Write(0x73, 1);
                            skipstore = true;
                        }
                        else if (c == d)
                        {
                            sb.AppendLine("\t\tld\t(hl),d"); tstates += 7; bytes += 1; buff.Write(0x72, 1);
                            skipstore = true;
                        }
                        else if (SetA)
                        {
                            if (a != c)
                            {
                                a = c;
                                sb.AppendLine("\t\tld\ta," + a.ToString()); tstates += 7; bytes += 2; buff.Write(0x3E | (((uint)(a & 0xff)) << 8), 2);
                            }
                        }

                        if (!skipstore)
                        {
                            if (a == c)
                            {
                                sb.AppendLine("\t\tld\t(hl),a"); tstates += 7; bytes += 1; buff.Write(0x77, 1);
                            }
                            else
                            {
                                sb.AppendLine("\t\tld\t(hl)," + c.ToString()); tstates += 10; bytes += 2; buff.Write(0x36 | (((uint)c) << 8), 2);
                            }
                        }
                        bc++;
                    }

                    xx += delta;
                }

                // work out pixels to next line...
                bc -= 256;
                bc -= (_sp.Width);


                if (yy != 0)
                {
                    // move to next line... Do we skip a few pixels first? If so include them in the new line ADD
                    int yl = yy - 1;
                    bool NotDone = true;
                    while (NotDone)
                    {
                        int xl = 0;
                        int cnt = 0;
                        while (xl < _sp.Width)
                        {
                            uint colchk = _sp[xl, yl];
                            byte c2 = ConvertPixel(colchk);
                            if (c2 == 0xe3)
                            {
                                xl++;
                                cnt++;
                            }
                            else
                            {
                                break;
                            }
                        }
                        // Line empty?
                        if (cnt == _sp.Width)
                        {
                            bc -= 256;
                            yl--;
                            yy--;
                            if (yl == 0) goto StopEarly;
                        }
                        else if (cnt != 0)
                        {
                            bc += cnt;
                            SkipInitialAdds = true;
                            NotDone = false;
                        }
                        else
                        {
                            NotDone = false;
                            break;
                        }
                    }
                    sb.AppendLine("\t\tadd\thl," + bc.ToString() + "\t\t\t;move back to start of line, and up one line"); tstates += 16; bytes += 4; buff.Write(0x34ED | (((uint)bc) << 16), 4);
                    bc = 0;

                    a = -1;
                    // New line code.... don't do on last line
                    sb.AppendLine();
                    sb.AppendLine("\t\t;New line");
                    //sb.AppendLine("\t\ttest\t$40"); tstates += 11; bytes += 3; buff.Write(0x4027ED, 3);
                    sb.AppendLine("\t\tbit\t6,h"); tstates += 8; bytes += 2; buff.Write(0x74CB, 2);
                    //sb.AppendLine("\t\tjr\tz,@NoBankChange" + yy.ToString()); tstates += 12; bytes += 2; tstates_max = -5; buff.Write(0x0928, 2);  // branch forward 12
                    sb.AppendLine("\t\tjp\tz,@NoBankChange" + yy.ToString()); tstates += 10; bytes += 3; tstates_max = 0; buff.Write(0xca | (uint)((_StartingOffset+ bytes + 11)<<8), 3);  // branch forward 12
                    sb.AppendLine("\t\tld\ta,h"); tstates += 0; bytes += 1; tstates_max += 4; buff.Write(0x7c, 1);
                    sb.AppendLine("\t\tand\ta,$3f"); tstates += 0; bytes += 2; tstates_max += 7; buff.Write(0x3Fe6, 2);
                    sb.AppendLine("\t\tld\th,a"); tstates += 0; bytes += 1; tstates_max += 5; buff.Write(0x67, 1);
                    sb.AppendLine("\t\tex\taf,af'"); tstates += 0; bytes += 1; tstates_max += 4; buff.Write(0x08, 1);
                    sb.AppendLine("\t\tsub\t$40"); tstates += 0; bytes += 2; tstates_max += 7; buff.Write(0x40D6, 2);
                    //sb.AppendLine("\t\tcp\t$CB\t\t\t; clipped? test with $cb due to register flags"); tstates += 0; bytes += 2; tstates_max += 4; buff.Write(0xCBFE, 2);
                    //sb.AppendLine("\t\tret\tz"); tstates += 0; bytes += 1; tstates_max += 5; buff.Write(0x0C8, 1);
                    sb.AppendLine("\t\tret\tm"); tstates += 0; bytes += 1; tstates_max += 5; buff.Write(0x0F8, 1);
                    sb.AppendLine("\t\tout\t(c),a"); tstates += 0; bytes += 2; tstates_max += 12; buff.Write(0x79ED, 2);
                    sb.AppendLine("\t\tex\taf,af'"); tstates += 0; bytes += 1; tstates_max += 4; buff.Write(0x08, 1);
                    sb.AppendLine("@NoBankChange" + yy.ToString() + ":");
                    sb.AppendLine();
                }
                else
                {
                    break;
                }
            }
            StopEarly:
            sb.AppendLine();
            sb.AppendLine("\t\tld\ta,2"); tstates += 7; bytes += 2; buff.Write(0x023E, 2);
            sb.AppendLine("\t\tout\t(c),a"); tstates += 12; bytes += 2; buff.Write(0x79ED, 2);
            sb.AppendLine("\t\tret"); tstates += 10; bytes += 1; ; buff.Write(0xc9, 1);
            sb.AppendLine("\t\t; T-States=" + (tstates+59).ToString() + "/" + (tstates +59+ tstates_max).ToString() + "     bytes =" + bytes.ToString());
            sb.AppendLine();
            //return sb.ToString();
            return buff;
        }


        // ####################################################################################
        /// <summary>
        ///     Convert a bitmap into direct drawing code
        /// </summary>
        /// <param name="_sp">The sprite to convert</param>
        /// <returns>
        ///     The code in a buffer
        /// </returns>
        // ####################################################################################
        public Buffer ConvertToCode_Lem(Sprite _sp, int _sprite_number, int _StartingOffset)
        {
            bool LR = true;         // plot Left to Right

            StringBuilder sb = new StringBuilder(1024);
            Buffer buff = new Buffer();

            int bc = 0;
            int a = 0x100;
            int tstates = 0;
            int tstates_max = 0;
            int bytes = 0;

            int de = FindMostCommponColours(_sp);
            int e = de & 0xff;
            int d = (de >> 8) & 0xff;

            // setup port
            sb.AppendLine("\t\t; Sprite Number " + _sprite_number.ToString());
            sb.AppendLine("\t\t; Common code = 59 T-States (outside function)");
            sb.AppendLine("\t\t; HL = screen address [y,x]");
            // This is now done OUTSIDE the function, as it's common
            //sb.AppendLine("\t\tld\tbc,$123b"); tstates += 10; bytes += 3; buff.Write(0x123B01, 3);
            //sb.AppendLine("\t\tld\ta,h"); tstates += 4; bytes += 1; buff.Write(0x7C, 1);
            //sb.AppendLine("\t\tand\t$c0"); tstates += 7; bytes += 2; buff.Write(0xc0E6, 2);
            //sb.AppendLine("\t\tor\t$03+8"); tstates += 7; bytes += 2; buff.Write(0x0BF6, 2);
            //sb.AppendLine("\t\tout\t(c),a"); tstates += 12; bytes += 2; buff.Write(0x79ED, 2);

            //sb.AppendLine("\t\tex\taf,af'"); tstates += 4; bytes += 1; buff.Write(0x08, 1);
            //sb.AppendLine("\t\tld\ta,h"); tstates += 4; bytes += 1; buff.Write(0x7C, 1);
            //sb.AppendLine("\t\tand\t$3f"); tstates += 7; bytes += 2; buff.Write(0x3FE6, 2);
            //sb.AppendLine("\t\tld\th,a"); tstates += 4; bytes += 1; buff.Write(0x67, 1);

            sb.AppendLine("\t\tld\tde," + de.ToString() + "\t\t;Most common 2 colours"); tstates += 10; bytes += 3; buff.Write(0x11 | (uint)(de << 8), 3);
            sb.AppendLine();

            bool SkipInitialAdds = false;

            // read through all pixels....
            for (int yy = _sp.Height - 1; yy >= 0; yy--)
            {
                a = 0x100;
                int xx, delta, end;
                if (LR)
                {
                    xx = 0;
                    delta = 1;
                    end = _sp.Width;
                }
                else
                {
                    xx = _sp.Width - 1;
                    delta = -1;
                    end = -1;
                }
                while (xx != end)
                //for (int xx = 0; xx < _sp.Width; xx++)
                {
                    // Get pixel
                    uint col = _sp[xx, yy];
                    byte c = ConvertPixel(col);

                    bool SetA = false;
                    int xl = xx + 1;
                    int cnt = 1;

                    // detect "runs" of colour
                    if (LR)
                    {
                        while (xl < _sp.Width)
                        {
                            uint colchk = _sp[xl, yy];
                            byte c2 = ConvertPixel(colchk);
                            if (c2 == 0xe3)
                            {
                                xl++;
                            }
                            else if (c == c2)
                            {
                                cnt++;
                                xl++;
                            }
                            else
                            {
                                break;
                            }
                        }
                    }
                    else
                    {
                        while (xl >= 0)
                        {
                            uint colchk = _sp[xl, yy];
                            byte c2 = ConvertPixel(colchk);
                            if (c2 == 0xe3)
                            {
                                xl--;
                            }
                            else if (c == c2)
                            {
                                cnt++;
                                xl--;
                            }
                            else
                            {
                                break;
                            }
                        }

                    }
                    if (cnt >= 3) SetA = true;



                    // transaprent?
                    if (c == 0xe3)
                    {
                        bc++;
                    }
                    else
                    {
                        if (!SkipInitialAdds)
                        {
                            if (LR)
                            {
                                switch (bc)
                                {
                                    case 0: break;
                                    case 1: sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1); break;
                                    case 2:
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        break;
                                    case 3:
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        sb.AppendLine("\t\tinc\tl"); tstates += 4; bytes += 1; buff.Write(0x2C, 1);
                                        break;
                                    default:
                                        // "HL" never crosses a 256 byte boundary here, so just add to L. 15 Tstates, 4 bytes (1 T-State faster than add hl,$0000)
                                        sb.AppendLine("\t\tld\ta," + (bc & 0xff).ToString()); tstates += 7; bytes += 2; buff.Write(0x3E | (((uint)(bc & 0xff)) << 8), 2);
                                        sb.AppendLine("\t\tadd\ta,l"); tstates += 4; bytes += 1; buff.Write(0x85, 1);
                                        sb.AppendLine("\t\tld\tl,a"); tstates += 4; bytes += 1; buff.Write(0x6f, 1);
                                        a = bc & 0xff;
                                        break;
                                }
                            }
                            else
                            {
                                switch (bc)
                                {
                                    case 0: break;
                                    case 1: sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1); break;
                                    case 2:
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        break;
                                    case 3:
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        sb.AppendLine("\t\tdec\tl"); tstates += 4; bytes += 1; buff.Write(0x2D, 1);
                                        break;
                                    default:
                                        // "HL" never crosses a 256 byte boundary here, so just add to L. 15 Tstates, 4 bytes (1 T-State faster than add hl,$0000)
                                        sb.AppendLine("\t\tld\ta,l"); tstates += 4; bytes += 1; buff.Write(0x7D, 1);
                                        sb.AppendLine("\t\tsub\t" + (bc & 0xff).ToString()); tstates += 7; bytes += 2; buff.Write(0xD6 | (((uint)(bc & 0xff)) << 8), 2);
                                        sb.AppendLine("\t\tld\tl,a"); tstates += 4; bytes += 1; buff.Write(0x6f, 1);
                                        a = bc & 0xff;
                                        break;
                                }

                            }
                        }
                        bc = 0;
                        SkipInitialAdds = false;

                        bool skipstore = false;
                        if (c == e)
                        {
                            sb.AppendLine("\t\tld\t(hl),e"); tstates += 7; bytes += 1; buff.Write(0x73, 1);
                            skipstore = true;
                        }
                        else if (c == d)
                        {
                            sb.AppendLine("\t\tld\t(hl),d"); tstates += 7; bytes += 1; buff.Write(0x72, 1);
                            skipstore = true;
                        }
                        else if (SetA)
                        {
                            if (a != c)
                            {
                                a = c;
                                sb.AppendLine("\t\tld\ta," + a.ToString()); tstates += 7; bytes += 2; buff.Write(0x3E | (((uint)(a & 0xff)) << 8), 2);
                            }
                        }

                        if (!skipstore)
                        {
                            if (a == c)
                            {
                                sb.AppendLine("\t\tld\t(hl),a"); tstates += 7; bytes += 1; buff.Write(0x77, 1);
                            }
                            else
                            {
                                sb.AppendLine("\t\tld\t(hl)," + c.ToString()); tstates += 10; bytes += 2; buff.Write(0x36 | (((uint)c) << 8), 2);
                            }
                        }
                        bc++;
                    }

                    xx += delta;
                }

                // work out pixels to next line...
                bc -= 256;
                bc -= (_sp.Width);


                if (yy != 0)
                {
                    // move to next line... Do we skip a few pixels first? If so include them in the new line ADD
                    int yl = yy - 1;
                    bool NotDone = true;
                    while (NotDone)
                    {
                        int xl = 0;
                        int cnt = 0;
                        while (xl < _sp.Width)
                        {
                            uint colchk = _sp[xl, yl];
                            byte c2 = ConvertPixel(colchk);
                            if (c2 == 0xe3)
                            {
                                xl++;
                                cnt++;
                            }
                            else
                            {
                                break;
                            }
                        }
                        // Line empty?
                        if (cnt == _sp.Width)
                        {
                            bc -= 256;
                            yl--;
                            yy--;
                            if (yl == 0) goto StopEarly;
                        }
                        else if (cnt != 0)
                        {
                            bc += cnt;
                            SkipInitialAdds = true;
                            NotDone = false;
                        }
                        else
                        {
                            NotDone = false;
                            break;
                        }
                    }
                    sb.AppendLine("\t\tadd\thl," + bc.ToString() + "\t\t\t;move back to start of line, and up one line"); tstates += 16; bytes += 4; buff.Write(0x34ED | (((uint)bc) << 16), 4);
                    bc = 0;

                    a = -1;
                    // New line code.... don't do on last line
                    sb.AppendLine();
                    sb.AppendLine("\t\t;New line");
                    //sb.AppendLine("\t\ttest\t$40"); tstates += 11; bytes += 3; buff.Write(0x4027ED, 3);
                    sb.AppendLine("\t\tbit\t6,h"); tstates += 8; bytes += 2; buff.Write(0x74CB, 2);
                    //sb.AppendLine("\t\tjr\tz,@NoBankChange" + yy.ToString()); tstates += 12; bytes += 2; tstates_max = -5; buff.Write(0x0928, 2);  // branch forward 12
                    sb.AppendLine("\t\tjp\tz,@NoBankChange" + yy.ToString()); tstates += 10; bytes += 3; tstates_max = 0; buff.Write(0xca | (uint)((_StartingOffset + bytes + 11) << 8), 3);  // branch forward 12
                    sb.AppendLine("\t\tld\ta,h"); tstates += 0; bytes += 1; tstates_max += 4; buff.Write(0x7c, 1);
                    sb.AppendLine("\t\tand\ta,$3f"); tstates += 0; bytes += 2; tstates_max += 7; buff.Write(0x3Fe6, 2);
                    sb.AppendLine("\t\tld\th,a"); tstates += 0; bytes += 1; tstates_max += 5; buff.Write(0x67, 1);
                    sb.AppendLine("\t\tex\taf,af'"); tstates += 0; bytes += 1; tstates_max += 4; buff.Write(0x08, 1);
                    sb.AppendLine("\t\tsub\t$40"); tstates += 0; bytes += 2; tstates_max += 7; buff.Write(0x40D6, 2);
                    //sb.AppendLine("\t\tcp\t$CB\t\t\t; clipped? test with $cb due to register flags"); tstates += 0; bytes += 2; tstates_max += 4; buff.Write(0xCBFE, 2);
                    //sb.AppendLine("\t\tret\tz"); tstates += 0; bytes += 1; tstates_max += 5; buff.Write(0x0C8, 1);
                    sb.AppendLine("\t\tret\tm"); tstates += 0; bytes += 1; tstates_max += 5; buff.Write(0x0F8, 1);
                    sb.AppendLine("\t\tout\t(c),a"); tstates += 0; bytes += 2; tstates_max += 12; buff.Write(0x79ED, 2);
                    sb.AppendLine("\t\tex\taf,af'"); tstates += 0; bytes += 1; tstates_max += 4; buff.Write(0x08, 1);
                    sb.AppendLine("@NoBankChange" + yy.ToString() + ":");
                    sb.AppendLine();
                }
                else
                {
                    break;
                }
            }
            StopEarly:
            sb.AppendLine();
            sb.AppendLine("\t\tld\ta,2"); tstates += 7; bytes += 2; buff.Write(0x023E, 2);
            sb.AppendLine("\t\tout\t(c),a"); tstates += 12; bytes += 2; buff.Write(0x79ED, 2);
            sb.AppendLine("\t\tret"); tstates += 10; bytes += 1; ; buff.Write(0xc9, 1);
            sb.AppendLine("\t\t; T-States=" + (tstates + 59).ToString() + "/" + (tstates + 59 + tstates_max).ToString() + "     bytes =" + bytes.ToString());
            sb.AppendLine();
            //return sb.ToString();
            return buff;
        }


        public List<int> m_BlockData;
        // ####################################################################################
        /// Function:   <summary>
        ///                 Start a sprite block
        ///             </summary>
        /// in:         <param name="_filename">name of file to save to....</param>
        // ####################################################################################
        public void SpriteBlockBegin(string _filename, int _numsprites)
        {
            m_BlockData = new List<int>(_numsprites*6);
            /*buffer[index++] = (byte)sp.XOff;
            buffer[index++] = (byte)sp.YOff;
            buffer[index++] = (byte)sp.Width;
            buffer[index++] = (byte)sp.Height;
            buffer[index++] = (byte)((sp.Height * sp.Width) & 0xff);
            buffer[index++] = (byte)(((sp.Height * sp.Width) >> 8) & 0xff);*/

        }

        // ####################################################################################
        /// Function:   <summary>
        ///                 Save specific sprite sprites
        ///             </summary>
        /// in:         <param name="_filename"></param>
        // ####################################################################################
        public void AddSprite(int _index, string _filename)
        {
        }
    }
}
