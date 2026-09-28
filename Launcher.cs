using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class Launcher {
 [STAThread]
 private static void Main() {
  try {
   string root=AppDomain.CurrentDomain.BaseDirectory;
   string script=Path.Combine(root,"Launch.ps1");
   if(!File.Exists(script))throw new FileNotFoundException("Launch.ps1 is missing.");
   var start=new ProcessStartInfo {
    FileName=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"),
    Arguments="-NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File \""+script+"\"",
    WorkingDirectory=root,
    UseShellExecute=false,
    CreateNoWindow=true,
    WindowStyle=ProcessWindowStyle.Hidden
   };
   using(var child=Process.Start(start)){}
  } catch(Exception error) {
   MessageBox.Show(error.Message,"ClassNote startup",MessageBoxButtons.OK,MessageBoxIcon.Error);
  }
 }
}
