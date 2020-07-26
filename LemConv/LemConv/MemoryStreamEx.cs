// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			MemoryStreamEx.cs
// Created:			15/04/2018
// Author:			Mike
// Project:			LemConv
// Description:		Make it easier to write different sizes to a memory stream
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 15/04/2018		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LemConv
{
    public class MemoryStreamEx : MemoryStream
    {
        public MemoryStreamEx() : base()
        {
        }
        public MemoryStreamEx(string _filename) : base()
        {
            byte[] buff = File.ReadAllBytes(_filename);
            Write(buff,0,buff.Length);
            Seek(0, SeekOrigin.Begin);
        }

        public void Write8(byte _val)
        {
            WriteByte((byte)(_val & 0xff));
        }
        public void Write16(UInt16 _val)
        {
            WriteByte((byte) (_val & 0xff));
            WriteByte((byte)((_val>>8) & 0xff));
        }
        public void Write32(UInt32 _val)
        {
            WriteByte((byte)(_val & 0xff));
            WriteByte((byte)((_val >> 8) & 0xff));
            WriteByte((byte)((_val >> 16) & 0xff));
            WriteByte((byte)((_val >> 24) & 0xff));
        }

        public byte Read8()
        {
            return (byte)ReadByte();
        }
        public UInt16 Read16()
        {
            int v = (int) ReadByte();
            v |= (((int)ReadByte())<<8);
            return (UInt16)v;
        }
        public UInt32  Read32()
        {
            UInt32 v = (UInt32)ReadByte();
            v |= (((UInt32)ReadByte()) << 8);
            v |= (((UInt32)ReadByte()) << 16);
            v |= (((UInt32)ReadByte()) << 24);
            return (UInt32)v;
        }

    }
}
