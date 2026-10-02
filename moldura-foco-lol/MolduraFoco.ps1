# Moldura de Foco para League of Legends
#
# Desenha uma moldura fixa no centro da janela do jogo (ou da tela) para
# ajudar a não perder o seu campeão de vista. Funciona com a câmera travada.
# A moldura é só um desenho por cima da tela: não lê nem altera nada do jogo
# e deixa os cliques do mouse passarem direto para o jogo.
#
# Para abrir, dê dois cliques em "Iniciar Moldura.bat".

$codigo = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using WinTimer = System.Windows.Forms.Timer;

namespace MolduraFoco
{
    public static class Program
    {
        public static void Run()
        {
            bool primeiraInstancia;
            using (System.Threading.Mutex mutex = new System.Threading.Mutex(true, "MolduraFocoLoL_InstanciaUnica", out primeiraInstancia))
            {
                if (!primeiraInstancia)
                {
                    MessageBox.Show("A Moldura de Foco já está aberta.\n\nProcure o ícone dela perto do relógio do Windows.",
                        "Moldura de Foco", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                // Trabalha em pixels reais, mesmo com a escala do Windows em 125% ou 150%.
                try { Native.SetProcessDPIAware(); } catch { }

                Application.EnableVisualStyles();
                Application.ThreadException += (s, e) =>
                    MessageBox.Show("Ocorreu um erro:\n\n" + e.Exception.Message, "Moldura de Foco",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);

                using (FocusApp app = new FocusApp())
                {
                    Application.Run(app);
                }
            }
        }
    }

    internal static class Native
    {
        public const int WM_HOTKEY = 0x0312;
        public const uint MOD_ALT = 0x0001;
        public const uint MOD_CONTROL = 0x0002;
        public const uint MOD_NOREPEAT = 0x4000;

        public const int WS_EX_TOPMOST = 0x00000008;
        public const int WS_EX_TRANSPARENT = 0x00000020;
        public const int WS_EX_TOOLWINDOW = 0x00000080;
        public const int WS_EX_LAYERED = 0x00080000;
        public const int WS_EX_NOACTIVATE = 0x08000000;

        public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        public const uint SWP_NOSIZE = 0x0001;
        public const uint SWP_NOMOVE = 0x0002;
        public const uint SWP_NOACTIVATE = 0x0010;

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left, Top, Right, Bottom; }

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT { public int X, Y; }

        [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
        [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint vk);
        [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string className, string windowName);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
        [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
        [DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr hIcon);
    }

    internal static class Palette
    {
        public static readonly string[] ShapeNames = { "Cantoneiras (moldura de câmera)", "Círculo", "Quadrado", "Seta acima da cabeça" };

        // Vermelho ficou de fora de propósito: no LoL ele indica inimigos.
        public static readonly string[] ColorNames = { "Amarelo", "Ciano", "Verde-limão", "Rosa-choque", "Laranja", "Branco", "Roxo" };
        public static readonly Color[] Colors =
        {
            Color.FromArgb(255, 230, 0),
            Color.FromArgb(0, 229, 255),
            Color.FromArgb(118, 255, 3),
            Color.FromArgb(255, 64, 200),
            Color.FromArgb(255, 145, 0),
            Color.FromArgb(255, 255, 255),
            Color.FromArgb(180, 110, 255)
        };

        public static readonly string[] ThicknessNames = { "Fina", "Média", "Grossa" };
        public static readonly int[] ThicknessAt1080p = { 2, 4, 7 };

        public static readonly int[] OpacityLevels = { 100, 85, 70, 50 };
    }

    // Tamanho e posição são guardados como fração da altura da tela, porque o
    // campeão aparece maior ou menor conforme a resolução do jogo.
    // Há uma posição para cada lado do mapa: com a câmera em "contrapeso por
    // lado" o campeão fica num ponto diferente da tela no lado azul e no vermelho.
    internal sealed class Settings
    {
        public const double DefaultSize = 0.065;
        public const double DefaultOffsetX = 0.0;
        public const double DefaultOffsetY = -0.025;

        public bool OnlyInGame = false;
        public bool HideWhenDead = true;
        public int Shape = 0;
        public int ColorIndex = 0;
        public double Size = DefaultSize;
        public double[] OffsetX = { DefaultOffsetX, DefaultOffsetX };
        public double[] OffsetY = { DefaultOffsetY, DefaultOffsetY };
        public int Thickness = 1;
        public int Opacity = 85;
        public bool Pulse = false;
        public int Monitor = -1;
        public bool Follow = false;
        public BarModel Bar = null;

        static string Folder
        {
            get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "MolduraFocoLoL"); }
        }

        static string FilePath
        {
            get { return Path.Combine(Folder, "config.txt"); }
        }

        public static Settings Load()
        {
            Settings s = new Settings();
            bool hasRed = false;
            try
            {
                if (!File.Exists(FilePath)) return s;
                foreach (string line in File.ReadAllLines(FilePath))
                {
                    int eq = line.IndexOf('=');
                    if (eq <= 0) continue;
                    string key = line.Substring(0, eq).Trim();
                    string value = line.Substring(eq + 1).Trim();
                    switch (key)
                    {
                        case "OnlyInGame": s.OnlyInGame = value == "1"; break;
                        case "Shape": s.Shape = ReadInt(value, s.Shape, 0, Palette.ShapeNames.Length - 1); break;
                        case "Color": s.ColorIndex = ReadInt(value, s.ColorIndex, 0, Palette.Colors.Length - 1); break;
                        case "Size": s.Size = ReadDouble(value, s.Size, 0.02, 0.3); break;
                        case "HideWhenDead": s.HideWhenDead = value == "1"; break;
                        case "OffsetX": s.OffsetX[0] = ReadDouble(value, s.OffsetX[0], -0.45, 0.45); break;
                        case "OffsetY": s.OffsetY[0] = ReadDouble(value, s.OffsetY[0], -0.45, 0.45); break;
                        case "RedOffsetX": s.OffsetX[1] = ReadDouble(value, s.OffsetX[1], -0.45, 0.45); hasRed = true; break;
                        case "RedOffsetY": s.OffsetY[1] = ReadDouble(value, s.OffsetY[1], -0.45, 0.45); hasRed = true; break;
                        case "Thickness": s.Thickness = ReadInt(value, s.Thickness, 0, Palette.ThicknessAt1080p.Length - 1); break;
                        case "Opacity": s.Opacity = ReadInt(value, s.Opacity, 20, 100); break;
                        case "Pulse": s.Pulse = value == "1"; break;
                        case "Monitor": s.Monitor = ReadInt(value, s.Monitor, -1, 16); break;
                        case "Follow": s.Follow = value == "1"; break;
                        default:
                            if (key.StartsWith("Bar")) ReadBar(s, key, value);
                            break;
                    }
                }
            }
            catch
            {
                // Arquivo de configuração estragado: segue com os valores padrão.
            }

            // Configuração da versão anterior, com uma posição só: vale para os dois lados.
            if (!hasRed)
            {
                s.OffsetX[1] = s.OffsetX[0];
                s.OffsetY[1] = s.OffsetY[0];
            }
            return s;
        }

        public void Save()
        {
            try
            {
                CultureInfo inv = CultureInfo.InvariantCulture;
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("OnlyInGame=" + (OnlyInGame ? "1" : "0"));
                sb.AppendLine("Shape=" + Shape.ToString(inv));
                sb.AppendLine("Color=" + ColorIndex.ToString(inv));
                sb.AppendLine("Size=" + Size.ToString("0.0000", inv));
                sb.AppendLine("HideWhenDead=" + (HideWhenDead ? "1" : "0"));
                sb.AppendLine("OffsetX=" + OffsetX[0].ToString("0.0000", inv));
                sb.AppendLine("OffsetY=" + OffsetY[0].ToString("0.0000", inv));
                sb.AppendLine("RedOffsetX=" + OffsetX[1].ToString("0.0000", inv));
                sb.AppendLine("RedOffsetY=" + OffsetY[1].ToString("0.0000", inv));
                sb.AppendLine("Thickness=" + Thickness.ToString(inv));
                sb.AppendLine("Opacity=" + Opacity.ToString(inv));
                sb.AppendLine("Pulse=" + (Pulse ? "1" : "0"));
                sb.AppendLine("Monitor=" + Monitor.ToString(inv));
                sb.AppendLine("Follow=" + (Follow ? "1" : "0"));
                if (Bar != null && Bar.Valid)
                {
                    sb.AppendLine("BarColor=" + Bar.R.ToString(inv) + "," + Bar.G.ToString(inv) + "," + Bar.B.ToString(inv));
                    sb.AppendLine("BarTolerance=" + Bar.Tolerance.ToString(inv));
                    sb.AppendLine("BarHeight=" + Bar.Height.ToString("0.000000", inv));
                    sb.AppendLine("BarWidth=" + Bar.Width.ToString("0.000000", inv));
                    sb.AppendLine("BarOffsetX=" + Bar.OffsetX.ToString("0.000000", inv));
                    sb.AppendLine("BarOffsetY=" + Bar.OffsetY.ToString("0.000000", inv));
                    sb.AppendLine("BarEdges=" + Bar.EdgeAbove.ToString(inv) + "," + Bar.EdgeBelow.ToString(inv) + "," + Bar.EdgeLeft.ToString(inv));
                }
                Directory.CreateDirectory(Folder);
                File.WriteAllText(FilePath, sb.ToString());
            }
            catch
            {
                // Não conseguir salvar não deve fechar a moldura.
            }
        }

        static void ReadBar(Settings s, string key, string value)
        {
            if (s.Bar == null) s.Bar = new BarModel();
            BarModel b = s.Bar;
            switch (key)
            {
                case "BarColor":
                    string[] parts = value.Split(',');
                    if (parts.Length == 3)
                    {
                        b.R = ReadInt(parts[0], 0, 0, 255);
                        b.G = ReadInt(parts[1], 0, 0, 255);
                        b.B = ReadInt(parts[2], 0, 0, 255);
                    }
                    break;
                case "BarTolerance": b.Tolerance = ReadInt(value, b.Tolerance, 20, 200); break;
                case "BarHeight": b.Height = ReadDouble(value, 0, 0, 0.05); break;
                case "BarWidth": b.Width = ReadDouble(value, 0, 0, 0.5); break;
                case "BarOffsetX": b.OffsetX = ReadDouble(value, 0, -0.5, 0.5); break;
                case "BarOffsetY": b.OffsetY = ReadDouble(value, 0, -0.5, 0.5); break;
                case "BarEdges":
                    string[] edges = value.Split(',');
                    if (edges.Length == 3)
                    {
                        b.EdgeAbove = ReadInt(edges[0], -1, -1, 255);
                        b.EdgeBelow = ReadInt(edges[1], -1, -1, 255);
                        b.EdgeLeft = ReadInt(edges[2], -1, -1, 255);
                    }
                    break;
            }
        }

        static int ReadInt(string text, int fallback, int min, int max)
        {
            int v;
            if (!int.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out v)) return fallback;
            return Math.Max(min, Math.Min(max, v));
        }

