using SecuGen.FDxSDKPro.Windows;
using System;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace BioKeyBridge
{
    class Program
    {
        private static SGFingerPrintManager fpm;
        private static int imageWidth;
        private static int imageHeight;

        static void Main(string[] args)
        {
            Console.Title = "BioKeyRotate SecuGen Bridge";
            Console.WriteLine("Starting BioKeyRotate SecuGen Bridge...");

            if (!InitScanner())
            {
                Console.WriteLine("Scanner init failed. Press Enter to exit.");
                Console.ReadLine();
                return;
            }

            StartHttpServer("http://127.0.0.1:5001/");

            Console.WriteLine("Bridge running.");
            Console.WriteLine("Listening on http://127.0.0.1:5001/scan");
            Console.WriteLine("Leave this window open while using the website.");
            Console.WriteLine("Press Enter to stop.");
            Console.ReadLine();
        }

        private static bool InitScanner()
        {
            try
            {
                fpm = new SGFingerPrintManager();
                var err = fpm.Init(SGFPMDeviceName.DEV_AUTO);
                if (err != (int)SGFPMError.ERROR_NONE)
                {
                    Console.WriteLine("Init error: " + (SGFPMError)err);
                    return false;
                }

                err = fpm.OpenDevice(0);
                if (err != (int)SGFPMError.ERROR_NONE)
                {
                    Console.WriteLine("OpenDevice error: " + (SGFPMError)err);
                    return false;
                }

                var info = new SGFPMDeviceInfoParam();
                fpm.GetDeviceInfo(info);
                imageWidth = info.ImageWidth;
                imageHeight = info.ImageHeight;

                Console.WriteLine($"Scanner ready. Image size: {imageWidth}x{imageHeight}");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Scanner init exception: " + ex.Message);
                return false;
            }
        }

        private static void StartHttpServer(string prefix)
        {
            var listener = new HttpListener();
            listener.Prefixes.Add(prefix);
            listener.Start();

            Task.Run(async () =>
            {
                while (listener.IsListening)
                {
                    HttpListenerContext ctx = null;
                    try
                    {
                        ctx = await listener.GetContextAsync();
                    }
                    catch
                    {
                        break;
                    }

                    HandleRequest(ctx);
                }
            });
        }

        private static void HandleRequest(HttpListenerContext ctx)
        {
            var req = ctx.Request;
            var res = ctx.Response;

            // CORS headers so browser JS can call this
            res.Headers.Add("Access-Control-Allow-Origin", "http://localhost:8000");
            res.Headers.Add("Access-Control-Allow-Methods", "POST, OPTIONS");
            res.Headers.Add("Access-Control-Allow-Headers", "Content-Type");

            // Preflight
            if (req.HttpMethod == "OPTIONS")
            {
                res.StatusCode = 200;
                res.Close();
                return;
            }

            if (req.Url.AbsolutePath == "/scan" && req.HttpMethod == "POST")
            {
                Console.WriteLine("Received /scan request. Waiting for finger...");

                string json;

                try
                {
                    byte[] tmpl = CaptureTemplate();
                    if (tmpl == null)
                    {
                        res.StatusCode = 500;
                        json = "{\"templateBase64\":null}";
                    }
                    else
                    {
                        string base64 = Convert.ToBase64String(tmpl);
                        json = "{\"templateBase64\":\"" + base64 + "\"}";
                        Console.WriteLine("Template captured and sent.");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Capture error: " + ex.Message);
                    res.StatusCode = 500;
                    json = "{\"templateBase64\":null}";
                }

                byte[] buf = Encoding.UTF8.GetBytes(json);
                res.ContentType = "application/json";
                res.OutputStream.Write(buf, 0, buf.Length);
                res.OutputStream.Close();
            }
            else
            {
                res.StatusCode = 404;
                res.Close();
            }
        }


        // Capture ONE template (waits up to 10 seconds for finger)
        private static byte[] CaptureSingleTemplate()
        {
            byte[] image = new byte[imageWidth * imageHeight];

            const int timeoutMs = 10000; // wait up to 10 seconds
            var sw = System.Diagnostics.Stopwatch.StartNew();

            int err;
            do
            {
                err = fpm.GetImage(image);
                if (err == (int)SGFPMError.ERROR_NONE)
                    break;

                System.Threading.Thread.Sleep(200); // brief wait then retry

            } while (sw.ElapsedMilliseconds < timeoutMs);

            if (err != (int)SGFPMError.ERROR_NONE)
            {
                Console.WriteLine("GetImage timeout or error: " + (SGFPMError)err);
                return null;
            }

            // template format
            fpm.SetTemplateFormat(SGFPMTemplateFormat.ANSI378);

            int maxSize = 0;
            fpm.GetMaxTemplateSize(ref maxSize);
            byte[] template = new byte[maxSize];

            err = fpm.CreateTemplate(image, template);
            if (err != (int)SGFPMError.ERROR_NONE)
            {
                Console.WriteLine("CreateTemplate error: " + (SGFPMError)err);
                return null;
            }

            return template;
        }

            // Capture multiple scans and average them for stability
private static byte[] CaptureTemplate()
        {
            const int numScans = 3;
            byte[][] templates = new byte[numScans][];

            for (int i = 0; i < numScans; i++)
            {
                Console.WriteLine($"Place finger for scan {i + 1} of {numScans}...");
                var tmpl = CaptureSingleTemplate();
                if (tmpl == null)
                {
                    Console.WriteLine("Failed to capture template for scan " + (i + 1));
                    return null;
                }
                templates[i] = tmpl;
                Console.WriteLine($"Scan {i + 1} complete. Lift finger.");
                System.Threading.Thread.Sleep(800); // small pause between scans
            }

            int length = templates[0].Length;
            // (Assume SDK gives same length for all scans; that's fine for project)

            byte[] merged = new byte[length];

            for (int idx = 0; idx < length; idx++)
            {
                int sum = 0;
                for (int s = 0; s < numScans; s++)
                {
                    sum += templates[s][idx];
                }
                merged[idx] = (byte)(sum / numScans);
            }

            Console.WriteLine("Averaged template created from multiple scans.");
            return merged;
        }

    }

}
