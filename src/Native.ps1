# Native.ps1 — dot-sourced in Desktop.ps1 initialization order.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NoteNative {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool ReleaseCapture();
 [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h,int m,IntPtr w,IntPtr l);
}
"@
[void][NoteNative]::SetProcessDPIAware()
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing @"
using System;
using System.Drawing;
using System.Windows.Forms;
public class NoteCheck : CheckBox {
 public NoteCheck(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
 protected override void OnPaint(PaintEventArgs e){
  e.Graphics.Clear(BackColor);
  float z=e.Graphics.DpiX/96f; int d=(int)(17*z), x=(int)(2*z), y=(Height-d)/2;
  var color=Color.FromArgb(82,117,103);
  e.Graphics.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
  using(var pen=new Pen(color,1.4f*z)) e.Graphics.DrawEllipse(pen,x,y,d,d);
  if(Checked){
   using(var b=new SolidBrush(color))e.Graphics.FillEllipse(b,x,y,d,d);
   using(var pen=new Pen(Color.FromArgb(250,249,245),1.6f*z)){
    pen.StartCap=pen.EndCap=System.Drawing.Drawing2D.LineCap.Round;
    e.Graphics.DrawLines(pen,new PointF[]{new PointF(x+4*z,y+8*z),new PointF(x+7*z,y+11*z),new PointF(x+13*z,y+5*z)});
   }
  }
  var rect=new Rectangle((int)(29*z),0,Width-(int)(29*z),Height);
  TextRenderer.DrawText(e.Graphics,Text,Font,rect,ForeColor,TextFormatFlags.VerticalCenter|TextFormatFlags.WordBreak|TextFormatFlags.NoPrefix);
  if(Focused && ShowFocusCues)ControlPaint.DrawFocusRectangle(e.Graphics,rect,ForeColor,BackColor);
 }
 protected override void OnCheckedChanged(EventArgs e){base.OnCheckedChanged(e);Invalidate();}
}
public class ResizableNote : Form {
 public ResizableNote(){
  SetStyle(ControlStyles.ResizeRedraw|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);
  DoubleBuffered=true;
 }
 protected override void OnResize(EventArgs e){base.OnResize(e);Invalidate(true);}
 protected override void OnResizeEnd(EventArgs e){base.OnResizeEnd(e);Invalidate(true);Update();}
 public int Grip = 8;
 public bool UserResized = false;
 protected override void OnResizeBegin(EventArgs e){UserResized=true;base.OnResizeBegin(e);}
 public int EdgeAt(Point p) {
  bool l=p.X<Grip, r=p.X>=ClientSize.Width-Grip;
  bool t=p.Y<Grip, b=p.Y>=ClientSize.Height-Grip;
  if(t&&l)return 13; if(t&&r)return 14;
  if(b&&l)return 16; if(b&&r)return 17;
  if(l)return 10; if(r)return 11; if(t)return 12; if(b)return 15;
  return 1;
 }
 protected override void WndProc(ref Message m) {
  if(m.Msg==0x84) {
   long packed=m.LParam.ToInt64();
   var p=PointToClient(new Point((short)(packed&65535),(short)((packed>>16)&65535)));
   int edge=EdgeAt(p);
   if(edge!=1){m.Result=(IntPtr)edge;return;}
  }
  base.WndProc(ref m);
 }
}
"@
[Windows.Forms.Application]::EnableVisualStyles()
