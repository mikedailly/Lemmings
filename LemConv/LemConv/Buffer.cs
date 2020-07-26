// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Buffer.cs
// Created:			23/03/2018
// Author:			Mike
// Project:			LemConv
// Description:		Writes a specific number of bytes (from an INT) to a buffer/stream
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 23/03/2018		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LemConv
{
    public class Buffer : System.IO.MemoryStream
    {
        public void Write(UInt32 _value, int _count)
        {
            for (int i = 0; i < _count; i++)
            {
                WriteByte((byte) (_value & 0xff));
                _value = _value >> 8;
            }
        }
    }
}
