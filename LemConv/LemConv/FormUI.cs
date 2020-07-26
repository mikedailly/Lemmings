using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace LemConv
{
    public partial class FormUI : Form
    {
        public FormUI()
        {
            InitializeComponent();
        }


        // ####################################################################################
        /// <summary>
        ///     GENERATE button clicked!
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        // ####################################################################################
        private void button3_Click(object sender, EventArgs e)
        {
            string srcf = SourceFolderBox.Text;
            if (!System.IO.Directory.Exists(srcf)){
                MessageBox.Show("Error: \"" + srcf + "\" does not exist");
                return;
            }

            string destf = DestFolderBox.Text;
            if( !System.IO.Directory.Exists(destf)){
                MessageBox.Show("Error: \"" + destf + "\" does not exist");
                return;
            }

            Program.WinLemPath = srcf;
            Program.DestFolder = destf;

            Program.ConvertResources();


        }
    }
}
