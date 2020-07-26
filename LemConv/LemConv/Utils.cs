// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Sprite.cs
// Created:			?????
// Author:			Mike
// Project:			LemConv
// Description:		Misc tools
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// ?????    		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LemConv
{
    public static class Utils
    {
        /// <summary>
        ///     Fill a rectangle
        /// </summary>
        /// <param name="_x"></param>
        /// <param name="_y"></param>
        /// <param name="_w"></param>
        /// <param name="_h"></param>
        /// <param name="_img"></param>
        public static void FillRect(int _x, int _y, int _w, int _h, Image _img, uint _col=0x00000000)
        {
            int w = _img.Width;
            uint[] bitmap = _img.Raw;
            for (int yy = 0; yy < _h; yy++)
            {
                int pos = _x + (yy * w);
                for (int xx = 0; xx < _w; xx++)
                {
                    bitmap[pos++] = _col;
                }
                yy++;
            }

        }

    }
}
