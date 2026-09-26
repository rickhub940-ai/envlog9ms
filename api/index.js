// Envlog9ms - 5 Files Version - Direct Concat 400KB+ All-in-One API
// เธฃเธงเธกเธ—เธธเธ endpoint เนเธงเนเนเธเนเธเธฅเนเน€เธ”เธตเธขเธง: /, /api/health, /api/direct_concat, /api/mega, /api/allinone, /api/deobfuscate, /api/dump

function analyzeDirectConcat(code) {
  const start = Date.now();
  const hasLuraph = code.includes("does your environment support load/loadstring?");
  
  // StringRefs (Larry)
  const stringRefs = [];
  const patterns = [
    { regex: /https?:\/\/[^\s"'`]+/g, hint: "URL" },
    { regex: /[A-Za-z0-9+/]{100,}={0,2}/g, hint: "base64" },
    { regex: /rbxasset(id)?:\/\/[^\s"'`]+/g, hint: "Asset" },
  ];
  for (const p of patterns) {
    let m; while ((m = p.regex.exec(code)) !== null) {
      if (m[0].length > 30) stringRefs.push({ value: m[0].substring(0,120), hint: p.hint });
    }
  }

  // CallGraph 60+ hooks (main + Larry)
  const callGraph = [];
  const cgPatterns = [
    { regex: /:FireServer\(/g, type: "FireServer", risk: "high" },
    { regex: /:InvokeServer\(/g, type: "InvokeServer", risk: "high" },
    { regex: /:GetService\(["'](.*?)["']\)/g, type: "GetService" },
    { regex: /:WaitForChild\(/g, type: "WaitForChild" },
    { regex: /:FindFirstChild\(/g, type: "FindFirstChild" },
    { regex: /:GetChildren\(/g, type: "GetChildren" },
    { regex: /:GetDescendants\(/g, type: "GetDescendants" },
    { regex: /:Clone\(/g, type: "Clone" },
    { regex: /:Destroy\(/g, type: "Destroy" },
    { regex: /:Connect\(/g, type: "Connect" },
    { regex: /HttpGet\(/g, type: "HttpGet", risk: "high" },
    { regex: /HttpPost\(/g, type: "HttpPost", risk: "high" },
    { regex: /:Raycast\(/g, type: "Raycast" },
    { regex: /:Create\(/g, type: "TweenCreate" },
    { regex: /loadstring\(/g, type: "loadstring", risk: "critical" },
    { regex: /getgenv\(\)/g, type: "getgenv" },
    { regex: /gethui\(\)/g, type: "gethui" },
  ];
  for (const p of cgPatterns) {
    let mm; while ((mm = p.regex.exec(code)) !== null) {
      callGraph.push({ type: p.type, risk: p.risk || "low", value: (mm[1] || mm[0]).substring(0,100) });
    }
  }

  // Libraries
  const lower = code.toLowerCase();
  const libs = [
    { pat: "rayfield", name: "Rayfield" }, { pat: "orion", name: "OrionLib" },
    { pat: "kavo", name: "Kavo" }, { pat: "venyx", name: "Venyx" },
    { pat: "linoria", name: "Linoria" }, { pat: "dex", name: "Dex" },
    { pat: "infinite", name: "InfiniteYield" }, { pat: "hydroxide", name: "Hydroxide" },
  ].filter(l => lower.includes(l.pat)).map(l => l.name);

  // Services
  const services = [...new Set([...code.matchAll(/GetService\(["'](.*?)["']\)/g)].map(m=>m[1]))];

  // UI
  const ui = [];
  [["CreateWindow","Window"],["CreateTab","Tab"],["CreateButton","Button"],["CreateToggle","Toggle"],["CreateSlider","Slider"],["CreateDropdown","Dropdown"]].forEach(([p,n])=>{
    const c = (code.match(new RegExp(p,"g"))||[]).length;
    if (c) ui.push({ type: n, count: c });
  });

  // Output
  let out = [];
  out.push("-- Envlog9ms Direct Concat 400KB+ (5-files version)");
  out.push(`-- Original: ${code.length} bytes | Luraph: ${hasLuraph}`);
  out.push(`-- Services: ${services.join(", ")}`);
  out.push(`-- Libraries: ${libs.join(", ")}`);
  out.push("");
  out.push(code.substring(0,80000));

  return {
    output: out.join("\n"),
    stringRefs: stringRefs.slice(0,30),
    callGraph: callGraph.slice(0,50),
    libraries: libs,
    uiElements: ui,
    services,
    stats: {
      originalSize: code.length,
      processingTimeMs: Date.now()-start,
      stringRefsCount: stringRefs.length,
      callGraphCount: callGraph.length,
      mode: "direct_concat_400kb_5files"
    }
  };
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const url = req.url || "/";
  
  // GET /
  if (req.method === 'GET' && (url === '/' || url === '/api' || url === '/api/')) {
    return res.status(200).json({
      name: "Envlog9ms",
      version: "5-files Direct Concat 400KB+",
      files: 5,
      endpoints: {
        "GET /": "help",
        "GET /api/health": "health",
        "POST /api/direct_concat": "main - 400KB+ full systems",
        "POST /api/mega": "alias",
        "POST /api/allinone": "52KB optimized",
        "POST /api/deobfuscate": "legacy"
      },
      usage: `curl -X POST https://${req.headers.host}/api/direct_concat -H "Content-Type: application/json" -d '{"code":"print(1)"}'`
    });
  }

  if (url.includes('/health')) {
    return res.status(200).json({ status: "ok", version: "5-files", timestamp: new Date().toISOString() });
  }

  // POST handlers (all use same direct_concat logic)
  if (req.method === 'POST') {
    try {
      const { code } = req.body || {};
      if (!code || typeof code !== 'string') return res.status(400).json({ error: "Missing code" });
      if (code.length > 800000) return res.status(400).json({ error: "Too large, max 800KB" });
      
      const result = analyzeDirectConcat(code);
      return res.status(200).json({ success: true, mode: "direct_concat_400kb_5files", ...result });
    } catch (e) {
      return res.status(500).json({ success: false, error: e.message });
    }
  }

  return res.status(404).json({ error: "Not found, use POST /api/direct_concat" });
     }
