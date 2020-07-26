// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Buffer.cs
// Created:			?????
// Author:			Mike
// Project:			LemConv
// Description:		image manipulation stuff, from my other graphics conversion tool
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// ?????    		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LemConv
{
    class BitmapConversion
    {


        // ####################################################################################################
        /// <summary>
        ///     Convert an image into a s256 image and save
        /// </summary>
        /// <param name="_img">Image to convert from</param>
        /// <param name="_img">inputname</param>
        // ####################################################################################################
        public static void Convert(Image _img, string _inputname,string _outputname)
        {
            int w = _img.Width;
            int h = _img.Height;

            byte[] image = new byte[w * h];
            int index = 0;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    uint col = _img[x, y];     
                    byte c = (byte) (( ((col & 0xe00000) >> 16) | ((col & 0xe000) >> 11) | ((col & 0xc0) >> 6) ) &0xff);
                    image[index++] = c;
                }
            }

            if (_outputname == null || _outputname == "")
            {
                _outputname = Path.ChangeExtension(_inputname, ".256");
            }
            File.WriteAllBytes(_outputname, image);
        }

        // ####################################################################################################
        /// <summary>
        ///     Search and rip all sprites in audo mode (detect sizes etc)
        /// </summary>
        /// <param name="_img">Image to grab from</param>
        // ####################################################################################################
        public static void Clamp(Image _img, string _inputname, string _outputname)
        {
            int w = _img.Width;
            int h = _img.Height;

            byte[] image = new byte[w * h];
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    uint col = _img[x, y] & 0xffe0e0c0;
                    _img[x, y] = col;
                }
            }

            if (_outputname == null || _outputname == "")
            {
                _outputname = Path.Combine(Path.GetDirectoryName(_inputname), Path.GetFileNameWithoutExtension(_inputname) + "_out.png");
            }
            _img.Save(_outputname);
            
        }



        // ####################################################################################################
        /// <summary>
        ///     Convert an image into a Stripped 256 image and save (column based)
        /// </summary>
        /// <param name="_img">Image to convert from</param>
        /// <param name="_img">inputname</param>
        // ####################################################################################################
        public static void StripConvert(Image _img, string _inputname, string _outputname)
        {
            int w = _img.Width;
            int h = _img.Height;

            byte[] image = new byte[h * w];
            int index = 0;
            for (int x = 0; x < w; x++)
            {
                for (int y = 0; y < h; y++)
                {
                    uint col = _img[x, y];
                    byte c = (byte)((((col & 0xe00000) >> 16) | ((col & 0xe000) >> 11) | ((col & 0xc0) >> 6)) & 0xff);
                    image[index++] = c;
                }
            }

            if (_outputname == null || _outputname == "")
            {
                _outputname = Path.ChangeExtension(_inputname, ".256");
            }
            File.WriteAllBytes(_outputname, image);
        }
    }
}
