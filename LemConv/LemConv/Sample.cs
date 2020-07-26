// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Sample.cs
// Created:			25/07/2020
// Author:			Mike
// Project:			LemConv
// Description:		Loads Windows lemmings WAV files, and resamples them into the desired samplerate
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 25/07/2020		V1.0.0      MJD     1st version
// 
// **********************************************************************************************************************
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace LemConv
{
    class Sample
    {
        public const float TARGET_FREQ = (128 * 50);

        public byte[] sample;
        float freq;
        string filename;


        // ######################################################################################################
        /// <summary>
        ///     Create a new sample, and resample it
        /// </summary>
        // ######################################################################################################
        public Sample()
        {
        }

        // ######################################################################################################
        /// <summary>
        ///     Save the sample
        /// </summary>
        /// <param name="_path">Sample name to save</param>
        // ######################################################################################################
        public void Save(string _path)
        {
            if (sample == null) return;
            string name = Path.GetFileNameWithoutExtension(filename) + ".raw";
            name = Path.Combine(_path, name);
            try
            {
                try
                {
                    // if it's already there... delete it first
                    if (System.IO.File.Exists(name)){
                        System.IO.File.Delete(name);
                    }
                }catch
                { }

                // save new files
                System.IO.File.WriteAllBytes(name, sample);
            }catch(Exception ex)
            {
                MessageBox.Show("Error saving sample:  " + name + Environment.NewLine + ex.Message);
            }
        }
        // ######################################################################################################
        /// <summary>
        ///     Do a simple resample from whatever we've gotten in, to 6400Hz - which is our playback speed
        ///     
        ///     Howto resample delta step
        /// 
        ///                              OrgFREQ
        ///     stepdelta = samplesize / -------- * SampleSize
        ///                              NoteFreq
        /// </summary>
        // ######################################################################################################
        public void Resample()
        {
            if (sample == null) return;

            double delta = sample.Length / ((TARGET_FREQ / freq ) * sample.Length);
            int len = (int) (sample.Length / delta);
            byte[] Resampled = new byte[len];

            // simple resample
            double index = delta;
            double prev = 0;
            for(int i = 0; i < len; i++)
            {
                //byte b = (byte) (((int)sample[(int)index]+128)&0xff);         // use if we're going to "mix"
                byte b = sample[(int)index];                                    // use if we're not mixing
                Resampled[i] = b;
                prev = index;
                index += delta;
            }

            sample = Resampled;
        }


        // ######################################################################################################
        /// <summary>
        ///     Returns left and right double arrays. 'right' will be null if sound is mono. 
        /// </summary>
        /// <param name="_filename"></param>
        // ######################################################################################################
        public void ReadWav(string _filename)
        {
            filename = _filename;
            sample = null;

            try
            {
                using (FileStream fs = File.Open(_filename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    BinaryReader reader = new BinaryReader(fs);

                    // chunk 0
                    int chunkID = reader.ReadInt32();
                    int fileSize = reader.ReadInt32();
                    int riffType = reader.ReadInt32();


                    // chunk 1
                    int fmtID = reader.ReadInt32();
                    int fmtSize = reader.ReadInt32(); // bytes for this chunk (expect 16 or 18)

                    // 16 bytes coming...
                    int fmtCode = reader.ReadInt16();
                    int channels = reader.ReadInt16();
                    int sampleRate = reader.ReadInt32();
                    int byteRate = reader.ReadInt32();
                    int fmtBlockAlign = reader.ReadInt16();
                    int bitDepth = reader.ReadInt16();

                    if (fmtSize == 18)
                    {
                        // Read any extra values
                        int fmtExtraSize = reader.ReadInt16();
                        reader.ReadBytes(fmtExtraSize);
                    }

                    // chunk 2
                    int dataID = reader.ReadInt32();
                    int bytes = reader.ReadInt32();

                    // Sample data - always 8bit mono
                    sample = reader.ReadBytes(bytes);
                    freq = sampleRate;

                }
            }
            catch(Exception ex)
            {
                Console.WriteLine("Error: " + ex.Message);
            }
        }
    }
}