        static double ReadDouble(string text, double fallback, double min, double max)
        {
            double v;
            if (!double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out v)) return fallback;
            return Math.Max(min, Math.Min(max, v));
        }
    }

    internal static class Shapes
    {
        public const int Corners = 0;
        public const int Circle = 1;
        public const int Square = 2;
        public const int Arrow = 3;

        public static GraphicsPath Build(int shape, float cx, float cy, float r)
        {
            GraphicsPath p = new GraphicsPath();
            switch (shape)
            {
                case Circle:
                    p.AddEllipse(cx - r, cy - r, 2 * r, 2 * r);
                    break;

                case Square:
                {
                    float d = r * 0.4f;
                    float x = cx - r, y = cy - r, w = 2 * r;
                    p.AddArc(x, y, d, d, 180, 90);
                    p.AddArc(x + w - d, y, d, d, 270, 90);
                    p.AddArc(x + w - d, y + w - d, d, d, 0, 90);
                    p.AddArc(x, y + w - d, d, d, 90, 90);
                    p.CloseFigure();
                    break;
                }

                case Arrow:
                {
                    float tipY = cy - r * 1.3f, height = r * 0.45f, halfWidth = r * 0.28f;
                    p.AddPolygon(new PointF[]
                    {
                        new PointF(cx - halfWidth, tipY - height),
                        new PointF(cx + halfWidth, tipY - height),
                        new PointF(cx, tipY)
                    });
                    break;
                }

                default:
                {
                    float len = r * 0.42f;
                    float x0 = cx - r, y0 = cy - r, x1 = cx + r, y1 = cy + r;
                    AddCorner(p, x0, y0 + len, x0, y0, x0 + len, y0);
                    AddCorner(p, x1 - len, y0, x1, y0, x1, y0 + len);
                    AddCorner(p, x1, y1 - len, x1, y1, x1 - len, y1);
                    AddCorner(p, x0 + len, y1, x0, y1, x0, y1 - len);
                    break;
                }
            }
            return p;
        }

        static void AddCorner(GraphicsPath p, float ax, float ay, float bx, float by, float cx, float cy)
        {
            p.StartFigure();
            p.AddLines(new PointF[] { new PointF(ax, ay), new PointF(bx, by), new PointF(cx, cy) });
        }

        public static void Draw(Graphics g, int shape, float cx, float cy, float r, float thickness, Color color)
        {
            using (GraphicsPath path = Build(shape, cx, cy, r))
            using (Pen outline = new Pen(Color.Black, thickness + 4f))
            using (Pen pen = new Pen(color, thickness))
            {
                // O contorno preto mantém a moldura visível tanto na grama quanto no rio.
                outline.LineJoin = LineJoin.Round;
                outline.StartCap = outline.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
                pen.StartCap = pen.EndCap = LineCap.Round;

                g.DrawPath(outline, path);
                if (shape == Arrow)
                {
                    using (Brush fill = new SolidBrush(color)) g.FillPath(fill, path);
                }
                else
                {
                    g.DrawPath(pen, path);
                }
            }
        }
    }

    // Janela transparente, sempre por cima, que não recebe cliques nem foco.
    internal sealed class OverlayForm : Form
    {
        static readonly Color KeyColor = Color.FromArgb(1, 2, 3);

        readonly Settings settings;
        float radius = 70f;
        float thickness = 4f;
        float fontSize = 17f;
        string message;
        Color messageColor;
        int messageUntil;
        bool messageShown;

        public OverlayForm(Settings settings)
        {
            this.settings = settings;
            Text = "Moldura de Foco";
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            StartPosition = FormStartPosition.Manual;
            TopMost = true;
            BackColor = KeyColor;
            TransparencyKey = KeyColor;
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint, true);
        }

        protected override bool ShowWithoutActivation
        {
            get { return true; }
        }

        protected override CreateParams CreateParams
        {
            get
            {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= Native.WS_EX_LAYERED | Native.WS_EX_TRANSPARENT | Native.WS_EX_TOOLWINDOW
                            | Native.WS_EX_NOACTIVATE | Native.WS_EX_TOPMOST;
                return cp;
            }
        }

        // Aviso curto escrito embaixo da moldura (as notificações do Windows
        // costumam ficar escondidas enquanto se joga).
        public void ShowMessage(string text, Color color)
        {
            message = text;
            messageColor = color;
            messageUntil = Environment.TickCount + 2500;
        }

        public bool HasMessage
        {
            get { return message != null && unchecked(Environment.TickCount - messageUntil) < 0; }
        }

        // Centraliza a moldura em (cx, cy). Só redesenha quando algo mudou.
        public void Place(Rectangle area, int cx, int cy, bool repaint)
        {
            float h = area.Height;
            float newRadius = Math.Max(10f, (float)(settings.Size * h));
            float newThickness = Math.Max(2f, (float)Math.Round(Palette.ThicknessAt1080p[settings.Thickness] * h / 1080f));
            bool withMessage = HasMessage;
            if (newRadius != radius || newThickness != thickness || withMessage != messageShown) repaint = true;
            radius = newRadius;
            thickness = newThickness;
            messageShown = withMessage;
            fontSize = Math.Max(13f, h * 0.016f);

            int half = (int)Math.Ceiling(radius * 1.9f + thickness * 2 + 6);
            if (withMessage) half = Math.Max(half, (int)Math.Ceiling(Math.Max(radius * 1.3f + fontSize * 2.2f, fontSize * 9f)));
            Rectangle bounds = new Rectangle(cx - half, cy - half, half * 2, half * 2);
            if (Bounds.Size != bounds.Size) repaint = true;
            if (Bounds != bounds) Bounds = bounds;
            if (repaint) Invalidate();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.Clear(KeyColor);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            float cx = ClientSize.Width / 2f, cy = ClientSize.Height / 2f;
            Shapes.Draw(g, settings.Shape, cx, cy, radius, thickness, Palette.Colors[settings.ColorIndex]);

            if (messageShown && message != null)
            {
                using (GraphicsPath text = new GraphicsPath())
                using (StringFormat format = new StringFormat())
                using (Pen outline = new Pen(Color.Black, Math.Max(3f, fontSize / 4f)))
                using (Brush fill = new SolidBrush(messageColor))
                {
                    format.Alignment = StringAlignment.Center;
                    text.AddString(message, FontFamily.GenericSansSerif, (int)FontStyle.Bold, fontSize,
                        new PointF(cx, cy + radius * 1.3f), format);
                    outline.LineJoin = LineJoin.Round;
                    g.DrawPath(outline, text);
                    g.FillPath(fill, text);
                }
            }
        }
    }

    // Consulta a API oficial que o próprio LoL abre no computador durante a
    // partida (https://127.0.0.1:2999/liveclientdata). Ela informa o time de
    // cada jogador e se ele está morto, mas não a posição do campeão na tela.
    internal sealed class LiveGame
    {
        public const int NoGame = -1;
        public const int Blue = 0;
        public const int Red = 1;

        volatile int side = NoGame;
        volatile bool dead;
        volatile bool running;
        readonly JavaScriptSerializer json = new JavaScriptSerializer();

        public int Side { get { return side; } }
        public bool Dead { get { return dead; } }

        public void Start()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            running = true;
            Thread thread = new Thread(Loop);
            thread.IsBackground = true;
            thread.Start();
        }

        public void Stop()
        {
            running = false;
        }

        void Loop()
        {
            while (running)
            {
                try
                {
                    Poll();
                }
                catch
                {
                    // Sem partida em andamento a API simplesmente não responde.
                    side = NoGame;
                    dead = false;
                }
                Thread.Sleep(side == NoGame ? 3000 : 1000);
            }
        }

        void Poll()
        {
            string me = json.DeserializeObject(Get("activeplayername")) as string;
            object[] players = json.DeserializeObject(Get("playerlist")) as object[];
            Dictionary<string, object> mine = FindPlayer(players, me, true) ?? FindPlayer(players, me, false);
            if (mine == null)
            {
                side = NoGame;
                dead = false;
                return;
            }
            side = Text(mine, "team") == "CHAOS" ? Red : Blue;
            object isDead;
            dead = mine.TryGetValue("isDead", out isDead) && isDead is bool && (bool)isDead;
        }

        static Dictionary<string, object> FindPlayer(object[] players, string me, bool exact)
        {
            if (players == null || string.IsNullOrEmpty(me)) return null;
            foreach (object item in players)
            {
                Dictionary<string, object> p = item as Dictionary<string, object>;
                if (p == null) continue;
                string[] names = { Text(p, "riotId"), Text(p, "summonerName"), Text(p, "riotIdGameName") };
                foreach (string name in names)
                {
                    if (string.IsNullOrEmpty(name)) continue;
                    if (exact ? SameText(name, me) : SameText(BeforeTag(name), BeforeTag(me))) return p;
                }
            }
            return null;
        }

        static string Text(Dictionary<string, object> p, string key)
        {
            object v;
            return p.TryGetValue(key, out v) ? v as string : null;
        }

        static string BeforeTag(string name)
        {
            int hash = name.IndexOf('#');
            return hash >= 0 ? name.Substring(0, hash) : name;
        }

        static bool SameText(string a, string b)
        {
            return string.Equals(a.Trim(), b.Trim(), StringComparison.OrdinalIgnoreCase);
        }

        static string Get(string path)
        {
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create("https://127.0.0.1:2999/liveclientdata/" + path);
            request.Proxy = null;
            request.Timeout = 1500;
            request.ReadWriteTimeout = 1500;
            // O jogo usa um certificado próprio da Riot; como o endereço é o do
            // próprio computador (127.0.0.1), aceitar esse certificado é seguro.
            request.ServerCertificateValidationCallback = delegate { return true; };
            using (WebResponse response = request.GetResponse())
            using (StreamReader reader = new StreamReader(response.GetResponseStream(), Encoding.UTF8))
            {
                return reader.ReadToEnd();
            }
        }
    }

    // O que a moldura aprendeu sobre a barra de vida do seu campeão. As medidas
    // são frações da altura da área do jogo, para valer em qualquer resolução.
    internal sealed class BarModel
    {
        public int R, G, B;
        public int Tolerance = 75;
        public double Height, Width;     // espessura e largura (com vida cheia) da parte colorida
        public double OffsetX, OffsetY;  // do canto superior esquerdo da barra até o centro da moldura
        // Tom (0 a 255) da moldura escura em volta da barra: em cima, embaixo e à esquerda
        // (onde fica o quadradinho do nível). -1 quando não há borda escura para conferir.
        public int EdgeAbove = -1, EdgeBelow = -1, EdgeLeft = -1;

        public bool Valid
        {
            get { return Height > 0 && Width > 0; }
        }

        public BarModel Clone()
        {
            return (BarModel)MemberwiseClone();
        }
    }

    internal struct BarHit
    {
        public int X, Y, Length;
    }

    // Procura a barra de vida numa imagem da tela (4 bytes por pixel: azul, verde, vermelho, alfa).
    // A busca usa o canto esquerdo da barra, que não sai do lugar quando a vida diminui.
    internal static class BarFinder
    {
        const int MaxGap = 2;          // os risquinhos da barra (a cada 100 de vida) têm 1 ou 2 pixels
        const int EdgeTolerance = 30;  // diferença de tom aceita na moldura escura da barra
        const int DarkEdge = 70;       // abaixo disso o tom conta como moldura escura

        public static bool Matches(byte[] px, int i, BarModel m)
        {
            int d = Math.Abs(px[i + 2] - m.R) + Math.Abs(px[i + 1] - m.G) + Math.Abs(px[i] - m.B);
            return d <= m.Tolerance;
        }

        static int Luma(byte[] px, int i)
        {
            return (px[i + 2] * 3 + px[i + 1] * 6 + px[i]) / 10;
        }

        static bool IsDark(byte[] px, int i)
        {
            return Luma(px, i) < 60;
        }

        static bool IsVivid(byte[] px, int i)
        {
            int max = Math.Max(px[i + 2], Math.Max(px[i + 1], px[i]));
            int min = Math.Min(px[i + 2], Math.Min(px[i + 1], px[i]));
            return max >= 110 && max - min >= 70;
        }

        static bool Close(byte[] px, int i, int j, int tolerance)
        {
            return Math.Abs(px[i] - px[j]) + Math.Abs(px[i + 1] - px[j + 1]) + Math.Abs(px[i + 2] - px[j + 2]) <= tolerance;
        }

        // Encontra a barra mais próxima de (expectedX, expectedY), o canto onde ela deveria estar.
        // 'tracking' indica que a barra estava ali no quadro anterior. Barras cujo canto cai em
        // 'skip' são ignoradas (painel de baixo e minimapa, que também têm barras verdes).
        public static bool Find(byte[] px, int stride, int w, int h, BarModel m, double areaHeight,
                                int expectedX, int expectedY, bool tracking, Rectangle skip, out BarHit best)
        {
            best = new BarHit();
            int barH = Math.Max(2, (int)Math.Round(m.Height * areaHeight));
            int barW = Math.Max(8, (int)Math.Round(m.Width * areaHeight));
            // Com pouca vida sobra só um pedacinho colorido. Se a moldura escura em volta foi
            // aprendida (em cima, embaixo e à esquerda), até 2 pixels bastam para reconhecer a barra.
            bool strongEdges = m.EdgeAbove >= 0 && m.EdgeBelow >= 0 && m.EdgeLeft >= 0;
            int minLen = strongEdges ? 2 : Math.Max(4, barW / 12);
            int maxLen = barW * 5 / 2;
            int near = Math.Max(8, (int)(areaHeight * 0.035));
            int heightTolerance = Math.Max(2, barH * 35 / 100);
            int rowStep = barH >= 5 ? 2 : 1;
            long bestScore = long.MaxValue;
            bool found = false;

            for (int y = 1; y < h - 1; y += rowStep)
            {
                int row = y * stride;
                int x = 0;
                while (x < w)
                {
                    if (!Matches(px, row + x * 4, m)) { x++; continue; }
                    int start = x, last = x, gap = 0;
                    for (x = x + 1; x < w; x++)
                    {
                        if (Matches(px, row + x * 4, m)) { last = x; gap = 0; }
                        else if (++gap > MaxGap) break;
                    }
                    x = last + 1;

                    int len = last - start + 1;
                    if (len > maxLen) continue;
                    bool nearExpected = tracking && Math.Abs(start - expectedX) <= near
                                        && Math.Abs(y - expectedY - barH / 2) <= near;
                    if (len < minLen && !(nearExpected && len >= 2)) continue;
                    if (skip.Contains(start, y)) continue;

                    int top, bottom;
                    VerticalExtent(px, stride, h, m, start, last, y, out top, out bottom);
                    if (Math.Abs(bottom - top + 1 - barH) > heightTolerance) continue;
                    if (!EdgeMatches(m.EdgeAbove, EdgeRow(px, stride, h, start, last, top - 1, top - 2))) continue;
                    if (!EdgeMatches(m.EdgeBelow, EdgeRow(px, stride, h, start, last, bottom + 1, bottom + 2))) continue;
                    if (!EdgeMatches(m.EdgeLeft, EdgeColumn(px, stride, w, start, top, bottom))) continue;

                    long dx = start - expectedX, dy = top - expectedY;
                    long score = dx * dx + dy * dy;
                    if (score < bestScore)
                    {
                        bestScore = score;
                        best.X = start;
                        best.Y = top;
                        best.Length = len;
                        found = true;
                    }
                }
            }
            return found;
        }

        static void VerticalExtent(byte[] px, int stride, int h, BarModel m, int start, int last, int y,
                                   out int top, out int bottom)
        {
            // Mede em três colunas e fica com a maior, porque um risquinho pode cortar uma delas.
            top = y;
            bottom = y;
            ExtendColumn(px, stride, h, m, start, y, ref top, ref bottom);
            ExtendColumn(px, stride, h, m, (start + last) / 2, y, ref top, ref bottom);
            ExtendColumn(px, stride, h, m, last, y, ref top, ref bottom);
        }

        static void ExtendColumn(byte[] px, int stride, int h, BarModel m, int c, int y, ref int top, ref int bottom)
        {
            if (!Matches(px, y * stride + c * 4, m)) return;
            int t = y, b = y;
            while (t > 0 && Matches(px, (t - 1) * stride + c * 4, m)) t--;
            while (b < h - 1 && Matches(px, (b + 1) * stride + c * 4, m)) b++;
            if (t < top) top = t;
            if (b > bottom) bottom = b;
        }

        static bool EdgeMatches(int learned, int seen)
        {
            return learned < 0 || seen < 0 || Math.Abs(seen - learned) <= EdgeTolerance;
        }

        // Tom da moldura logo acima (ou abaixo) da barra: o mais escuro entre as duas linhas
        // vizinhas, medido em três colunas, ficando com o do meio. -1 se sair da imagem.
        static int EdgeRow(byte[] px, int stride, int h, int start, int last, int y1, int y2)
        {
            if (y1 < 0 || y1 >= h || y2 < 0 || y2 >= h) return -1;
            int a = Math.Min(Luma(px, y1 * stride + start * 4), Luma(px, y2 * stride + start * 4));
            int mid = (start + last) / 2;
            int b = Math.Min(Luma(px, y1 * stride + mid * 4), Luma(px, y2 * stride + mid * 4));
            int c = Math.Min(Luma(px, y1 * stride + last * 4), Luma(px, y2 * stride + last * 4));
            return Median(a, b, c);
        }

        // Tom logo à esquerda da barra (quadradinho do nível), em três alturas.
        static int EdgeColumn(byte[] px, int stride, int w, int start, int top, int bottom)
        {
            if (start < 3) return -1;
            int[] rows = { top + 1, (top + bottom) / 2, bottom - 1 };
            int[] values = new int[3];
            for (int k = 0; k < 3; k++)
            {
                int i = rows[k] * stride + start * 4;
                values[k] = Math.Min(Luma(px, i - 4), Math.Min(Luma(px, i - 8), Luma(px, i - 12)));
            }
            return Median(values[0], values[1], values[2]);
        }

        static int Median(int a, int b, int c)
        {
            return Math.Max(Math.Min(a, b), Math.Min(Math.Max(a, b), c));
        }

        static int LearnEdge(int seen)
        {
            return seen >= 0 && seen < DarkEdge ? seen : -1;
        }

        // A borda da barra é escura: confere em três pontos, olhando uma ou duas linhas para fora.
        static bool DarkLine(byte[] px, int stride, int w, int h, int start, int last, int y1, int y2)
        {
            if (y1 < 0 || y1 >= h || y2 < 0 || y2 >= h) return true;
            int dark = 0;
            int[] columns = { start, (start + last) / 2, last };
            foreach (int c in columns)
            {
                if (IsDark(px, y1 * stride + c * 4) || IsDark(px, y2 * stride + c * 4)) dark++;
            }
            return dark >= 2;
        }

        // Aprende a barra de vida numa imagem em que o centro do campeão está em (cx, cy).
        // Procura, acima do campeão, a maior faixa horizontal de uma cor viva e uniforme.
        public static BarModel Learn(byte[] px, int stride, int w, int h, int cx, int cy, double areaHeight)
        {
            int halfWidth = (int)(areaHeight * 0.16);
            int x0 = Math.Max(1, cx - halfWidth), x1 = Math.Min(w - 4, cx + halfWidth);
            int y0 = Math.Max(3, cy - (int)(areaHeight * 0.30)), y1 = Math.Min(h - 4, cy + (int)(areaHeight * 0.04));
            int minLen = Math.Max(12, (int)(areaHeight * 0.02));

            // Cada faixa: menor início, maior fim, linha de cima, linha de baixo, cor de referência,
            // maior início, menor fim, início e fim da última linha.
            List<int[]> blobs = new List<int[]>();
            for (int y = y0; y <= y1; y++)
            {
                int row = y * stride;
                int x = x0;
                while (x <= x1)
                {
                    int i = row + x * 4;
                    if (!IsVivid(px, i) || !Close(px, i, i + 4, 40) || !Close(px, i, i + 8, 40)) { x++; continue; }
                    int reference = i + 4;
                    int start = x, last = x, gap = 0;
                    for (x = x + 1; x <= x1; x++)
                    {
                        if (Close(px, row + x * 4, reference, 45)) { last = x; gap = 0; }
                        else if (++gap > MaxGap) break;
                    }
                    x = last + 1;
                    if (last - start + 1 >= minLen) AddRun(blobs, px, y, start, last, reference);
                }
            }

            // A barra é um retângulo: bordas retas, bem mais larga que alta, inteira dentro da busca.
            // Manchas do terreno ou de feitiços não passam nesses testes.
            int[] bar = null;
            long bestScore = 0;
            foreach (int[] b in blobs)
            {
                int rows = b[3] - b[2] + 1, width = b[1] - b[0] + 1;
                if (rows < 3 || width < rows * 3) continue;
                if (b[5] - b[0] > 2 || b[1] - b[6] > 4) continue;
                if (b[0] <= x0 + 1 || b[1] >= x1 - 1 || b[2] <= y0 || b[3] >= y1) continue;
                if (Math.Abs((b[0] + b[1]) / 2 - cx) > areaHeight * 0.12) continue;
                long score = (long)rows * width;
                if (DarkLine(px, stride, w, h, b[0], b[1], b[2] - 1, b[2] - 2)
                    && DarkLine(px, stride, w, h, b[0], b[1], b[3] + 1, b[3] + 2)) score *= 3;
                if (score > bestScore) { bestScore = score; bar = b; }
            }
            if (bar == null) return null;

            // Cor média da linha do meio da faixa.
            int middle = (bar[2] + bar[3]) / 2;
            long r = 0, g = 0, bl = 0, n = 0;
            for (int x = bar[0] + 2; x <= bar[1] - 2; x++)
            {
                int i = middle * stride + x * 4;
                bl += px[i]; g += px[i + 1]; r += px[i + 2]; n++;
            }
            if (n == 0) return null;

            BarModel m = new BarModel();
            m.R = (int)(r / n);
            m.G = (int)(g / n);
            m.B = (int)(bl / n);

            int top, bottom;
            VerticalExtent(px, stride, h, m, bar[0] + 2, bar[1] - 2, middle, out top, out bottom);
            int thickness = bottom - top + 1;
            if (thickness < 3 || thickness > areaHeight * 0.03) return null;
            m.Height = thickness / areaHeight;
            m.Width = (bar[1] - bar[0] + 1) / areaHeight;
            m.EdgeAbove = LearnEdge(EdgeRow(px, stride, h, bar[0] + 2, bar[1] - 2, top - 1, top - 2));
            m.EdgeBelow = LearnEdge(EdgeRow(px, stride, h, bar[0] + 2, bar[1] - 2, bottom + 1, bottom + 2));
            m.EdgeLeft = LearnEdge(EdgeColumn(px, stride, w, bar[0], top, bottom));

            // Confere que a busca normal encontra essa mesma barra e guarda a distância até o campeão.
            BarHit hit;
            if (!Find(px, stride, w, h, m, areaHeight, bar[0], top, false, Rectangle.Empty, out hit)) return null;
            if (Math.Abs(hit.X - bar[0]) > 6 || Math.Abs(hit.Y - top) > 3) return null;
            m.OffsetX = (cx - hit.X) / areaHeight;
            m.OffsetY = (cy - hit.Y) / areaHeight;
            return m;
        }

        static void AddRun(List<int[]> blobs, byte[] px, int y, int start, int last, int reference)
        {
            foreach (int[] b in blobs)
            {
                if (b[3] < y - 2 || Math.Abs(b[7] - start) > 4 || Math.Abs(b[8] - last) > 8) continue;
                if (!Close(px, b[4], reference, 60)) continue;
                b[3] = y;
                b[0] = Math.Min(b[0], start);
                b[1] = Math.Max(b[1], last);
                b[4] = reference;
                b[5] = Math.Max(b[5], start);
                b[6] = Math.Min(b[6], last);
                b[7] = start;
                b[8] = last;
                return;
            }
            blobs.Add(new int[] { start, last, y, y, reference, start, last, start, last });
        }
    }

    // Copia um pedaço da tela para a memória.
    internal sealed class ScreenGrabber : IDisposable
    {
        Bitmap bitmap;
        public byte[] Buffer;

        public int Grab(Rectangle region)
        {
            if (bitmap == null || bitmap.Width < region.Width || bitmap.Height < region.Height)
            {
                if (bitmap != null) bitmap.Dispose();
                bitmap = new Bitmap(Math.Max(region.Width, 64), Math.Max(region.Height, 64), PixelFormat.Format32bppArgb);
            }
            using (Graphics g = Graphics.FromImage(bitmap))
            {
                g.CopyFromScreen(region.Left, region.Top, 0, 0, region.Size, CopyPixelOperation.SourceCopy);
            }
            BitmapData data = bitmap.LockBits(new Rectangle(0, 0, region.Width, region.Height),
                ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try
            {
                int bytes = data.Stride * region.Height;
                if (Buffer == null || Buffer.Length < bytes) Buffer = new byte[bytes];
                Marshal.Copy(data.Scan0, Buffer, 0, bytes);
                return data.Stride;
            }
            finally
            {
                bitmap.UnlockBits(data);
            }
        }

        public void Dispose()
        {
            if (bitmap != null) bitmap.Dispose();
            bitmap = null;
        }

        // Aprende a barra de vida olhando a tela em volta de onde o campeão está agora.
        public static BarModel LearnBar(Rectangle area, Point champion)
        {
            double h = area.Height;
            Rectangle region = Rectangle.Intersect(area, new Rectangle(
                champion.X - (int)(h * 0.2), champion.Y - (int)(h * 0.34), (int)(h * 0.4), (int)(h * 0.42)));
            if (region.Width < 32 || region.Height < 32) return null;
            using (ScreenGrabber grabber = new ScreenGrabber())
            {
                int stride = grabber.Grab(region);
                return BarFinder.Learn(grabber.Buffer, stride, region.Width, region.Height,
                    champion.X - region.X, champion.Y - region.Y, h);
            }
        }
    }

    // Procura a barra de vida na tela umas 30 vezes por segundo, em segundo plano.
    internal sealed class Tracker
    {
        readonly object sync = new object();
        volatile bool running;

        // Combinado com a tela principal (protegido por 'sync').
        bool enabled;
        Rectangle area;
        Point expectedCenter;
        BarModel model;
        bool hasResult;
        int resultX, resultY, resultTime;

        // Usado só pela thread de busca.
        readonly ScreenGrabber grabber = new ScreenGrabber();
        bool tracking, pending;
        int prevX, prevY, pendingX, pendingY, lost;

        public void Start()
        {
            running = true;
            Thread thread = new Thread(Loop);
            thread.IsBackground = true;
            thread.Priority = ThreadPriority.BelowNormal;
            thread.Start();
        }

        public void Stop()
        {
            running = false;
        }

        public void Configure(bool on, Rectangle gameArea, Point fixedCenter, BarModel bar)
        {
            lock (sync)
            {
                enabled = on;
                area = gameArea;
                expectedCenter = fixedCenter;
                model = bar;
                if (!on) hasResult = false;
            }
        }

        // Centro do campeão encontrado há pouco tempo, em coordenadas da tela.
        public bool TryGetCenter(out Point center)
        {
            lock (sync)
            {
                center = new Point(resultX, resultY);
                return hasResult && unchecked(Environment.TickCount - resultTime) < 600;
            }
        }

        void Loop()
        {
            while (running)
            {
                bool on;
                Rectangle a;
                Point expected;
                BarModel m;
                lock (sync)
                {
                    on = enabled;
                    a = area;
                    expected = expectedCenter;
                    m = model;
                }
                if (!on || m == null || !m.Valid || a.Width < 100 || a.Height < 100)
                {
                    tracking = false;
                    pending = false;
                    Thread.Sleep(100);
                    continue;
                }

                int began = Environment.TickCount;
                try
                {
                    Step(a, expected, m);
                }
                catch
                {
                    // A tela pode ficar inacessível por um instante (bloqueio, aviso do Windows).
                    tracking = false;
                    pending = false;
                    Thread.Sleep(400);
                }
                int period = tracking ? 33 : 100;
                int spent = unchecked(Environment.TickCount - began);
                if (spent < period) Thread.Sleep(period - spent);
            }
            grabber.Dispose();
        }

        void Step(Rectangle a, Point expected, BarModel m)
        {
            double h = a.Height;
            int offX = (int)Math.Round(m.OffsetX * h);
            int offY = (int)Math.Round(m.OffsetY * h);

            // A faixa de baixo da tela (painel com a barra de vida grande) e o minimapa ficam de fora.
            Rectangle searchable = new Rectangle(a.X, a.Y, a.Width, (int)(h * 0.88));
            Rectangle minimap = new Rectangle(a.Right - (int)(h * 0.30), a.Bottom - (int)(h * 0.30), (int)(h * 0.30), (int)(h * 0.30));

            // Seguindo: olha só em volta de onde a barra estava. Perdeu: olha a tela toda.
            Rectangle region = searchable;
            if (tracking)
            {
                int rw = (int)(h * 0.35), rh = (int)(h * 0.22);
                region = Rectangle.Intersect(searchable, new Rectangle(prevX - rw, prevY - rh, rw * 2, rh * 2));
            }
            if (region.Width < 16 || region.Height < 16)
            {
                tracking = false;
                return;
            }

            int stride = grabber.Grab(region);
            int ex = (tracking ? prevX : expected.X - offX) - region.X;
            int ey = (tracking ? prevY : expected.Y - offY) - region.Y;
            Rectangle skip = new Rectangle(minimap.X - region.X, minimap.Y - region.Y, minimap.Width, minimap.Height);
            BarHit hit;
            if (!BarFinder.Find(grabber.Buffer, stride, region.Width, region.Height, m, h, ex, ey, tracking, skip, out hit))
            {
                pending = false;
                if (tracking && ++lost > 6) tracking = false;
                return;
            }

            int sx = region.X + hit.X, sy = region.Y + hit.Y;
            if (!tracking)
            {
                // Só começa a seguir depois de ver a barra no mesmo lugar em dois quadros seguidos.
                bool confirmed = pending && Math.Abs(sx - pendingX) <= 12 && Math.Abs(sy - pendingY) <= 12;
                pending = true;
                pendingX = sx;
                pendingY = sy;
                if (!confirmed) return;
                pending = false;
                tracking = true;
            }
            prevX = sx;
            prevY = sy;
            lost = 0;
            lock (sync)
            {
                resultX = sx + offX;
                resultY = sy + offY;
                resultTime = Environment.TickCount;
                hasResult = true;
            }
        }
    }

    // Recebe os atalhos de teclado globais (funcionam mesmo com o jogo em foco).
    internal sealed class HotkeyWindow : NativeWindow, IDisposable
    {
        readonly Dictionary<int, Action> actions = new Dictionary<int, Action>();
        int nextId = 1;

        public HotkeyWindow()
        {
            CreateHandle(new CreateParams());
        }

        public bool Bind(Keys key, bool repeat, Action action)
        {
            int id = nextId++;
            uint mods = Native.MOD_CONTROL | Native.MOD_ALT | (repeat ? 0u : Native.MOD_NOREPEAT);
            if (!Native.RegisterHotKey(Handle, id, mods, (uint)key)) return false;
            actions[id] = action;
            return true;
        }

        protected override void WndProc(ref Message m)
        {
            Action action;
            if (m.Msg == Native.WM_HOTKEY && actions.TryGetValue(m.WParam.ToInt32(), out action))
            {
                action();
                return;
            }
            base.WndProc(ref m);
        }

        public void Dispose()
        {
            foreach (int id in actions.Keys) Native.UnregisterHotKey(Handle, id);
            actions.Clear();
            DestroyHandle();
        }
    }

    internal sealed class FocusApp : ApplicationContext
    {
        const double MoveStep = 0.002;
        const double SizeStep = 0.003;

        readonly Settings settings;
        readonly OverlayForm overlay;
        readonly NotifyIcon tray;
        readonly HotkeyWindow hotkeys;
        readonly LiveGame live = new LiveGame();
        readonly Tracker tracker = new Tracker();
        readonly WinTimer trackTimer = new WinTimer();
        readonly WinTimer calibrationTimer = new WinTimer();
        readonly WinTimer pulseTimer = new WinTimer();
        readonly WinTimer saveTimer = new WinTimer();
        readonly List<Image> menuImages = new List<Image>();
        IntPtr trayIconHandle;

        bool visible = true;
        bool dirty;
        bool closed;
        int ticks;
        double pulsePhase;
        Rectangle lastArea;
        int lastSide = int.MinValue;
        bool calibrating;

        ToolStripMenuItem statusItem, showItem, onlyInGameItem, hideWhenDeadItem, followItem, pulseItem, monitorMenu;
        readonly List<ToolStripMenuItem> shapeItems = new List<ToolStripMenuItem>();
        readonly List<ToolStripMenuItem> colorItems = new List<ToolStripMenuItem>();
        readonly List<ToolStripMenuItem> thicknessItems = new List<ToolStripMenuItem>();
        readonly List<ToolStripMenuItem> opacityItems = new List<ToolStripMenuItem>();

        public FocusApp()
        {
            settings = Settings.Load();
            overlay = new OverlayForm(settings);

            tray = new NotifyIcon();
            tray.Icon = CreateTrayIcon();
            tray.Text = "Moldura de Foco (LoL)";
            tray.ContextMenuStrip = BuildMenu();
            tray.MouseClick += OnTrayClick;
            tray.Visible = true;

            hotkeys = new HotkeyWindow();
            string failed = RegisterHotkeys();

            trackTimer.Interval = 250;
            trackTimer.Tick += delegate { Refresh(false); };
            trackTimer.Start();

            pulseTimer.Interval = 40;
            pulseTimer.Tick += OnPulse;

            saveTimer.Interval = 1500;
            saveTimer.Tick += delegate { if (dirty) { dirty = false; settings.Save(); } };
            saveTimer.Start();

            calibrationTimer.Interval = 200;
            calibrationTimer.Tick += delegate { FinishCalibration(); };

            live.Start();
            tracker.Start();
            Refresh(true);

            string message = failed.Length == 0
                ? "Ctrl+Alt+F mostra ou esconde a moldura. Clique com o botão direito neste ícone para trocar forma, cor e tamanho."
                : "Estes atalhos já estão em uso por outro programa: " + failed + ". As mesmas opções estão no menu deste ícone.";
            tray.ShowBalloonTip(6000, "Moldura de Foco ligada", message, ToolTipIcon.Info);
        }

        // ---------- posição e visibilidade ----------

        void Refresh(bool force)
        {
            if (closed) return;

            IntPtr game = FindGameWindow();
            Rectangle area = game != IntPtr.Zero ? ClientArea(game) : Rectangle.Empty;
            if (area.Width < 320 || area.Height < 240)
            {
                game = IntPtr.Zero;
                area = CurrentScreen().Bounds;
            }

            // Lado do mapa informado pela API do jogo; fora de partida usa a posição do lado azul.
            int side = live.Side;
            bool inMatch = game != IntPtr.Zero || side != LiveGame.NoGame;
            bool dead = side != LiveGame.NoGame && live.Dead;
            if (side != lastSide)
            {
                lastSide = side;
                tray.Text = "Moldura de Foco (LoL) - " + SideText(side);
            }
            lastArea = area;

            bool show = visible;
            if (show && settings.OnlyInGame)
                show = game != IntPtr.Zero && Native.GetForegroundWindow() == game;
            if (show && settings.HideWhenDead && dead)
                show = false;

            // Modo seguir: a moldura vai para onde a barra de vida foi encontrada.
            // Sem barra à vista (campeão fora da tela), a moldura some.
            Point fixedCenter = FixedCenter(area);
            Point center = fixedCenter;
            bool following = IsFollowing && inMatch;
            tracker.Configure(following && show && !dead && !calibrating, area, fixedCenter, settings.Bar);
            if (following)
            {
                Point tracked;
                if (tracker.TryGetCenter(out tracked)) center = tracked;
                else if (!overlay.HasMessage) show = false;
            }
            if (calibrating) show = false;

            overlay.Place(area, center.X, center.Y, force);
            int interval = following ? 33 : 250;
            if (trackTimer.Interval != interval) trackTimer.Interval = interval;

            if (show && !overlay.Visible) overlay.Show();
            else if (!show && overlay.Visible) overlay.Hide();

            // Alguns jogos tentam ficar por cima de tudo; reafirma a moldura de tempos em tempos.
            if (show && ++ticks % 8 == 0)
                Native.SetWindowPos(overlay.Handle, Native.HWND_TOPMOST, 0, 0, 0, 0,
                    Native.SWP_NOMOVE | Native.SWP_NOSIZE | Native.SWP_NOACTIVATE);

            pulseTimer.Enabled = show && settings.Pulse;
            if (!settings.Pulse) SetOpacityIfChanged(BaseOpacity);
        }

        bool IsFollowing
        {
            get { return settings.Follow && settings.Bar != null && settings.Bar.Valid; }
        }

        // Posição fixa da moldura (câmera travada) no lado atual do mapa.
        Point FixedCenter(Rectangle area)
        {
            double h = area.Height;
            return new Point(
                area.Left + area.Width / 2 + (int)Math.Round(settings.OffsetX[PositionIndex] * h),
                area.Top + area.Height / 2 + (int)Math.Round(settings.OffsetY[PositionIndex] * h));
        }

        // Qual das duas posições guardadas está em uso: 0 = lado azul, 1 = lado vermelho.
        int PositionIndex
        {
            get { return lastSide == LiveGame.Red ? 1 : 0; }
        }

        static string SideText(int side)
        {
            if (side == LiveGame.Blue) return "lado azul";
            if (side == LiveGame.Red) return "lado vermelho";
            return "nenhuma partida";
        }

        void SetOpacityIfChanged(double value)
        {
            if (Math.Abs(overlay.Opacity - value) > 0.001) overlay.Opacity = value;
        }

        static IntPtr FindGameWindow()
        {
            // Só procura a janela da partida para saber onde ela está na tela.
            IntPtr h = Native.FindWindow("RiotWindowClass", null);
            if (h == IntPtr.Zero) h = Native.FindWindow(null, "League of Legends (TM) Client");
            if (h == IntPtr.Zero || !Native.IsWindowVisible(h) || Native.IsIconic(h)) return IntPtr.Zero;
            return h;
        }

        static Rectangle ClientArea(IntPtr window)
        {
            Native.RECT rect;
            Native.POINT origin = new Native.POINT();
            if (!Native.GetClientRect(window, out rect) || !Native.ClientToScreen(window, ref origin))
                return Rectangle.Empty;
            return new Rectangle(origin.X, origin.Y, rect.Right - rect.Left, rect.Bottom - rect.Top);
        }

        Screen CurrentScreen()
        {
            Screen[] all = Screen.AllScreens;
            if (settings.Monitor >= 0 && settings.Monitor < all.Length) return all[settings.Monitor];
            return Screen.PrimaryScreen;
        }

        double BaseOpacity
        {
            get { return settings.Opacity / 100.0; }
        }

        void OnPulse(object sender, EventArgs e)
        {
            pulsePhase += 2 * Math.PI * pulseTimer.Interval / 1600.0;
            double wave = 0.5 + 0.5 * Math.Sin(pulsePhase);
            SetOpacityIfChanged(BaseOpacity * (0.35 + 0.65 * wave));
        }

        // ---------- ações ----------

        void Changed()
        {
            dirty = true;
            Refresh(true);
        }

        void ToggleVisible()
        {
            visible = !visible;
            Refresh(true);
        }

        void Move(int dx, int dy)
        {
            visible = true;
            if (IsFollowing)
            {
                // Seguindo: ajusta onde a moldura fica em relação à barra de vida.
                BarModel bar = settings.Bar.Clone();
                bar.OffsetX = Clamp(bar.OffsetX + dx * MoveStep, -0.5, 0.5);
                bar.OffsetY = Clamp(bar.OffsetY + dy * MoveStep, -0.5, 0.5);
                settings.Bar = bar;
            }
            else
            {
                int i = PositionIndex;
                settings.OffsetX[i] = Clamp(settings.OffsetX[i] + dx * MoveStep, -0.45, 0.45);
                settings.OffsetY[i] = Clamp(settings.OffsetY[i] + dy * MoveStep, -0.45, 0.45);
            }
            Changed();
        }

        void Resize(int direction)
        {
            visible = true;
            settings.Size = Clamp(settings.Size + direction * SizeStep, 0.02, 0.3);
            Changed();
        }

        void SetShape(int shape) { visible = true; settings.Shape = shape; Changed(); }
        void SetColor(int index) { visible = true; settings.ColorIndex = index; Changed(); }
        void SetThickness(int level) { visible = true; settings.Thickness = level; Changed(); }
        void SetOpacity(int percent) { visible = true; settings.Opacity = percent; Changed(); }
        void SetMonitor(int index) { settings.Monitor = index; Changed(); }
        void TogglePulse() { visible = true; settings.Pulse = !settings.Pulse; Changed(); }
        void ToggleOnlyInGame() { settings.OnlyInGame = !settings.OnlyInGame; Changed(); }
        void ToggleHideWhenDead() { settings.HideWhenDead = !settings.HideWhenDead; Changed(); }

        void ToggleFollow()
        {
            visible = true;
            if (settings.Bar == null || !settings.Bar.Valid)
            {
                settings.Follow = false;
                Notify("Primeiro: Ctrl+Alt+B", "Para seguir o campeão, a moldura precisa aprender a sua barra de vida. "
                    + "Trave a câmera com a moldura em cima do campeão, fique parado com a vida cheia e aperte Ctrl+Alt+B.");
                return;
            }
            settings.Follow = !settings.Follow;
            overlay.ShowMessage(settings.Follow ? "Seguindo o campeão" : "Moldura fixa", Color.White);
            Changed();
        }

        // Aprender a barra: esconde a moldura, espera a tela atualizar e olha em volta do campeão.
        void StartCalibration()
        {
            if (calibrating) return;
            visible = true;
            calibrating = true;
            Refresh(true);
            calibrationTimer.Start();
        }

        void FinishCalibration()
        {
            calibrationTimer.Stop();
            BarModel learned = null;
            try
            {
                learned = ScreenGrabber.LearnBar(lastArea, FixedCenter(lastArea));
            }
            catch
            {
                learned = null;
            }
            calibrating = false;

            if (learned != null)
            {
                settings.Bar = learned;
                settings.Follow = true;
                dirty = true;
                overlay.ShowMessage("Barra aprendida! Seguindo", Color.White);
                Refresh(true);
            }
            else
            {
                Notify("Não achei a barra de vida", "Trave a câmera, confira se a moldura está em cima do campeão, "
                    + "fique parado com a vida cheia e longe de outros campeões, e aperte Ctrl+Alt+B de novo.");
            }
        }

        void Notify(string shortText, string longText)
        {
            overlay.ShowMessage(shortText, Color.FromArgb(255, 170, 60));
            tray.ShowBalloonTip(8000, "Moldura de Foco", longText, ToolTipIcon.Warning);
            Refresh(true);
        }

        void ResetPosition()
        {
            visible = true;
            settings.Size = Settings.DefaultSize;
            settings.OffsetX[PositionIndex] = Settings.DefaultOffsetX;
            settings.OffsetY[PositionIndex] = Settings.DefaultOffsetY;
            Changed();
        }

        static double Clamp(double v, double min, double max)
        {
            return Math.Max(min, Math.Min(max, v));
        }

        string RegisterHotkeys()
        {
            List<string> failed = new List<string>();
            Check(failed, "Ctrl+Alt+F", hotkeys.Bind(Keys.F, false, ToggleVisible));

            bool arrows = hotkeys.Bind(Keys.Up, true, () => Move(0, -1));
            arrows &= hotkeys.Bind(Keys.Down, true, () => Move(0, 1));
            arrows &= hotkeys.Bind(Keys.Left, true, () => Move(-1, 0));
            arrows &= hotkeys.Bind(Keys.Right, true, () => Move(1, 0));
            Check(failed, "Ctrl+Alt+setas", arrows);

            // Aceita o + e o - normais, os do teclado numérico e PageUp/PageDown.
            bool bigger = hotkeys.Bind(Keys.Oemplus, true, () => Resize(1));
            bigger |= hotkeys.Bind(Keys.Add, true, () => Resize(1));
            bigger |= hotkeys.Bind(Keys.PageUp, true, () => Resize(1));
            bool smaller = hotkeys.Bind(Keys.OemMinus, true, () => Resize(-1));
            smaller |= hotkeys.Bind(Keys.Subtract, true, () => Resize(-1));
            smaller |= hotkeys.Bind(Keys.PageDown, true, () => Resize(-1));
            Check(failed, "Ctrl+Alt + / -", bigger && smaller);

            Check(failed, "Ctrl+Alt+M", hotkeys.Bind(Keys.M, false, () => SetShape((settings.Shape + 1) % Palette.ShapeNames.Length)));
            Check(failed, "Ctrl+Alt+C", hotkeys.Bind(Keys.C, false, () => SetColor((settings.ColorIndex + 1) % Palette.Colors.Length)));
            Check(failed, "Ctrl+Alt+P", hotkeys.Bind(Keys.P, false, TogglePulse));
            Check(failed, "Ctrl+Alt+R", hotkeys.Bind(Keys.R, false, ResetPosition));
            Check(failed, "Ctrl+Alt+S", hotkeys.Bind(Keys.S, false, ToggleFollow));
            Check(failed, "Ctrl+Alt+B", hotkeys.Bind(Keys.B, false, StartCalibration));
            return string.Join(", ", failed.ToArray());
        }

        static void Check(List<string> failed, string name, bool ok)
        {
            if (!ok) failed.Add(name);
        }

        // ---------- menu do ícone ----------

        ContextMenuStrip BuildMenu()
        {
            ContextMenuStrip menu = new ContextMenuStrip();

            statusItem = new ToolStripMenuItem();
            statusItem.Enabled = false;
            menu.Items.Add(statusItem);
            menu.Items.Add(new ToolStripSeparator());

            showItem = Item("Mostrar moldura", "Ctrl+Alt+F", delegate { ToggleVisible(); });
            onlyInGameItem = Item("Mostrar só durante a partida", null, delegate { ToggleOnlyInGame(); });
            hideWhenDeadItem = Item("Esconder quando o campeão morrer", null, delegate { ToggleHideWhenDead(); });
            menu.Items.Add(showItem);
            menu.Items.Add(onlyInGameItem);
            menu.Items.Add(hideWhenDeadItem);
            menu.Items.Add(new ToolStripSeparator());

            followItem = Item("Seguir o campeão (experimental)", "Ctrl+Alt+S", delegate { ToggleFollow(); });
            menu.Items.Add(followItem);
            menu.Items.Add(Item("Aprender a barra de vida", "Ctrl+Alt+B", delegate { StartCalibration(); }));
            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem shapeMenu = new ToolStripMenuItem("Forma");
            for (int i = 0; i < Palette.ShapeNames.Length; i++)
            {
                int index = i;
                ToolStripMenuItem item = Item(Palette.ShapeNames[i], null, delegate { SetShape(index); });
                Bitmap preview = ShapePreview(i);
                menuImages.Add(preview);
                item.Image = preview;
                shapeItems.Add(item);
                shapeMenu.DropDownItems.Add(item);
            }
            menu.Items.Add(shapeMenu);

            ToolStripMenuItem colorMenu = new ToolStripMenuItem("Cor");
            for (int i = 0; i < Palette.Colors.Length; i++)
            {
                int index = i;
                ToolStripMenuItem item = Item(Palette.ColorNames[i], null, delegate { SetColor(index); });
                Bitmap swatch = ColorSwatch(Palette.Colors[i]);
                menuImages.Add(swatch);
                item.Image = swatch;
                colorItems.Add(item);
                colorMenu.DropDownItems.Add(item);
            }
            menu.Items.Add(colorMenu);

            ToolStripMenuItem sizeMenu = new ToolStripMenuItem("Tamanho");
            sizeMenu.DropDownItems.Add(Item("Aumentar", "Ctrl+Alt + +", delegate { Resize(3); }));
            sizeMenu.DropDownItems.Add(Item("Diminuir", "Ctrl+Alt + -", delegate { Resize(-3); }));
            menu.Items.Add(sizeMenu);

            ToolStripMenuItem thicknessMenu = new ToolStripMenuItem("Espessura da linha");
            for (int i = 0; i < Palette.ThicknessNames.Length; i++)
            {
                int level = i;
                ToolStripMenuItem item = Item(Palette.ThicknessNames[i], null, delegate { SetThickness(level); });
                thicknessItems.Add(item);
                thicknessMenu.DropDownItems.Add(item);
            }
            menu.Items.Add(thicknessMenu);

            ToolStripMenuItem opacityMenu = new ToolStripMenuItem("Opacidade");
            foreach (int percent in Palette.OpacityLevels)
            {
                int value = percent;
                ToolStripMenuItem item = Item(value + "%", null, delegate { SetOpacity(value); });
                item.Tag = value;
                opacityItems.Add(item);
                opacityMenu.DropDownItems.Add(item);
            }
            menu.Items.Add(opacityMenu);

            pulseItem = Item("Pulsar suavemente", "Ctrl+Alt+P", delegate { TogglePulse(); });
            menu.Items.Add(pulseItem);

            monitorMenu = new ToolStripMenuItem("Monitor (se o jogo não for encontrado)");
            menu.Items.Add(monitorMenu);

            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add(Item("Voltar à posição e tamanho iniciais (deste lado)", "Ctrl+Alt+R", delegate { ResetPosition(); }));
            menu.Items.Add(Item("Ver atalhos de teclado...", null, delegate { ShowHelp(); }));
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add(Item("Sair", null, delegate { Quit(); }));

            menu.Opening += delegate { RefreshMenu(); };
            return menu;
        }

        // O Windows só abre o menu com o botão direito; abre também com o esquerdo.
        void OnTrayClick(object sender, MouseEventArgs e)
        {
            if (e.Button != MouseButtons.Left) return;
            MethodInfo show = typeof(NotifyIcon).GetMethod("ShowContextMenu", BindingFlags.Instance | BindingFlags.NonPublic);
            if (show != null) show.Invoke(tray, null);
        }

        static ToolStripMenuItem Item(string text, string shortcut, EventHandler onClick)
        {
            ToolStripMenuItem item = new ToolStripMenuItem(text);
            if (shortcut != null) item.ShortcutKeyDisplayString = shortcut;
            item.Click += onClick;
            return item;
        }

        void RefreshMenu()
        {
            int side = live.Side;
            string status = side == LiveGame.NoGame
                ? "Nenhuma partida em andamento"
                : "Partida detectada: " + SideText(side) + (live.Dead ? " (campeão morto)" : "");
            if (IsFollowing && side != LiveGame.NoGame)
            {
                Point unused;
                status += tracker.TryGetCenter(out unused) ? " - seguindo" : " - procurando o campeão";
            }
            statusItem.Text = status;
            followItem.Checked = IsFollowing;
            showItem.Checked = visible;
            onlyInGameItem.Checked = settings.OnlyInGame;
            hideWhenDeadItem.Checked = settings.HideWhenDead;
            pulseItem.Checked = settings.Pulse;
            for (int i = 0; i < shapeItems.Count; i++) shapeItems[i].Checked = i == settings.Shape;
            for (int i = 0; i < colorItems.Count; i++) colorItems[i].Checked = i == settings.ColorIndex;
            for (int i = 0; i < thicknessItems.Count; i++) thicknessItems[i].Checked = i == settings.Thickness;
            foreach (ToolStripMenuItem item in opacityItems) item.Checked = (int)item.Tag == settings.Opacity;

            // A lista de monitores pode mudar com o programa aberto.
            Screen[] screens = Screen.AllScreens;
            monitorMenu.Visible = screens.Length > 1;
            monitorMenu.DropDownItems.Clear();
            ToolStripMenuItem primary = Item("Monitor principal", null, delegate { SetMonitor(-1); });
            primary.Checked = settings.Monitor < 0 || settings.Monitor >= screens.Length;
            monitorMenu.DropDownItems.Add(primary);
            for (int i = 0; i < screens.Length; i++)
            {
                int index = i;
                string name = "Monitor " + (i + 1) + (screens[i].Primary ? " (principal)" : "")
                            + "  -  " + screens[i].Bounds.Width + "x" + screens[i].Bounds.Height;
                ToolStripMenuItem item = Item(name, null, delegate { SetMonitor(index); });
                item.Checked = settings.Monitor == i;
                monitorMenu.DropDownItems.Add(item);
            }
        }

        void ShowHelp()
        {
            MessageBox.Show(
                "Atalhos (funcionam com o jogo aberto):\n\n" +
                "Ctrl + Alt + F  —  mostrar / esconder a moldura\n" +
                "Ctrl + Alt + setas  —  mover a moldura\n" +
                "Ctrl + Alt + (+) / (-)  —  aumentar / diminuir\n" +
                "      (também valem PageUp / PageDown)\n" +
                "Ctrl + Alt + M  —  trocar a forma\n" +
                "Ctrl + Alt + C  —  trocar a cor\n" +
                "Ctrl + Alt + P  —  ligar / desligar o efeito de pulsar\n" +
                "Ctrl + Alt + R  —  voltar à posição e ao tamanho iniciais\n" +
                "Ctrl + Alt + B  —  aprender a barra de vida (para seguir o campeão)\n" +
                "Ctrl + Alt + S  —  ligar / desligar o modo seguir o campeão\n\n" +
                "A moldura guarda uma posição para o lado azul e outra para o vermelho e troca\n" +
                "sozinha conforme o lado da partida. Ajuste cada lado uma vez, com a câmera travada.\n\n" +
                "Dica: deixe o jogo no modo \"Sem bordas\".\n\n" +
                "Para fechar: botão direito no ícone perto do relógio  →  Sair.",
                "Moldura de Foco — atalhos", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        // ---------- imagens do ícone e do menu ----------

        Icon CreateTrayIcon()
        {
            using (Bitmap bmp = new Bitmap(32, 32))
            {
                using (Graphics g = Graphics.FromImage(bmp))
                {
                    g.SmoothingMode = SmoothingMode.AntiAlias;
                    g.Clear(Color.Transparent);
                    Shapes.Draw(g, Shapes.Corners, 16, 16, 12, 3, Palette.Colors[0]);
                    using (Brush dot = new SolidBrush(Palette.Colors[0])) g.FillEllipse(dot, 12, 12, 8, 8);
                }
                trayIconHandle = bmp.GetHicon();
                return Icon.FromHandle(trayIconHandle);
            }
        }

        static Bitmap ShapePreview(int shape)
        {
            Bitmap bmp = new Bitmap(16, 16);
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);
                // A seta é desenhada acima do centro, então o centro fica abaixo da imagem.
                float r = shape == Shapes.Arrow ? 20f : 5.5f;
                float cy = shape == Shapes.Arrow ? 38.5f : 8f;
                using (GraphicsPath path = Shapes.Build(shape, 8, cy, r))
                using (Pen pen = new Pen(Color.FromArgb(60, 60, 60), 1.6f))
                {
                    if (shape == Shapes.Arrow)
                        using (Brush b = new SolidBrush(Color.FromArgb(60, 60, 60))) g.FillPath(b, path);
                    else
                        g.DrawPath(pen, path);
                }
            }
            return bmp;
        }

        static Bitmap ColorSwatch(Color color)
        {
            Bitmap bmp = new Bitmap(16, 16);
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.Clear(Color.Transparent);
                using (Brush b = new SolidBrush(color)) g.FillRectangle(b, 2, 2, 12, 12);
                g.DrawRectangle(Pens.Black, 2, 2, 11, 11);
            }
            return bmp;
        }

        // ---------- encerramento ----------

        void Quit()
        {
            Cleanup();
            ExitThread();
        }

        void Cleanup()
        {
            if (closed) return;
            closed = true;
            live.Stop();
            tracker.Stop();
            calibrationTimer.Stop();
            trackTimer.Stop();
            pulseTimer.Stop();
            saveTimer.Stop();
            settings.Save();
            hotkeys.Dispose();
            tray.Visible = false;
            tray.Dispose();
            overlay.Close();
            overlay.Dispose();
            foreach (Image img in menuImages) img.Dispose();
            if (trayIconHandle != IntPtr.Zero) Native.DestroyIcon(trayIconHandle);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) Cleanup();
            base.Dispose(disposing);
        }
    }
}
'@

try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Web.Extensions
    # Caminho completo de cada biblioteca, para o compilador encontrá-las com certeza.
    $referencias = [System.Windows.Forms.Form], [System.Drawing.Color], [System.Web.Script.Serialization.JavaScriptSerializer] |
        ForEach-Object { $_.Assembly.Location }
    Add-Type -TypeDefinition $codigo -Language CSharp -ReferencedAssemblies $referencias
    [MolduraFoco.Program]::Run()
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Não foi possível abrir a Moldura de Foco.`n`n$($_.Exception.Message)",
        'Moldura de Foco', 'OK', 'Error') | Out-Null
}
