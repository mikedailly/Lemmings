// **********************************************************************************************************************
// 
// Copyright (c)2017-2020, Mike Dailly. All Rights reserved.
// 
// File:			Program.cs
// Created:			30/10/2017
// Author:			Mike
// Project:			LemConv
// Description:		Main graphics conversion. Takes Windows lemmings and converts it into the format
//                  and directory layout of Lemmings for the ZX Spectrum Next
// 
// Date				Version		BY		Comment
// ----------------------------------------------------------------------------------------------------------------------
// 30/10/2017		V1.0.0      MJD     1st version
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
    class Program
    {
        public const string LEMMING_FEFONT = "gfx\\FEFONT.SPR";

        public const string LEMMING_FILE = "gfx\\LEMMSMA.SPR";
        public const string LEVEL0_PAL = "styles\\LEVEL0.PAL";
        public const string LEVEL1_PAL = "styles\\LEVEL1.PAL";
        public const string LEVEL2_PAL = "styles\\LEVEL2.PAL";
        public const string LEVEL3_PAL = "styles\\LEVEL3.PAL";
        public const string LEVEL4_PAL = "styles\\LEVEL4.PAL";
        public const string FE_PAL     = "gfx\\FE.PAL";
        public const string STYLE_L0   = "styles\\LEVEL0s.spr";
        public const string STYLE_L1   = "styles\\LEVEL1s.spr";
        public const string STYLE_L2   = "styles\\LEVEL2s.spr";
        public const string STYLE_L3   = "styles\\LEVEL3s.spr";
        public const string STYLE_L4   = "styles\\LEVEL4s.spr";

        public const string STYLE_0Objs = "styles\\LEVEL0Os.spr";
        public const string STYLE_1Objs = "styles\\LEVEL1Os.spr";
        public const string STYLE_2Objs = "styles\\LEVEL2Os.spr";
        public const string STYLE_3Objs = "styles\\LEVEL3Os.spr";
        public const string STYLE_4Objs = "styles\\LEVEL4Os.spr";

        public const string STYLE_0DB = "styles\\GROUND0O.DAT";
        public const string STYLE_1DB = "styles\\GROUND1O.DAT";
        public const string STYLE_2DB = "styles\\GROUND2O.DAT";
        public const string STYLE_3DB = "styles\\GROUND3O.DAT";
        public const string STYLE_4DB = "styles\\GROUND4O.DAT";


        public const string SND_1 = "sound\\BANG.wav";
        public const string SND_2 = "sound\\CHAIN.wav";
        public const string SND_3 = "sound\\CHANGEOP.wav";
        public const string SND_4 = "sound\\CHINK.wav";
        public const string SND_5 = "sound\\DIE.wav";
        public const string SND_6 = "sound\\DOOR.wav";
        public const string SND_7 = "sound\\ELECTRIC.wav";
        public const string SND_8 = "sound\\EXPLODE.wav";
        public const string SND_9 = "sound\\FIRE.wav";
        public const string SND_10 = "sound\\GLUG.wav";
        public const string SND_11 = "sound\\LETSGO.wav";
        public const string SND_12 = "sound\\MANTRAP.wav";
        public const string SND_13 = "sound\\MOUSEPRE.wav";
        public const string SND_14 = "sound\\OHNO.wav";
        public const string SND_15 = "sound\\OING.wav";
        public const string SND_16 = "sound\\SCRAPE.wav";
        public const string SND_17 = "sound\\SLICER.wav";
        public const string SND_18 = "sound\\SPLASH.wav";
        public const string SND_19 = "sound\\SPLAT.wav";
        public const string SND_20 = "sound\\TENTON.wav";
        public const string SND_21 = "sound\\THUD.wav";
        public const string SND_22 = "sound\\THUNK.wav";
        public const string SND_23 = "sound\\TING.wav";
        public const string SND_24 = "sound\\YIPPEE.wav";

        public static FormUI form1;

        enum PalIndex
        {
            Level0,
            Level1,
            Level2,
            Level3,
            Level4,
            FE,
            Lemmings
        }

        /// <summary>The windows lemmings install location</summary>
        public static string WinLemPath = "";
        /// <summary>The NEXT data folder</summary>
        public static string DestFolder = "";

        /// <summary>Grabbed sprites</summary>
        public static List<Sprite> Sprites = new List<Sprite>();
        // game palettes
        public static List<Palette> pal = new List<Palette>();

        public static SPRLoader Lemmings;
        public static SPRLoader Style0;
        public static SPRLoader Style1;
        public static SPRLoader Style2;
        public static SPRLoader Style3;
        public static SPRLoader Style4;


        // ####################################################################################
        /// Function:   <summary>
        ///                 Parse all arguments
        ///             </summary>
        /// In:         <param name="_args">the argument array</param>
        // ####################################################################################
        public static void ParseArguments(string[] _args)
        {
            int i = 0;
            while (i < _args.Length)
            {
                string a = _args[i];
                switch (a)
                {
                    //case "-bmp": bBMP256Conv = true; break;         // convert BMP into 256 colour
                    //case "-png": bBMP256Clamp = true; break;        // clamp all colours to spec next colours
                    default:
                        WinLemPath = a;
                        break;
                }
                i++;
            }

        }




        // ####################################################################################
        /// <summary>
        ///     Check a file is there
        /// </summary>
        /// <param name="_name"></param>
        /// <returns></returns>
        // ####################################################################################
        static string CheckFile(string _name)
        {
            string filename = Path.Combine(WinLemPath, _name);
            if( File.Exists(filename))  return filename;

            MessageBox.Show("Error: Can't find " + filename);
            return null;
        }



        // ####################################################################################
        /// <summary>
        ///     Grab lemmings from the "lemmsma.spr" file
        /// </summary>
        /// <param name="_name"></param>
        /// <returns></returns>
        // ####################################################################################
        static void GrabLemmings()
        {
            SPRLoader.BankSize = 8192;
            string lemfile = CheckFile(LEMMING_FILE);
            if (lemfile == null) return;
            
            Lemmings = new SPRLoader(lemfile, pal[(int)PalIndex.FE]);
            Lemmings.SaveSprites(Path.Combine(DestFolder, "lemmings.spr"),true);
            //Lemmings.GenerateSimpleTextuepage(@"C:\source\ZXSpectrum\graphics\lemming_frames.png");

        }


        // ####################################################################################
        /// <summary>
        ///     Grab style files from the "lemmsma.spr" file
        /// </summary>
        /// <param name="_name"></param>
        /// <returns></returns>
        // ####################################################################################
        static void GrabStyles()
        {
            string stylefile;
            string Dest = Path.Combine(DestFolder, "styles");
            if (!CreateAFolder(Dest)) return;

            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_L0);
            if (stylefile == null) return;
            Style0 = new SPRLoader(stylefile, pal[(int)PalIndex.Level0]);
            Style0.SaveSprites(Path.Combine(Dest, "style0.spr"), false);
            //Style0.GenerateSimpleTextuepage(@"c:\temp\style0.png");

            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_0Objs);
            SPRLoader obj = new SPRLoader(stylefile, pal[(int)PalIndex.Level0]);
            obj.SaveSprites(Path.Combine(Dest, "style0o.spr"), false);
            //obj.GenerateSimpleTextuepage(@"c:\temp\style0o.png");




            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_L1);
            if (stylefile == null) return;
            Style1 = new SPRLoader(stylefile, pal[(int)PalIndex.Level1]);
            Style1.SaveSprites(Path.Combine(Dest, "style1.spr"),false);
            //Style1.GenerateSimpleTextuepage(@"c:\temp\style1.png");

            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_1Objs);
            obj = new SPRLoader(stylefile, pal[(int)PalIndex.Level1]);
            obj.SaveSprites(Path.Combine(Dest, "style1o.spr"), false);
            //obj.GenerateSimpleTextuepage(@"c:\temp\style1o.png");




            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_L2);
            if (stylefile == null) return;
            Style2 = new SPRLoader(stylefile, pal[(int)PalIndex.Level2]);
            Style2.SaveSprites(Path.Combine(Dest, "style2.spr"),false);
            //Style2.GenerateSimpleTextuepage(@"c:\temp\style2.png");

            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_2Objs);
            obj = new SPRLoader(stylefile, pal[(int)PalIndex.Level2]);
            obj.SaveSprites(Path.Combine(Dest, "style2o.spr"), false);
            //obj.GenerateSimpleTextuepage(@"c:\temp\style2obj.png");





            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_L3);
            if (stylefile == null) return;
            Style3 = new SPRLoader(stylefile, pal[(int)PalIndex.Level3]);
            Style3.SaveSprites(Path.Combine(Dest, "style3.spr"),false);
            //Style3.GenerateSimpleTextuepage(@"c:\temp\style3.png");

            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_3Objs);
            obj = new SPRLoader(stylefile, pal[(int)PalIndex.Level3]);
            obj.SaveSprites( Path.Combine(Dest, "style3o.spr"), false);
            //obj.GenerateSimpleTextuepage(@"c:\temp\style3o.png");





            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_L4);
            if (stylefile == null) return;
            Style4 = new SPRLoader(stylefile, pal[(int)PalIndex.Level4]);
            Style4.SaveSprites(Path.Combine(Dest, "style4.spr"),false);
            //Style4.GenerateSimpleTextuepage(@"c:\temp\style4.png");

            SPRLoader.BankSize = 8192;
            stylefile = CheckFile(STYLE_4Objs);
            obj = new SPRLoader(stylefile, pal[(int)PalIndex.Level4]);
            obj.SaveSprites(Path.Combine(Dest, "style4o.spr"), false);
            //obj.GenerateSimpleTextuepage(@"c:\temp\style4o.png");
        }


        // ####################################################################################
        /// <summary>
        ///     Grab lemmings from the "lemmsma.spr" file
        /// </summary>
        /// <param name="_name"></param>
        /// <returns></returns>
        // ####################################################################################
        static void LoadPalettes()
        {
            //string lemfile = CheckFile(LEMMING_FILE);
            //if (lemfile == null) return;

            string file = CheckFile(LEVEL0_PAL);
            if (file == null) return;
            pal.Add(new LemConv.Palette(file));

            file = CheckFile(LEVEL1_PAL);
            if (file == null) return;
            pal.Add(new LemConv.Palette(file));

            file = CheckFile(LEVEL2_PAL);
            if (file == null) return;
            pal.Add(new LemConv.Palette(file));

            file = CheckFile(LEVEL3_PAL);
            if (file == null) return;
            pal.Add(new LemConv.Palette(file));

            file = CheckFile(LEVEL4_PAL);
            if (file == null) return;
            pal.Add(new LemConv.Palette(file));

            file = CheckFile(FE_PAL);
            if (file == null) return;
            pal.Add(new LemConv.Palette(file));

            Palette lempal = new Palette(256);
            lempal[0x30] = 0xff5F63FF;
            lempal[0x31] = 0xff00B300;
            lempal[0x4b] = 0xffFFEBDF;
        }

        // ####################################################################################
        /// <summary>
        ///     Convert one the object database(s), and save it out
        ///     
        ///     ObjFlags        dw      various flags. behind =$8000, inside=$4000
        ///     ObjAnim         db      sprite index into the object sprite pool
        ///     ObjMax          db		max anim - offset from ObjAnim
        ///     ObjWidth        db      original sprite width - not cropped width
        ///     ObjHeight       db		original sprite height - not cropped width
        ///     ObjUnknown      ds 8    8 bytes unknown
        ///     ObjXCollOff     dw      X offset into collision map
        ///     ObjYCollOff     dw      Y offset into collision map
        ///     ObjCollWidth    db      number of 4x4 blocks wide
        ///     ObjCollHeight   db      number of 4x4 blocks high
        ///     ObjCollType     db      collision type
        ///     ObjUnknown      ds 6    who knows
        ///     ObjSound        db      sound effect to use
        ///     
        ///     Output:
        ///     ------
        ///         flags       db  $80|$40     behind,inside
        ///         anim        db  0           sprite index
        ///         animmax     db  0           max sprite index (sequential)
        ///         width       db  0           original sprite width
        ///         height      db  0           original sprite height
        ///         collwidth   db  0           collision width        
        ///         collheight  db  0           collision height
        ///         colltype    db  0           collision type
        ///         fx          db  0           sound fx
        ///         padding     ds  4           16 byte padding
        /// 
        /// </summary>
        // ####################################################################################
        static void ProcessOneDB(string _in, string _out)
        {            
            
            MemoryStreamEx src = new MemoryStreamEx(_in);
            MemoryStreamEx dest = new MemoryStreamEx();

            byte ObjectSprite = 0;
            // there are upto 16 object types in each level
            for(int i = 0; i < 16; i++)
            {
                // flags
                UInt16 f = src.Read16();
                dest.Write8((byte)(f >> 8));        // only care about the 2 flags

                // Animation start
                dest.Write8((byte)(ObjectSprite & 0xff));

                // starting frame
                byte a = (byte)(src.Read8()+ ObjectSprite);
                dest.Write8(a);
                // max frame
                a = (byte)(src.Read8()+((byte)ObjectSprite));
                dest.Write8(a);
                ObjectSprite = (byte) a;       // next sprites

                // width
                a = src.Read8();
                dest.Write8(a);
                // height
                a = src.Read8();
                dest.Write8(a);

                src.Read32();   // skip 12 bytes
                src.Read32();
                src.Read32();   

                // collision width,height off
                a = src.Read8();
                dest.Write8(a);
                a = src.Read8();
                dest.Write8(a);

                // collision type
                a = src.Read8();
                dest.Write8(a);

                // unknown 6 bytes
                src.Read32();
                src.Read16();

                // sound effect number
                a = src.Read8();
                dest.Write8(a);

                // padding
                for (int p = 0; p < 6; p++)
                {
                    dest.Write8(0);
                }

            }

            byte[] outfile = dest.ToArray();
            File.WriteAllBytes(_out, outfile);
        }


        // ####################################################################################
        /// <summary>
        ///     Convert the object database(s).
        /// </summary>
        // ####################################################################################
        static void ConvertObjectDB()
        {
            string name;
            string dest = Path.Combine(DestFolder, "styles");

            name = CheckFile(STYLE_0DB);
            if (name != null) ProcessOneDB(name, Path.Combine(dest,"style0.dat"));
            name = CheckFile(STYLE_1DB);
            if (name != null) ProcessOneDB(name, Path.Combine(dest, "style1.dat"));
            name = CheckFile(STYLE_2DB);
            if (name != null) ProcessOneDB(name, Path.Combine(dest, "style2.dat"));
            name = CheckFile(STYLE_3DB);
            if (name != null) ProcessOneDB(name, Path.Combine(dest, "style3.dat"));
            name = CheckFile(STYLE_4DB);
            if (name != null) ProcessOneDB(name, Path.Combine(dest, "style4.dat"));
        }


        // ####################################################################################
        /// <summary>
        ///     Copy all the levels into the correct location
        /// </summary>
        // ####################################################################################
        static public void CopyAllLevels()
        {
            string src = Path.Combine(WinLemPath, "level/ORIG");
            string dest = Path.Combine(DestFolder, "levels");
            if (!CreateAFolder(dest)) return;

            string[] lst = System.IO.Directory.GetFiles(src,"*.lvl");
            foreach(string filename in lst)
            {
                try
                {
                    string dest_name = Path.GetFileName(filename);
                    dest_name = Path.Combine(dest, dest_name);
                    if (System.IO.File.Exists(dest_name))
                    {
                        System.IO.File.Delete(dest_name);
                    }

                    System.IO.File.Copy(filename, dest_name);
                    System.IO.File.SetAttributes(dest_name, FileAttributes.Normal);
                }catch(Exception ex)
                {
                    MessageBox.Show("Error: copying level '" + filename + "'."+Environment.NewLine+ex.Message);
                }

            }
        }

        // ####################################################################################
        /// <summary>
        ///     Create a folder or display an error if we can't
        /// </summary>
        /// <param name="_folder"></param>
        // ####################################################################################
        public static bool CreateAFolder(string _folder)
        {
            if (!Directory.Exists(_folder))
            {
                try
                {
                    Directory.CreateDirectory(_folder);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Error creating Directory: " + _folder);
                    return false;
                }
            }
            return true;
        }
        // ####################################################################################
        /// <summary>
        ///     Convert all Windows Lemmings sounds into 6400Hz
        /// </summary>
        // ####################################################################################
        public static void CovertSound()
        {
            string dest_path = Path.Combine(DestFolder, "sound");
            if (!CreateAFolder(dest_path)) return;

            string[] files = { SND_1, SND_2, SND_3, SND_4, SND_5, SND_6, SND_7, SND_8, SND_9,
                               SND_10, SND_11, SND_12, SND_13, SND_14, SND_15, SND_16, SND_17,
                               SND_18, SND_19,SND_20, SND_21, SND_22, SND_23, SND_24};

            Sample sp = new Sample();
            foreach (string name in files)
            {
                string src_file = Path.Combine(WinLemPath, name);
                string wav_filename = CheckFile(src_file);
                if (wav_filename != null) {
                    sp.ReadWav(wav_filename);
                    sp.Resample();
                    sp.Save(dest_path);                
                }
            }
        }

        // ####################################################################################
        /// <summary>
        ///     Convert all resources
        /// </summary>
        // ####################################################################################
        static public void ConvertResources()
        {
            // Convert all samples
            CovertSound();

            // Load palette files
            LoadPalettes();

            // Grab lemming graphics
            GrabStyles();

            // Grab lemming graphics
            GrabLemmings();

            // Read object database
            ConvertObjectDB();

            // Copy levels
            CopyAllLevels();


            MessageBox.Show("Done");
        }

        // ####################################################################################
        /// Function:   <summary>
        ///                 Main loop
        ///             </summary>
        /// In:         <param name="_args">the argument array</param>
        // ####################################################################################
        [STAThread]
        static void Main(string[] _args)
        {
            WinLemPath = @"C:\source\ZXSpectrum\Lemmings\win95lem\win95m";

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            form1 = new FormUI();
            Application.Run(form1);


        }
    }
}
