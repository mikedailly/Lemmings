// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Sprite.cs
// Created:			24/12/2017
// Author:			Mike
// Project:			LemConv
// Description:		Sprite container
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 24/12/2017		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LemConv
{
    public class Sprite
    {
        public uint[] Raw;
        /// <summary>Sprite x drawing offset </summary>
        public int XOff;
        /// <summary>Sprite x drawing offset </summary>
        public int YOff;
        /// <summary>Actual WIDTH of Raw[]</summary>
        public int Width;
        /// <summary>Actual HEIGHTof Raw[]</summary>
        public int Height;
        /// <summary>Uncropped width of sprite </summary>
        public int FullWidth;
        /// <summary>Uncropped height of sprite</summary>
        public int FullHeight;


        public int FileOffset;

        // #############################################################################################
        /// <summary>
        ///     Get/Set array access into the image
        /// </summary>
        /// <param name="_x">x coordinate</param>
        /// <param name="_y">y coordinate</param>
        /// <returns>pixel</returns>
        // #############################################################################################
        public uint this[int _x, int _y]
        {
            get
            {
                return Raw[_x + (_y * Width)];

            }
            set
            {
                Raw[_x + (_y * Width)] = value;
            }
        }

        // #############################################################################################
        /// <summary>
        ///     Create a new sprite
        /// </summary>
        /// <param name="_w">width of sprite</param>
        /// <param name="_h">height of sprite</param>
        // #############################################################################################
        public Sprite(int _w, int _h)
        {
            Raw = new uint[_w * _h];
            for (int i = 0; i < (_w * _h); i++) Raw[i] = 0xffff00ff;        // full magenta is transparent
            Width = _w;
            Height = _h;
        }


        // #############################################################################################
        /// <summary>
        ///     Crop the sprites
        /// </summary>
        /// <param name="_xoff">x start of crop</param>
        /// <param name="_yoff">y start of crop</param>
        /// <param name="_width">width of new sprite</param>
        /// <param name="_height">height of new sprite</param>
        // #############################################################################################
        public void Crop(int _xoff,int _yoff, int _width, int _height)
        {
            int index =0;
            uint[] NewImage = new uint[_width * _height];
            for(int y = _yoff; y < (_yoff + _height); y++)
            {
                for (int x = _xoff; x < (_xoff + _width); x++)
                {
                    NewImage[index++] = this[x, y];
                }
            }
            Raw = NewImage;
            Width = _width;
            Height = _height;
        }


        // #############################################################################################
        /// <summary>
        ///     Save the sprite to a PNG
        /// </summary>
        /// <param name="_filename"></param>
        /// <param name="pal"></param>
        // #############################################################################################
        public void Save(string _filename, Palette pal)
        {
            Image img = new Image(Width,Height);
            for(int y = 0; y < Height; y++)
            {
                for (int x = 0; x < Width; x++)
                {
                    uint b = this[x, y];
                    if (b == 0xffff00ff)
                    {
                        img[x, y] = 0x00000000;     // make transparent
                    }
                    else
                    {
                        img[x, y] = b;
                    }
                }
            }
            img.Save(_filename);
        }



        /// <summary>
        ///     Draw this sprite onto the provided image
        /// </summary>
        /// <param name="_img"></param>
        /// <param name="_xx"></param>
        /// <param name="_yy"></param>
        public void Draw(Image _img, int _xx, int _yy)
        {
            // loop through all pixels
            for (int y = 0; y < Height; y++)
            {
                int xx = _xx;
                for (int x = 0; x < Width; x++)
                {
                    _img[xx++, _yy] = this[x, y];
                }
                _yy++;
            }
        }
    }
}
