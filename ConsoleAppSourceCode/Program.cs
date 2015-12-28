using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using streetsharksconsoleapp;

namespace streetsharksconsoleapp
{
    class Program
    {
        static void Main(string[] args)
        {
            Execute();
        }

        private static void Execute()
        {
            StreetSharksConnection db = new StreetSharksConnection();
            db.openConnection();
            db.printMenuReadInput();
        }
    }
}
