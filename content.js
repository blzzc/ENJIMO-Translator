(() => {
  if (globalThis.__fuyiLoaded) return;
  globalThis.__fuyiLoaded = true;

  const HOST_ID = "fuyi-translator-host";
  const SIZE_PRESET_VERSION = 1;
  const DEFAULT_PANEL_WIDTH = 286;
  const DEFAULT_PANEL_HEIGHT = 72;
  const OPACITIES = [0.62, 0.76, 0.88, 0.96];
  const THEMES = ["gray", "graphite", "warm"];
  const LANGUAGES = {
    en: { code: "EN", hint: "EN_US", name: "ENGLISH", color: "#38c7ff" },
    zh: { code: "ZH", hint: "ZH_CN", name: "中文", color: "#ff5252" },
    es: { code: "ES", hint: "ES_ES", name: "ESPAÑOL", color: "#ffbd32" },
    ja: { code: "JA", hint: "JA_JP", name: "日本語", color: "#ff63b1" },
    ko: { code: "KO", hint: "KO_KR", name: "한국어", color: "#4de39b" }
  };
  const SPEECH_LOCALES = { en: "en-US", zh: "zh-CN", es: "es-ES", ja: "ja-JP", ko: "ko-KR" };
  const PALETTE_ROWS = [
    ["#2a819b", "#21bcaf", "#f5c36b", "#f4efe5", "#f66770", "#db4a61"],
    ["#f0d1ae", "#ef9ca4", "#d45e78", "#a53962", "#510822", "#290716"],
    ["#c7d0a6", "#e3e6be", "#f6f1d7", "#f2e2b6", "#cca06f", "#a8744e"],
    ["#88c5dd", "#2b9db8", "#073b50", "#fdb512", "#f57c00", "#e7542e"],
    ["#d2d0c7", "#a4b48f", "#73936d", "#527b56", "#365c3d", "#2f4f42"],
    ["#294d5a", "#2f9e91", "#e8c45e", "#f29b5c", "#e86b4e", "#cd4f3d"],
    ["#bda6cd", "#eabbd3", "#f09bc1", "#a9cded", "#8cbce7", "#74a9d5"],
    ["#16162f", "#4d0821", "#87061e", "#d41414", "#f05a0a", "#ffb414"],
    ["#3f388c", "#7571df", "#fdba0c", "#f48600", "#f34e00", "#c92a2a"]
  ];
  const PALETTE_MARKUP = PALETTE_ROWS.map((row) => `
    <div class="palette-strip">${row.map((color) =>
      `<button class="palette-color" draggable="true" data-color="${color}" style="background:${color}" aria-label="拖动颜色 ${color}"></button>`
    ).join("")}</div>`).join("");

  let host;
  let shadow;
  let translator;
  let translatorPair = "";
  let busy = false;
  let pendingTranslation = false;
  let translateTimer;
  let sourceLanguage = "en";
  let targetLanguage = "zh";
  let opacityIndex = 2;
  let themeIndex = 0;
  let blockColors = { handle: "", source: "", target: "" };
  let panelWidth = DEFAULT_PANEL_WIDTH;
  let panelHeight = DEFAULT_PANEL_HEIGHT;
  let savedPosition = null;
  let drag = null;
  let commandMode = false;
  let commandModeTimer;
  let translationVersion = 0;
  let spokenUtterance = null;

  const markup = `
    <style>
      :host{all:initial;position:fixed;z-index:2147483647;top:88px;right:28px;width:286px;font-family:"Cascadia Mono","SFMono-Regular",Consolas,"Noto Sans SC",monospace;font-size:12px;line-height:1.3;filter:drop-shadow(0 9px 18px rgba(0,0,0,.32))}
      *{box-sizing:border-box}
      .panel{position:relative;overflow:visible;border:0;background:var(--shell);backdrop-filter:blur(13px);-webkit-backdrop-filter:blur(13px);opacity:var(--opacity)}
      .panel[data-theme="gray"]{--shell:rgba(9,13,16,.9);--field:rgba(24,30,34,.9);--field2:rgba(15,21,25,.88);--text:#dce9ed;--muted:#73848b;--border:rgba(105,227,250,.16);--accent:#5de3fa}
      .panel[data-theme="graphite"]{--shell:rgba(8,9,11,.92);--field:rgba(27,29,33,.9);--field2:rgba(17,19,22,.9);--text:#edf1f3;--muted:#7e878c;--border:rgba(255,255,255,.12);--accent:#b8c3c8}
      .panel[data-theme="warm"]{--shell:rgba(20,16,14,.92);--field:rgba(39,31,27,.9);--field2:rgba(27,21,19,.9);--text:#ece5df;--muted:#928278;--border:rgba(239,163,118,.14);--accent:#d98252}
      textarea{display:block;width:100%;height:calc(var(--panel-height,72px)/2);min-height:29px;resize:none;overflow:auto;border:0;outline:0;padding:10px 12px;background:var(--field);color:var(--text);font:10px/1.4 inherit;letter-spacing:.02em;scrollbar-width:thin}
      textarea::placeholder{color:currentColor;opacity:.48;font-size:8px;font-weight:700;letter-spacing:.1em}
      .source{border:0;background:var(--source-color,var(--field));color:var(--source-text,var(--text));scrollbar-width:none}
      .source::-webkit-scrollbar{display:none}
      .result-row{position:relative;height:calc(var(--panel-height,72px)/2)}
      .result{height:100%;padding-right:35px;background:var(--target-color,var(--field2));color:var(--target-text,var(--text))}
      .result.busy{color:var(--muted)}
      .speak{position:absolute;z-index:1;right:6px;top:50%;width:21px;height:21px;transform:translateY(-50%);border:0;padding:0;background:rgba(35,39,42,.16);color:var(--target-text,var(--text));cursor:pointer}.speak:hover{background:rgba(77,101,111,.35)}.speak:disabled{opacity:0;pointer-events:none}.speak.playing{background:#526f79;color:#fff;box-shadow:0 0 7px rgba(92,145,160,.32)}.speak svg{display:block;width:12px;height:12px;margin:auto;fill:currentColor;shape-rendering:crispEdges}
      .drag-handle{position:absolute;z-index:2;left:-7px;top:-7px;width:13px;height:13px;border:0;padding:0;background:var(--handle-color,var(--accent));cursor:move;touch-action:none}
      .panel.command-mode .drag-handle{background:#72b6c8;box-shadow:0 0 7px rgba(114,182,200,.42)}
      .help,.editor,.language-picker,.color-picker{position:absolute;z-index:3;right:0;top:calc(100% + 7px);width:244px;padding:8px 9px;border:0;background:linear-gradient(145deg,rgba(24,28,32,.98),rgba(11,14,17,.98)),repeating-linear-gradient(0deg,transparent 0 7px,rgba(100,230,255,.025) 8px);color:#eef7fa;box-shadow:0 12px 30px rgba(0,0,0,.42),inset 0 1px rgba(121,231,255,.12);font:8px/1.5 inherit;opacity:1}
      .help[hidden],.editor[hidden],.language-picker[hidden],.color-picker[hidden]{display:none}.help>div{display:flex;align-items:center;justify-content:space-between;gap:12px;min-height:29px;border-bottom:1px solid rgba(112,226,247,.08)}.help>div:last-child{border-bottom:0}.help>div>span:first-child{color:#77858d;font-size:8px;font-weight:700;letter-spacing:.16em;text-transform:uppercase}.help-actions{display:flex;gap:4px}.help-action{min-width:58px;height:21px;border:0;padding:0 7px;background:#262d31;color:#cbd5d9;font:600 8px/1 inherit;letter-spacing:.03em;cursor:pointer}.help-action:hover{background:#354147;color:#eef7fa}.help-action:active{background:#526f79;color:#fff}.help-action.compact{min-width:27px;width:27px;padding:0;font-size:10px}.help-actions .help-action{min-width:27px}
      .editor{width:270px}.size-row{display:grid;grid-template-columns:42px 54px 1fr;align-items:center;gap:7px;margin:6px 0}.size-row label{color:#73838b;font-size:8px;font-weight:700;letter-spacing:.14em}.size-row input[type="number"]{width:54px;height:23px;border:0;background:#11181c;color:#dff8fd;padding:3px 5px;font:9px inherit;outline:0;box-shadow:inset 0 0 0 1px rgba(105,227,250,.14)}.size-row input[type="range"]{width:100%;accent-color:#65e5fb}
      .language-picker{width:270px;padding:8px}.language-slots{display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:7px}.language-slot{height:41px;border:0;padding:5px 7px;background:#11181c;box-shadow:inset 0 0 0 1px rgba(105,227,250,.15)}.language-slot.over{background:#19313a;box-shadow:inset 0 0 0 1px #64e5fb}.language-slot small{display:block;color:#66777f;font-size:7px;letter-spacing:.15em}.language-slot span{display:flex;align-items:center;gap:5px;color:#e9f8fb;font-size:8px;font-weight:700;letter-spacing:.04em}.lang-dot{display:inline-block;flex:0 0 auto;width:7px;height:7px;background:var(--lang-color)}.language-bank{display:grid;grid-template-columns:repeat(5,1fr);gap:5px}.language-tile{display:flex;align-items:center;justify-content:center;gap:4px;height:34px;border:0;background:#242a2e;color:#dbe8ec;font-size:8px;font-weight:600;letter-spacing:.03em;cursor:grab;user-select:none}.language-tile:active{cursor:grabbing;background:#526f79;color:#fff}.language-tile:hover{background:#354147;color:#fff}
      .color-picker{width:286px;padding:8px}.palette-list{display:grid;gap:4px}.palette-strip{display:grid;grid-template-columns:repeat(6,1fr);height:21px}.palette-color{position:relative;z-index:0;border:0;padding:0;cursor:grab}.palette-color:hover{z-index:1;filter:saturate(1.08) brightness(1.04);transform:scaleY(1.12)}.palette-color:active{cursor:grabbing}.panel.color-dragging [data-color-block]{outline:2px dashed rgba(115,232,255,.7);outline-offset:-3px}.panel.color-dragging [data-color-block].color-over{outline-style:solid;outline-color:#63e6ff}
      @media(max-width:370px){:host{left:8px!important;right:8px!important;width:auto}}
    </style>
    <section class="panel" data-theme="gray" style="--opacity:.88;--panel-height:72px" role="dialog" aria-label="ENJIMO Translate">
      <button class="drag-handle" data-color-block="handle" title="拖动 ENJIMO Translate" aria-label="拖动翻译框"></button>
      <textarea class="source" data-color-block="source" maxlength="5000" rows="1" spellcheck="false" aria-label="翻译输入"></textarea>
      <div class="result-row" data-color-block="target">
        <textarea class="result" rows="1" readonly aria-label="翻译输出"></textarea>
        <button class="speak" title="朗读译文" aria-label="朗读译文" disabled>
          <svg viewBox="0 0 16 16" aria-hidden="true"><rect x="1" y="6" width="4" height="5"/><rect x="5" y="4" width="2" height="9"/><rect x="7" y="3" width="2" height="11"/><rect x="11" y="5" width="2" height="2"/><rect x="13" y="7" width="2" height="4"/><rect x="11" y="11" width="2" height="2"/></svg>
        </button>
      </div>
      <aside class="help" hidden>
        <div><span>翻译</span><button class="help-action" data-action="translate">RUN</button></div>
        <div><span>语言</span><button class="help-action" data-action="language">SELECT</button></div>
        <div><span>配色</span><button class="help-action" data-action="color">PICK</button></div>
        <div><span>透明</span><span class="help-actions"><button class="help-action compact" data-action="opacity-down">−</button><button class="help-action compact" data-action="opacity-up">＋</button></span></div>
        <div><span>复制</span><button class="help-action" data-action="copy">COPY</button></div>
        <div><span>尺寸</span><button class="help-action" data-action="size">EDIT</button></div>
        <div><span>收起</span><button class="help-action" data-action="close">CLOSE</button></div>
      </aside>
      <aside class="editor" hidden>
        <div class="size-row"><label>WIDTH</label><input class="width-number" type="number" min="220" max="720" step="1"><input class="width-range" type="range" min="220" max="720" step="1"></div>
        <div class="size-row"><label>HEIGHT</label><input class="height-number" type="number" min="58" max="320" step="1"><input class="height-range" type="range" min="58" max="320" step="1"></div>
      </aside>
      <aside class="language-picker" hidden aria-label="语言选择">
        <div class="language-slots">
          <div class="language-slot" data-role="source"><small>INPUT</small><span><i class="lang-dot"></i><b class="slot-language"></b></span></div>
          <div class="language-slot" data-role="target"><small>OUTPUT</small><span><i class="lang-dot"></i><b class="slot-language"></b></span></div>
        </div>
        <div class="language-bank">
          <div class="language-tile" draggable="true" data-language="en" style="--lang-color:#38c7ff"><i class="lang-dot"></i>EN</div>
          <div class="language-tile" draggable="true" data-language="zh" style="--lang-color:#ff5252"><i class="lang-dot"></i>ZH</div>
          <div class="language-tile" draggable="true" data-language="es" style="--lang-color:#ffbd32"><i class="lang-dot"></i>ES</div>
          <div class="language-tile" draggable="true" data-language="ja" style="--lang-color:#ff63b1"><i class="lang-dot"></i>JA</div>
          <div class="language-tile" draggable="true" data-language="ko" style="--lang-color:#4de39b"><i class="lang-dot"></i>KO</div>
        </div>
      </aside>
      <aside class="color-picker" hidden aria-label="颜色编辑">
        <div class="palette-list">${PALETTE_MARKUP}</div>
      </aside>
    </section>`;

  function mountTarget() {
    const fullscreen = document.fullscreenElement;
    if (fullscreen && !["VIDEO", "IMG", "IFRAME"].includes(fullscreen.tagName)) return fullscreen;
    return document.documentElement;
  }

  function selectedText() {
    return String(window.getSelection?.() || "").trim().slice(0, 5000);
  }

  function updateLanguageHints() {
    shadow.querySelector(".source").placeholder = `INPUT::${LANGUAGES[sourceLanguage].hint}`;
    shadow.querySelector(".result").placeholder = `OUTPUT::${LANGUAGES[targetLanguage].hint}`;
    for (const slot of shadow.querySelectorAll(".language-slot")) {
      const language = slot.dataset.role === "source" ? sourceLanguage : targetLanguage;
      slot.style.setProperty("--lang-color", LANGUAGES[language].color);
      slot.querySelector(".slot-language").textContent = LANGUAGES[language].name;
    }
  }

  function applySize() {
    host.style.width = `${panelWidth}px`;
    shadow.querySelector(".panel").style.setProperty("--panel-height", `${panelHeight}px`);
    shadow.querySelector(".width-number").value = panelWidth;
    shadow.querySelector(".width-range").value = panelWidth;
    shadow.querySelector(".height-number").value = panelHeight;
    shadow.querySelector(".height-range").value = panelHeight;
    if (host.style.left) {
      host.style.left = `${Math.max(8, Math.min(innerWidth - panelWidth - 8, parseFloat(host.style.left) || 8))}px`;
      host.style.top = `${Math.max(8, Math.min(innerHeight - panelHeight - 8, parseFloat(host.style.top) || 8))}px`;
    }
  }

  function updateSize(dimension, rawValue) {
    const value = Number(rawValue);
    if (!Number.isFinite(value)) return;
    if (dimension === "width") panelWidth = Math.max(220, Math.min(720, Math.round(value)));
    else panelHeight = Math.max(58, Math.min(320, Math.round(value)));
    applySize();
    saveSettings();
  }

  function ensureHost() {
    if (host?.isConnected) return;
    host = document.createElement("div");
    host.id = HOST_ID;
    host.style.display = "none";
    shadow = host.attachShadow({ mode: "closed" });
    shadow.innerHTML = markup;
    mountTarget().append(host);
    bindUI();
    restoreSettings();
    applySize();
    updateLanguageHints();
  }

  function setVisible(visible, suppliedText = "") {
    ensureHost();
    host.style.display = visible ? "block" : "none";
    if (!visible) {
      stopSpeaking();
      shadow.querySelector(".help").hidden = true;
      shadow.querySelector(".editor").hidden = true;
      shadow.querySelector(".language-picker").hidden = true;
      shadow.querySelector(".color-picker").hidden = true;
      return;
    }
    const input = shadow.querySelector(".source");
    const text = suppliedText || selectedText();
    if (text) input.value = text;
    requestAnimationFrame(() => input.focus());
  }

  async function getTranslator() {
    const pair = `${sourceLanguage}:${targetLanguage}`;
    if (translator && translatorPair === pair) return translator;
    translator?.destroy?.();
    translator = null;
    if (!("Translator" in globalThis)) {
      throw new Error("需要 Chrome 138+");
    }
    const options = { sourceLanguage, targetLanguage };
    const availability = await globalThis.Translator.availability(options);
    if (availability === "unavailable") throw new Error("语言包不可用");
    translator = await globalThis.Translator.create(options);
    translatorPair = pair;
    return translator;
  }

  async function translate() {
    clearTimeout(translateTimer);
    if (busy) {
      pendingTranslation = true;
      return;
    }
    const input = shadow.querySelector(".source");
    const output = shadow.querySelector(".result");
    const text = input.value.trim();
    const version = translationVersion;
    if (!text) {
      stopSpeaking();
      output.value = "";
      shadow.querySelector(".speak").disabled = true;
      return;
    }
    stopSpeaking();
    busy = true;
    output.classList.add("busy");
    output.value = "…";
    shadow.querySelector(".speak").disabled = true;
    try {
      const engine = await getTranslator();
      const translated = await engine.translate(text);
      if (version === translationVersion) {
        output.value = translated;
        shadow.querySelector(".speak").disabled = false;
      }
    } catch (error) {
      if (version === translationVersion) {
        output.value = error?.message || "翻译失败";
        shadow.querySelector(".speak").disabled = true;
      }
    } finally {
      busy = false;
      output.classList.remove("busy");
      if (pendingTranslation) {
        pendingTranslation = false;
        translate();
      }
    }
  }

  function scheduleTranslate() {
    clearTimeout(translateTimer);
    translateTimer = setTimeout(translate, 420);
  }

  function setLanguage(role, language) {
    if (!LANGUAGES[language]) return;
    const previousSource = sourceLanguage;
    const previousTarget = targetLanguage;
    if (role === "source") {
      sourceLanguage = language;
      if (sourceLanguage === targetLanguage) targetLanguage = previousSource;
    } else {
      targetLanguage = language;
      if (targetLanguage === sourceLanguage) sourceLanguage = previousTarget;
    }
    translationVersion += 1;
    translator?.destroy?.();
    translator = null;
    translatorPair = "";
    stopSpeaking();
    const output = shadow.querySelector(".result");
    output.value = "";
    shadow.querySelector(".speak").disabled = true;
    updateLanguageHints();
    saveSettings();
    if (shadow.querySelector(".source").value.trim()) translate();
  }

  function toggleLanguagePicker() {
    const picker = shadow.querySelector(".language-picker");
    picker.hidden = !picker.hidden;
    shadow.querySelector(".help").hidden = true;
    shadow.querySelector(".editor").hidden = true;
    shadow.querySelector(".color-picker").hidden = true;
  }

  function setCommandMode(active) {
    clearTimeout(commandModeTimer);
    commandMode = active;
    shadow.querySelector(".panel").classList.toggle("command-mode", active);
    if (active) commandModeTimer = setTimeout(() => setCommandMode(false), 1800);
  }

  function applyBlockColors() {
    const panel = shadow.querySelector(".panel");
    for (const [block, color] of Object.entries(blockColors)) {
      const property = block === "handle" ? "--handle-color" : block === "source" ? "--source-color" : "--target-color";
      if (color) panel.style.setProperty(property, color);
      else panel.style.removeProperty(property);
      if (block === "source" || block === "target") {
        const textProperty = block === "source" ? "--source-text" : "--target-text";
        if (color) panel.style.setProperty(textProperty, contrastText(color));
        else panel.style.removeProperty(textProperty);
      }
    }
  }

  function contrastText(background) {
    const colors = background.match(/#[0-9a-f]{6}/gi) || [];
    if (!colors.length) return "#edf5f7";
    const brightness = colors.reduce((sum, color) => {
      const value = Number.parseInt(color.slice(1), 16);
      const red = value >> 16;
      const green = (value >> 8) & 255;
      const blue = value & 255;
      return sum + (red * 299 + green * 587 + blue * 114) / 1000;
    }, 0) / colors.length;
    return brightness > 145 ? "#171a1c" : "#edf5f7";
  }

  function setBlockColor(block, color) {
    const validColor = /^#[0-9a-f]{6}$/i.test(color);
    if (!(block in blockColors) || !validColor) return;
    blockColors[block] = color;
    applyBlockColors();
    saveSettings();
  }

  function toggleColorPicker() {
    const picker = shadow.querySelector(".color-picker");
    picker.hidden = !picker.hidden;
    shadow.querySelector(".help").hidden = true;
    shadow.querySelector(".editor").hidden = true;
    shadow.querySelector(".language-picker").hidden = true;
  }

  function adjustOpacity(direction) {
    opacityIndex = Math.max(0, Math.min(OPACITIES.length - 1, opacityIndex + direction));
    shadow.querySelector(".panel").style.setProperty("--opacity", OPACITIES[opacityIndex]);
    saveSettings();
  }

  async function copyOutput() {
    const text = shadow.querySelector(".result").value;
    if (!text) return;
    try { await navigator.clipboard.writeText(text); } catch { /* 页面可能禁用剪贴板权限。 */ }
  }

  function stopSpeaking() {
    globalThis.speechSynthesis?.cancel();
    spokenUtterance = null;
    shadow?.querySelector(".speak")?.classList.remove("playing");
  }

  function speakOutput() {
    const button = shadow.querySelector(".speak");
    const text = shadow.querySelector(".result").value.trim();
    if (!text || !("speechSynthesis" in globalThis)) return;
    if (spokenUtterance) {
      stopSpeaking();
      return;
    }
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = SPEECH_LOCALES[targetLanguage];
    utterance.rate = 0.96;
    utterance.onend = utterance.onerror = () => {
      if (spokenUtterance !== utterance) return;
      spokenUtterance = null;
      button.classList.remove("playing");
    };
    spokenUtterance = utterance;
    button.classList.add("playing");
    globalThis.speechSynthesis.speak(utterance);
  }

  function bindUI() {
    const input = shadow.querySelector(".source");
    const handle = shadow.querySelector(".drag-handle");
    const helpPanel = shadow.querySelector(".help");
    input.addEventListener("input", scheduleTranslate);
    shadow.querySelector(".result").addEventListener("focus", (event) => event.target.select());
    shadow.querySelector(".speak").addEventListener("click", speakOutput);
    helpPanel.addEventListener("click", (event) => {
      const button = event.target.closest(".help-action");
      if (!button) return;
      const action = button.dataset.action;
      if (action === "translate") translate();
      else if (action === "language") toggleLanguagePicker();
      else if (action === "color") toggleColorPicker();
      else if (action === "opacity-down") adjustOpacity(-1);
      else if (action === "opacity-up") adjustOpacity(1);
      else if (action === "copy") copyOutput();
      else if (action === "size") {
        helpPanel.hidden = true;
        shadow.querySelector(".language-picker").hidden = true;
        shadow.querySelector(".color-picker").hidden = true;
        shadow.querySelector(".editor").hidden = false;
      }
      else if (action === "close") helpPanel.hidden = true;
    });
    for (const tile of shadow.querySelectorAll(".language-tile")) {
      tile.addEventListener("dragstart", (event) => {
        event.dataTransfer.effectAllowed = "move";
        event.dataTransfer.setData("text/plain", tile.dataset.language);
      });
    }
    for (const slot of shadow.querySelectorAll(".language-slot")) {
      slot.addEventListener("dragover", (event) => {
        event.preventDefault();
        event.dataTransfer.dropEffect = "move";
        slot.classList.add("over");
      });
      slot.addEventListener("dragleave", () => slot.classList.remove("over"));
      slot.addEventListener("drop", (event) => {
        event.preventDefault();
        slot.classList.remove("over");
        setLanguage(slot.dataset.role, event.dataTransfer.getData("text/plain"));
      });
    }
    for (const swatch of shadow.querySelectorAll(".palette-color")) {
      swatch.addEventListener("dragstart", (event) => {
        event.dataTransfer.effectAllowed = "copy";
        event.dataTransfer.setData("application/x-enjimo-color", swatch.dataset.color);
        event.dataTransfer.setData("text/plain", swatch.dataset.color);
        shadow.querySelector(".panel").classList.add("color-dragging");
      });
      swatch.addEventListener("dragend", () => {
        shadow.querySelector(".panel").classList.remove("color-dragging");
        for (const block of shadow.querySelectorAll(".color-over")) block.classList.remove("color-over");
      });
    }
    for (const block of shadow.querySelectorAll("[data-color-block]")) {
      block.addEventListener("dragover", (event) => {
        if (!event.dataTransfer.types.includes("application/x-enjimo-color")) return;
        event.preventDefault();
        event.dataTransfer.dropEffect = "copy";
        block.classList.add("color-over");
      });
      block.addEventListener("dragleave", () => block.classList.remove("color-over"));
      block.addEventListener("drop", (event) => {
        const color = event.dataTransfer.getData("application/x-enjimo-color");
        if (!color) return;
        event.preventDefault();
        block.classList.remove("color-over");
        setBlockColor(block.dataset.colorBlock, color);
      });
    }
    for (const control of shadow.querySelectorAll(".width-number,.width-range")) {
      control.addEventListener("input", (event) => updateSize("width", event.target.value));
    }
    for (const control of shadow.querySelectorAll(".height-number,.height-range")) {
      control.addEventListener("input", (event) => updateSize("height", event.target.value));
    }
    handle.addEventListener("pointerdown", (event) => {
      const rect = host.getBoundingClientRect();
      drag = { id: event.pointerId, dx: event.clientX - rect.left, dy: event.clientY - rect.top };
      handle.setPointerCapture(event.pointerId);
      event.preventDefault();
    });
    handle.addEventListener("pointermove", (event) => {
      if (!drag || drag.id !== event.pointerId) return;
      const left = Math.max(8, Math.min(innerWidth - panelWidth - 8, event.clientX - drag.dx));
      const top = Math.max(8, Math.min(innerHeight - panelHeight - 8, event.clientY - drag.dy));
      host.style.left = `${left}px`;
      host.style.top = `${top}px`;
      host.style.right = "auto";
    });
    handle.addEventListener("pointerup", () => {
      drag = null;
      const rect = host.getBoundingClientRect();
      savedPosition = { x: rect.left / innerWidth, y: rect.top / innerHeight };
      saveSettings();
    });
    handle.addEventListener("contextmenu", (event) => {
      event.preventDefault();
      const help = shadow.querySelector(".help");
      help.hidden = !help.hidden;
      shadow.querySelector(".editor").hidden = true;
      shadow.querySelector(".language-picker").hidden = true;
      shadow.querySelector(".color-picker").hidden = true;
    });
    shadow.addEventListener("keydown", (event) => {
      const pressedKey = event.key.toLowerCase();
      if (event.ctrlKey && event.shiftKey && event.code === "Semicolon") {
        setCommandMode(true);
        event.preventDefault();
        return;
      }
      if (event.key === "Escape") {
        if (commandMode) {
          setCommandMode(false);
          event.preventDefault();
          return;
        }
        if (!shadow.querySelector(".help").hidden) shadow.querySelector(".help").hidden = true;
        else if (!shadow.querySelector(".editor").hidden) shadow.querySelector(".editor").hidden = true;
        else if (!shadow.querySelector(".language-picker").hidden) shadow.querySelector(".language-picker").hidden = true;
        else if (!shadow.querySelector(".color-picker").hidden) shadow.querySelector(".color-picker").hidden = true;
        else setVisible(false);
        event.preventDefault();
        return;
      }
      if (event.target === input && event.key === "Enter" && !event.shiftKey) {
        translate();
        event.preventDefault();
        return;
      }
      if (!commandMode || event.ctrlKey || event.altKey || event.metaKey) return;
      setCommandMode(false);
      const key = pressedKey;
      if (key === "l") toggleLanguagePicker();
      else if (key === "c") toggleColorPicker();
      else if (key === "arrowup") adjustOpacity(1);
      else if (key === "arrowdown") adjustOpacity(-1);
      else if (key === "v") copyOutput();
      else if (key === "s") {
        const editor = shadow.querySelector(".editor");
        editor.hidden = !editor.hidden;
        shadow.querySelector(".help").hidden = true;
        shadow.querySelector(".language-picker").hidden = true;
        shadow.querySelector(".color-picker").hidden = true;
      }
      else return;
      event.preventDefault();
    });
    window.addEventListener("blur", () => setCommandMode(false));
  }

  function saveSettings() {
    chrome.storage.local.set({
      fuyiMinimalSettings: {
        sourceLanguage, targetLanguage, opacityIndex, themeIndex,
        panelWidth, panelHeight, position: savedPosition, blockColors,
        sizePresetVersion: SIZE_PRESET_VERSION
      }
    });
  }

  async function restoreSettings() {
    const { fuyiMinimalSettings } = await chrome.storage.local.get("fuyiMinimalSettings");
    if (!fuyiMinimalSettings) return;
    sourceLanguage = LANGUAGES[fuyiMinimalSettings.sourceLanguage] ? fuyiMinimalSettings.sourceLanguage : "en";
    targetLanguage = LANGUAGES[fuyiMinimalSettings.targetLanguage] ? fuyiMinimalSettings.targetLanguage : "zh";
    if (targetLanguage === sourceLanguage) targetLanguage = sourceLanguage === "zh" ? "en" : "zh";
    opacityIndex = Math.max(0, Math.min(OPACITIES.length - 1, Number(fuyiMinimalSettings.opacityIndex) || 0));
    themeIndex = Math.max(0, Math.min(THEMES.length - 1, Number(fuyiMinimalSettings.themeIndex) || 0));
    if (fuyiMinimalSettings.blockColors && typeof fuyiMinimalSettings.blockColors === "object") {
      for (const block of Object.keys(blockColors)) {
        const color = fuyiMinimalSettings.blockColors[block];
        const validColor = /^#[0-9a-f]{6}$/i.test(color || "");
        blockColors[block] = validColor ? color : "";
      }
    }
    const useSavedSize = fuyiMinimalSettings.sizePresetVersion === SIZE_PRESET_VERSION;
    panelWidth = useSavedSize
      ? Math.max(220, Math.min(720, Number(fuyiMinimalSettings.panelWidth) || DEFAULT_PANEL_WIDTH))
      : DEFAULT_PANEL_WIDTH;
    panelHeight = useSavedSize
      ? Math.max(58, Math.min(320, Number(fuyiMinimalSettings.panelHeight) || DEFAULT_PANEL_HEIGHT))
      : DEFAULT_PANEL_HEIGHT;
    savedPosition = fuyiMinimalSettings.position || null;
    const panel = shadow.querySelector(".panel");
    panel.dataset.theme = THEMES[themeIndex];
    panel.style.setProperty("--opacity", OPACITIES[opacityIndex]);
    applyBlockColors();
    applySize();
    if (savedPosition) {
      host.style.left = `${Math.max(8, Math.min(innerWidth - panelWidth - 8, savedPosition.x * innerWidth))}px`;
      host.style.top = `${Math.max(8, Math.min(innerHeight - panelHeight - 8, savedPosition.y * innerHeight))}px`;
      host.style.right = "auto";
    }
    updateLanguageHints();
    if (!useSavedSize) saveSettings();
  }

  chrome.runtime.onMessage.addListener((message) => {
    if (message.type === "FUYI_TOGGLE") {
      ensureHost();
      setVisible(host.style.display === "none");
    }
    if (message.type === "FUYI_SHOW") {
      setVisible(true, message.text || "");
      if (message.autoTranslate) translate();
    }
  });

  // 直接在普通网页捕获呼出键，避免 Chrome 未给开发版扩展分配 commands 快捷键。
  document.addEventListener("keydown", (event) => {
    const isToggleKey = (event.ctrlKey || event.metaKey) && event.shiftKey &&
      !event.altKey && (event.code === "Digit9" || event.code === "Numpad9");
    if (!isToggleKey) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    ensureHost();
    setVisible(host.style.display === "none");
  }, true);

  // 双击开发启动器时，在专用预览页上自动显示翻译框。
  if (new URL(location.href).searchParams.get("enjimo-preview") === "1") {
    setVisible(true);
  }

  document.addEventListener("fullscreenchange", () => {
    if (!host) return;
    const wasVisible = host.style.display !== "none";
    mountTarget().append(host);
    if (wasVisible) host.style.display = "block";
  });
})();
