// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Palette.cs
// Created:			15/11/2017
// Author:			Mike
// Project:			LemConv
// Description:		Palette loader
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 15/11/2017		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LemConv
{
    public class Palette
    {
        public int Number;
        public uint[] Pal;

        
        // #############################################################################################
        /// <summary>
        ///     Get/Set array access into the palette
        /// </summary>
        /// <param name="_index">palette entry</param>
        /// <returns>palette entry</returns> 
        // #############################################################################################
        public uint this[int _index]
        {
            get
            {
                return Pal[_index];
            }
            set
            {
                Pal[_index]= value;
            }
        }


        // #############################################################################################
        /// <summary>
        ///     Create a custom palette file
        /// </summary>
        /// <param name="_size"></param>
        // #############################################################################################
        public Palette(int _size)
        {
            Number = _size;
            Pal = new uint[_size];
        }

        // #############################################################################################
        /// <summary>
        ///     Load a .PAL file
        /// </summary>
        /// <param name="_palette_file">name of file to load</param>
        // #############################################################################################
        public Palette(string _palette_file)
        {
            byte[] buffer = System.IO.File.ReadAllBytes(_palette_file);
            if (buffer[0] != 0x20 || buffer[1] != 0x4c || buffer[2] != 0x41 || buffer[3] != 0x50) return;    // ' LAP' signature

            // number of palette entries
            Number = (int)buffer[4]| ((int)buffer[5]<<8);
            Pal = new uint[256];                                // always make 256
            int pal_index = 0;
            while (pal_index < 256)
            {
                int index = 6;
                for (int i = 0; i < Number; i++)
                {
                    uint colour = (uint)buffer[index + 2] | ((uint)buffer[index + 1] << 8) | ((uint)buffer[index] << 16) | 0xff000000;  // ((uint)buffer[index + 3] << 24);
                    index += 4;
                    Pal[pal_index++] = colour;
                }
            }

        }
    }
}
