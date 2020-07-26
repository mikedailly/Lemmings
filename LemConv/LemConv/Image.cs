// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Image.cs
// Created:			30/10/2017
// Author:			Mike
// Project:			LemConv
// Description:		Holds all the data for a single image
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
using System.IO;
using System.Drawing;


namespace LemConv
{
    public unsafe class Image
    {
        public string FullFilename;
        public string Filename;
        public UInt32[] Raw;
        public int Width;
        public int Height;


        // #############################################################################################
        /// <summary>
        ///     Get/Set array access into the image
        /// </summary>
        /// <param name="_x">x coordinate</param>
        /// <param name="_y">y coordinate</param>
        /// <returns>pixel</returns>
        // #############################################################################################
        public uint this[int _x,int _y]
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
        /// Constructor: <summary>
        ///              	Create a new image holder
        ///              </summary>
        ///
        /// In:		<param name="_filename">full path+filenameto image</param>
        // #############################################################################################
        public unsafe Image(int _w, int _h)
        {
            Raw = new uint[_w * _h];
            Width = _w;
            Height = _h;
        }
        // #############################################################################################
        /// Constructor: <summary>
        ///              	Create a new image holder
        ///              </summary>
        /// In:		<param name="_filename">full path to image</param>
        // #############################################################################################
        public unsafe Image( string _filename )
        {
            FullFilename = _filename;

            // Now load the PNG and get the pixels from it....
            Bitmap pngImage = new Bitmap(FullFilename);
            Raw = new UInt32[pngImage.Width * pngImage.Height];
            Width = pngImage.Width;
            Height = pngImage.Height;

            var data = pngImage.LockBits(
                        new Rectangle(0, 0, pngImage.Width, pngImage.Height),
                        System.Drawing.Imaging.ImageLockMode.ReadWrite,
                        pngImage.PixelFormat);
                        //System.Drawing.Imaging.PixelFormat.Format32bppArgb);

            byte* pData = (byte*)data.Scan0;
            int index=0;
            for (int y = 0; y < pngImage.Height; y++)
            {
                for (int x = 0; x < pngImage.Width; x++)
                {
                    UInt32 col;
                    int ind = (y*data.Stride);
                    if( pngImage.PixelFormat== System.Drawing.Imaging.PixelFormat.Format24bppRgb )
                    {
                        ind += x*3;
                        col = 0xff000000 | ((UInt32)pData[ind] + (UInt32)(pData[ind+1]<<8) + (UInt32)(pData[ind+2]<<16));
                    }else{
                        ind += x*4;
                        col = (UInt32)pData[ind] + (UInt32)(pData[ind+1]<<8) + (UInt32)(pData[ind+2]<<16) + (UInt32)(pData[ind+3]<<24);
                    }
                    Raw[index++] = col;
                }
            }
            pngImage.UnlockBits(data);
        }


        // #############################################################################################
        /// Constructor: <summary>
        ///              	Save image to PNG file
        ///              </summary>
        /// In:		<param name="_filename">full path+filename</param>
        // #############################################################################################
        public unsafe void Save(string _filename)
        {
            FullFilename = _filename;
            Bitmap pngImage = null;
            // Now load the PNG and get the pixels from it....
            fixed (uint* pData = &Raw[0]){
                IntPtr data = (IntPtr)pData;

                pngImage = new Bitmap(Width, Height, Width * 4, System.Drawing.Imaging.PixelFormat.Format32bppArgb, data);
            }
            pngImage.Save(_filename);
        }

        // #############################################################################################
        /// Function:<summary>
        ///          	Show nicer debug info
        ///          </summary>
        // #############################################################################################
        public override string ToString()
        {
            return "w=" + Width.ToString() + ", h=" + Height.ToString();
        }
    }
}
