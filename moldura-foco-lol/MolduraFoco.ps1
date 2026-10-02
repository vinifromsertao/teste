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
                Directory.CreateDirectory(Folder);
                File.WriteAllText(FilePath, sb.ToString());
            }
            catch
            {
                // Não conseguir salvar não deve fechar a moldura.
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

        public void Place(Rectangle area, double offsetX, double offsetY)
        {
            float h = area.Height;
            radius = Math.Max(10f, (float)(settings.Size * h));
            thickness = Math.Max(2f, (float)Math.Round(Palette.ThicknessAt1080p[settings.Thickness] * h / 1080f));

            int half = (int)Math.Ceiling(radius * 1.9f + thickness * 2 + 6);
            int cx = area.Left + area.Width / 2 + (int)Math.Round(offsetX * h);
            int cy = area.Top + area.Height / 2 + (int)Math.Round(offsetY * h);
            Rectangle bounds = new Rectangle(cx - half, cy - half, half * 2, half * 2);
            if (Bounds != bounds) Bounds = bounds;
            Invalidate();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            g.Clear(KeyColor);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            Shapes.Draw(g, settings.Shape, ClientSize.Width / 2f, ClientSize.Height / 2f, radius, thickness,
                Palette.Colors[settings.ColorIndex]);
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
        readonly WinTimer trackTimer = new WinTimer();
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

        ToolStripMenuItem statusItem, showItem, onlyInGameItem, hideWhenDeadItem, pulseItem, monitorMenu;
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

            live.Start();
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

            bool show = visible;
            if (show && settings.OnlyInGame)
                show = game != IntPtr.Zero && Native.GetForegroundWindow() == game;
            if (show && settings.HideWhenDead && side != LiveGame.NoGame && live.Dead)
                show = false;

            if (force || area != lastArea || side != lastSide)
            {
                lastArea = area;
                lastSide = side;
                overlay.Place(area, settings.OffsetX[PositionIndex], settings.OffsetY[PositionIndex]);
                tray.Text = "Moldura de Foco (LoL) - " + SideText(side);
            }

            if (show && !overlay.Visible) overlay.Show();
            else if (!show && overlay.Visible) overlay.Hide();

            // Alguns jogos tentam ficar por cima de tudo; reafirma a moldura de tempos em tempos.
            if (show && ++ticks % 8 == 0)
                Native.SetWindowPos(overlay.Handle, Native.HWND_TOPMOST, 0, 0, 0, 0,
                    Native.SWP_NOMOVE | Native.SWP_NOSIZE | Native.SWP_NOACTIVATE);

            pulseTimer.Enabled = show && settings.Pulse;
            if (!settings.Pulse) SetOpacityIfChanged(BaseOpacity);
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
            int i = PositionIndex;
            settings.OffsetX[i] = Clamp(settings.OffsetX[i] + dx * MoveStep, -0.45, 0.45);
            settings.OffsetY[i] = Clamp(settings.OffsetY[i] + dy * MoveStep, -0.45, 0.45);
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
            statusItem.Text = side == LiveGame.NoGame
                ? "Nenhuma partida em andamento"
                : "Partida detectada: " + SideText(side) + (live.Dead ? " (campeão morto)" : "");
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
                "Ctrl + Alt + R  —  voltar à posição e ao tamanho iniciais\n\n" +
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
