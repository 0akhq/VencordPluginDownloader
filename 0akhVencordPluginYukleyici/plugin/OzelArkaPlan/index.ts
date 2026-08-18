import { definePluginSettings } from "@api/Settings";
import definePlugin, { OptionType } from "@utils/types";

const settings = definePluginSettings({
    imageUrl: {
        type: OptionType.STRING,
        default: "",
        description: "Arka plan resim URL'si (http/https veya yerel data: URI)",
        onChange() { applyCSS(); }
    },
    darkness: {
        type: OptionType.SLIDER,
        default: 0.45,
        min: 0,
        max: 1,
        markers: [0, 0.25, 0.5, 0.75, 1],
        description: "Discord panel karartma (0 = saydam, 1 = tam siyah)",
        onChange() { applyCSS(); }
    },
    blur: {
        type: OptionType.SLIDER,
        default: 0,
        min: 0,
        max: 24,
        markers: [0, 6, 12, 18, 24],
        description: "Arka plan bulanıklığı (px)",
        onChange() { applyCSS(); }
    },
    saturation: {
        type: OptionType.SLIDER,
        default: 100,
        min: 0,
        max: 200,
        markers: [0, 50, 100, 150, 200],
        description: "Renk doygunluğu (%) — 0 gri, 100 normal, 200 canlı",
        onChange() { applyCSS(); }
    },
    brightness: {
        type: OptionType.SLIDER,
        default: 100,
        min: 30,
        max: 170,
        markers: [30, 70, 100, 130, 170],
        description: "Parlaklık (%)",
        onChange() { applyCSS(); }
    },
    contrast: {
        type: OptionType.SLIDER,
        default: 100,
        min: 50,
        max: 150,
        markers: [50, 75, 100, 125, 150],
        description: "Kontrast (%)",
        onChange() { applyCSS(); }
    },
    overlayColor: {
        type: OptionType.STRING,
        default: "#000000",
        description: "Ek renk overlay (HEX — örn. #ff0000 kırmızı ton)",
        onChange() { applyCSS(); }
    },
    overlayOpacity: {
        type: OptionType.SLIDER,
        default: 0,
        min: 0,
        max: 0.8,
        markers: [0, 0.2, 0.4, 0.6, 0.8],
        description: "Renk overlay opaklığı",
        onChange() { applyCSS(); }
    },
    position: {
        type: OptionType.SELECT,
        description: "Arka plan konumu",
        options: [
            { label: "Merkez",     value: "center center", default: true },
            { label: "Üst",        value: "center top" },
            { label: "Alt",        value: "center bottom" },
            { label: "Sol Üst",    value: "left top" },
            { label: "Sağ Üst",   value: "right top" },
            { label: "Sol Alt",   value: "left bottom" },
            { label: "Sağ Alt",   value: "right bottom" }
        ],
        onChange() { applyCSS(); }
    },
    size: {
        type: OptionType.SELECT,
        description: "Arka plan boyutu",
        options: [
            { label: "Kapla (cover)",   value: "cover", default: true },
            { label: "Sığdır (contain)", value: "contain" },
            { label: "Tam genişlik",    value: "100% auto" },
            { label: "Tam yükseklik",   value: "auto 100%" }
        ],
        onChange() { applyCSS(); }
    },
    gradient: {
        type: OptionType.BOOLEAN,
        default: false,
        description: "Dikey vignette gradient ekle (kenarları koyulaştır)",
        onChange() { applyCSS(); }
    },
    panelTransparency: {
        type: OptionType.BOOLEAN,
        default: true,
        description: "Discord panellerini şeffaflaştır (kapalıysa sadece arka plan değişir)",
        onChange() { applyCSS(); }
    },
    animateOnLoad: {
        type: OptionType.BOOLEAN,
        default: true,
        description: "Arka planı yüklenirken yavaşça göster (fade-in)",
        onChange() { applyCSS(); }
    }
});

const STYLE_ID = "ozelarkaplan-style";

function hexToRgba(hex: string, alpha: number): string {
    const clean = hex.replace(/^#/, "");
    const full  = clean.length === 3
        ? clean.split("").map(c => c + c).join("")
        : clean;
    const num = parseInt(full, 16);
    if (isNaN(num)) return `rgba(0,0,0,${alpha})`;
    const r = (num >> 16) & 255;
    const g = (num >>  8) & 255;
    const b =  num        & 255;
    return `rgba(${r},${g},${b},${alpha})`;
}

function applyCSS() {
    document.getElementById(STYLE_ID)?.remove();

    const url = settings.store.imageUrl.trim();
    if (!url) return;

    const {
        darkness, blur, saturation, brightness, contrast,
        overlayOpacity, position, size, gradient,
        panelTransparency, animateOnLoad
    } = settings.store;

    const overlayColor  = settings.store.overlayColor.trim() || "#000000";

    const layers: string[] = [];

    if (gradient) {
        const d0 = Math.min(1, darkness + 0.25).toFixed(2);
        const d1 = Math.max(0, darkness - 0.1 ).toFixed(2);
        layers.push(
            `linear-gradient(to bottom, rgba(0,0,0,${d0}) 0%, rgba(0,0,0,${d1}) 40%, rgba(0,0,0,${d1}) 60%, rgba(0,0,0,${d0}) 100%)`
        );
    }

    if (overlayOpacity > 0) {
        layers.push(`linear-gradient(${hexToRgba(overlayColor, overlayOpacity)}, ${hexToRgba(overlayColor, overlayOpacity)})`);
    }

    const safeUrl = url.replace(/"/g, "%22");
    layers.push(`url("${safeUrl}")`);

    const panelSelectors = panelTransparency ? `
        body,
        #app-mount,
        [class*="bg_"],
        [class*="sidebar_"],
        [class*="chat_"],
        [class*="container_"],
        [class*="app_"],
        [class*="base_"],
        [class*="content_"],
        [class*="layers_"],
        [class*="layer_"],
        [class*="scroller_"],
        [class*="membersWrap_"],
        [class*="channelTextArea_"],
        [class*="toolbar_"],
        [class*="header_"],
        [class*="footer_"] {
            background-color: rgba(0, 0, 0, ${darkness}) !important;
            background-image: none !important;
        }` : "";

    const fadeIn = animateOnLoad ? `
        @keyframes oap-fadein {
            from { opacity: 0; }
            to   { opacity: 1; }
        }
        body::before { animation: oap-fadein 0.6s ease; }` : "";

    const css = `
        body::before {
            content: "";
            position: fixed;
            inset: 0;
            background-image: ${layers.join(",\n                    ")};
            background-size: ${size}, auto, ${size};
            background-position: ${position};
            background-repeat: no-repeat;
            filter: blur(${blur}px) saturate(${saturation}%) brightness(${brightness}%) contrast(${contrast}%);
            z-index: -1;
            pointer-events: none;
            /* blur taşma gizleme: inset:0 + overflow:hidden yerine clip-path */
            ${blur > 0 ? "transform: scale(1.05);" : ""}
        }
        ${fadeIn}
        ${panelSelectors}
    `;

    const el = document.createElement("style");
    el.id = STYLE_ID;
    el.textContent = css;
    document.head.appendChild(el);
}

export default definePlugin({
    name: "OzelArkaPlan",
    description: "Discord'a özel arka plan, blur, renk tonu, parlaklık, doygunluk, kontrast ve vignette efektleri ekler.",
    authors: [{ name: "0akh", id: 0n }],
    settings,

    start() {
        applyCSS();
    },

    stop() {
        document.getElementById(STYLE_ID)?.remove();
    }
});
