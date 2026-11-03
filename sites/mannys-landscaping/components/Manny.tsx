/**
 * "Manny" — the Manny's Landscaping mascot.
 * One drawing, two crops: the full figure, or a head-and-cap badge for the logo.
 */

const C = {
  navy: "#0f1a2e",
  navyMid: "#2b3d5e",
  red: "#b8322a",
  redDark: "#8f241e",
  cream: "#f6efe2",
  sand: "#d4bb8f",
  sandDark: "#b39667",
  skin: "#b07650",
  skinShade: "#935f3e",
  hair: "#241812",
  boot: "#3f2a1d",
  wood: "#c8975d",
  steel: "#a9b1bb",
};

function Figure({ animated }: { animated: boolean }) {
  return (
    <>
      {/* shadow */}
      <ellipse cx="100" cy="236" rx="60" ry="7" fill={C.navy} opacity="0.16" />

      {/* legs + boots */}
      <rect x="72" y="188" width="24" height="34" rx="7" fill={C.navyMid} />
      <rect x="104" y="188" width="24" height="34" rx="7" fill={C.navyMid} />
      <rect x="64" y="216" width="36" height="16" rx="8" fill={C.boot} />
      <rect x="100" y="216" width="36" height="16" rx="8" fill={C.boot} />

      {/* torso: red work shirt + navy overall bib */}
      <rect x="62" y="122" width="76" height="70" rx="20" fill={C.red} />
      <path d="M78 196 V146 a6 6 0 0 1 6 -6 H116 a6 6 0 0 1 6 6 V196 Z" fill={C.navy} />
      <path d="M82 142 L72 126 M118 142 L128 126" stroke={C.navy} strokeWidth="7" strokeLinecap="round" />
      <circle cx="84" cy="147" r="3" fill={C.sand} />
      <circle cx="116" cy="147" r="3" fill={C.sand} />
      <rect x="88" y="156" width="24" height="16" rx="3" fill="none" stroke={C.cream} strokeOpacity="0.25" strokeWidth="2" />

      {/* tool belt + trowel */}
      <rect x="60" y="180" width="80" height="12" rx="5" fill={C.sandDark} />
      <rect x="94" y="181" width="12" height="10" rx="2" fill="none" stroke={C.cream} strokeWidth="2" />
      <rect x="124" y="176" width="5" height="10" rx="2" fill={C.wood} />
      <path d="M118 188 H136 L127 208 Z" fill={C.steel} />

      {/* right arm holding a paver */}
      <path d="M132 134 Q146 148 150 166" stroke={C.red} strokeWidth="17" strokeLinecap="round" fill="none" />
      <g transform="rotate(-10 158 160)">
        <rect x="136" y="146" width="44" height="28" rx="3" fill={C.sand} stroke={C.sandDark} strokeWidth="2" />
        <path d="M136 160 H180 M158 146 V160 M147 160 V174 M169 160 V174" stroke={C.sandDark} strokeWidth="1.6" />
      </g>
      <circle cx="150" cy="170" r="9" fill={C.skin} />

      {/* left arm with rubber mallet (taps when animated) */}
      <g className={animated ? "manny-mallet" : undefined}>
        <path d="M66 134 Q54 150 52 170" stroke={C.red} strokeWidth="17" strokeLinecap="round" fill="none" />
        <path d="M56 180 L30 126" stroke={C.wood} strokeWidth="6" strokeLinecap="round" />
        <g transform="rotate(-26 28 122)">
          <rect x="10" y="111" width="36" height="22" rx="6" fill={C.navy} />
          <rect x="10" y="111" width="9" height="22" rx="4" fill={C.navyMid} />
        </g>
        <circle cx="52" cy="174" r="9" fill={C.skin} />
      </g>

      {/* neck */}
      <rect x="90" y="112" width="20" height="16" rx="6" fill={C.skinShade} />

      {/* head */}
      <circle cx="56" cy="84" r="8" fill={C.skinShade} />
      <circle cx="144" cy="84" r="8" fill={C.skinShade} />
      <ellipse cx="100" cy="84" rx="44" ry="38" fill={C.skin} />
      {/* hair at temples + short beard line */}
      <path d="M57 66 Q55 82 61 90 L66 70 Z M143 66 Q145 82 139 90 L134 70 Z" fill={C.hair} />
      <path d="M66 98 Q72 118 100 120 Q128 118 134 98 Q126 112 100 114 Q74 112 66 98 Z" fill={C.hair} opacity="0.55" />
      {/* brows, eyes, nose, smile, cheeks */}
      <path d="M77 75 Q85 70 93 75 M107 75 Q115 70 123 75" stroke={C.hair} strokeWidth="4" strokeLinecap="round" fill="none" />
      <ellipse cx="85" cy="87" rx="5" ry="6" fill={C.navy} />
      <ellipse cx="115" cy="87" rx="5" ry="6" fill={C.navy} />
      <circle cx="87" cy="85" r="1.8" fill="#fff" />
      <circle cx="117" cy="85" r="1.8" fill="#fff" />
      <path d="M100 91 Q105 97 99 100" stroke={C.skinShade} strokeWidth="3" strokeLinecap="round" fill="none" />
      <path d="M83 102 Q100 120 117 102 Q100 108 83 102 Z" fill={C.cream} stroke={C.navy} strokeWidth="2.5" strokeLinejoin="round" />
      <circle cx="73" cy="100" r="6" fill={C.red} opacity="0.22" />
      <circle cx="127" cy="100" r="6" fill={C.red} opacity="0.22" />

      {/* cap */}
      <path d="M54 68 Q54 24 100 22 Q146 24 146 68 Z" fill={C.navy} />
      <circle cx="100" cy="24" r="4" fill={C.red} />
      <path d="M48 66 Q100 80 152 66 Q150 78 100 84 Q50 78 48 66 Z" fill={C.red} />
      <path d="M88 58 V40 L100 52 L112 40 V58" stroke={C.cream} strokeWidth="5" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </>
  );
}

export function Manny({ className = "", animated = true, title = "Manny, the Manny's Landscaping mascot" }: { className?: string; animated?: boolean; title?: string }) {
  return (
    <svg viewBox="0 0 200 246" className={className} role="img" aria-label={title}>
      <Figure animated={animated} />
    </svg>
  );
}

/** Head-and-cap crop inside a cream badge, used as the logo mark. */
export function MannyBadge({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="40 14 120 120" className={className} aria-hidden>
      <defs>
        <clipPath id="manny-badge">
          <circle cx="100" cy="74" r="58" />
        </clipPath>
      </defs>
      <circle cx="100" cy="74" r="58" fill={C.cream} />
      <g clipPath="url(#manny-badge)">
        <Figure animated={false} />
      </g>
      <circle cx="100" cy="74" r="56.5" fill="none" stroke={C.red} strokeWidth="3" />
    </svg>
  );
}
