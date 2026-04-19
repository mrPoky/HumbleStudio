// HumbleSudoku demo config — mirrors .humble/design.json in the HumbleSudoku repo
const DEMO_CONFIG = {
  meta: { name:"HumbleSudoku", version:"1.0", platform:"ios", repo:"humbleplatform/HumbleSudoku" },
  tokens: {
    colors: {
      accent:         { dark:"#1DB8A0", light:"#0D9B86", group:"Accent" },
      accentLight:    { dark:"#2DD4BF", light:"#1DB8A0", group:"Accent" },
      accentBlue:     { dark:"#3B82F6", light:"#2563EB", group:"Accent" },
      bookmark:       { dark:"#5B8DEF", light:"#3B6FD4", group:"Accent" },
      bgPrimary:      { dark:"#0D1628", light:"#F0F4FA", group:"Backgrounds" },
      surface:        { dark:"#162035", light:"#FFFFFF",  group:"Backgrounds" },
      surface2:       { dark:"#1E2A40", light:"#E8EEF8",  group:"Backgrounds" },
      surface3:       { dark:"#263348", light:"#D8E2F0",  group:"Backgrounds" },
      destructiveBg:  { dark:"#3D0F1F", light:"#FEE2E2",  group:"Semantic" },
      destructive:    { dark:"#F87171", light:"#DC2626",   group:"Semantic" },
      success:        { dark:"#34D399", light:"#059669",   group:"Semantic" },
      warning:        { dark:"#FBBF24", light:"#D97706",   group:"Semantic" },
      textPrimary:    { dark:"#FFFFFF", light:"#0D1628",   group:"Text" },
      textSecondary:  { dark:"#8A9BB0", light:"#4A5E78",   group:"Text" },
      textTertiary:   { dark:"#4A5E78", light:"#8A9BB0",   group:"Text" },
    },
    typography: [
      { role:"displayTitle",  swiftui:".largeTitle .bold",    size:28, weight:700, preview:"HumbleSudoku" },
      { role:"navTitle",      swiftui:".title2 .semibold",    size:20, weight:600, preview:"Uložená sudoku" },
      { role:"headline",      swiftui:".headline",            size:17, weight:600, preview:"Detail rébusu" },
      { role:"bodySemibold",  swiftui:".body .medium",        size:15, weight:500, preview:"Zobrazení chyb" },
      { role:"body",          swiftui:".body",                size:15, weight:400, preview:"Klidný design. Ostrá výzva.", secondary:true },
      { role:"subheadline",   swiftui:".subheadline",         size:13, weight:400, preview:"V systémovém nastavení iOS", secondary:true },
      { role:"caption",       swiftui:".caption",             size:12, weight:400, preview:"18. 4. 2026 16:08", secondary:true },
      { role:"sectionHeader", swiftui:".caption2 .semibold",  size:11, weight:700, preview:"Historie pokusů", caps:true, secondary:true },
      { role:"numpad",        swiftui:".title2 .bold",        size:22, weight:700, preview:"1  2  3" },
      { role:"timer",         swiftui:".title3 .mono",        size:20, weight:700, preview:"00:06", mono:true },
    ],
    spacing: {
      sp1: { value:"4",  usage:"micro gap" },
      sp2: { value:"8",  usage:"component gap" },
      sp3: { value:"12", usage:"inner padding" },
      sp4: { value:"16", usage:"card padding" },
      sp5: { value:"20", usage:"screen h-padding" },
      sp6: { value:"24", usage:"section gap" },
      sp8: { value:"32", usage:"large gap" },
    },
    radius: {
      sm:    { value:"8px",  usage:"badge, tag" },
      md:    { value:"12px", usage:"tool button" },
      btn:   { value:"14px", usage:"button, numpad" },
      card:  { value:"16px", usage:"card, sheet" },
      pill:  { value:"50px", usage:"badge pill" },
      circle:{ value:"50%",  usage:"circle button" },
    }
  },
  components: [
    {
      id:"primary-button", name:"HumbleButton", group:"Buttons",
      renderer:"button", swiftui:"HumbleButton(title:style:)",
      description:"Primary CTA. Full-width on most screens.",
      mocks:[
        { id:"primary",     label:"Primary",     props:{ title:"Spustit klidnou hru", style:"primary" } },
        { id:"blue",        label:"Blue CTA",    props:{ title:"Pokračovat ve hře",   style:"blue" } },
        { id:"secondary",   label:"Secondary",   props:{ title:"Sekundární",          style:"secondary" } },
        { id:"destructive", label:"Destructive", props:{ title:"Resetovat hru",       style:"destructive" } },
        { id:"ghost",       label:"Ghost",       props:{ title:"Zrušit",              style:"ghost" } },
        { id:"disabled",    label:"Disabled",    props:{ title:"Spustit hru",         style:"primary", disabled:true } },
      ]
    },
    {
      id:"badge", name:"HumbleBadge", group:"Labels",
      renderer:"badge", swiftui:"HumbleBadge(label:style:)",
      description:"Status pill. border-radius: 50px.",
      mocks:[
        { id:"teal",    label:"Teal (difficulty)", props:{ label:"Střední",     style:"teal" } },
        { id:"surface", label:"Surface",           props:{ label:"Extra lehké", style:"surface" } },
        { id:"blue",    label:"Blue (info)",       props:{ label:"Nápověda",    style:"blue" } },
      ]
    },
    {
      id:"timer-badge", name:"TimerBadge", group:"Labels",
      renderer:"timer", swiftui:"TimerBadge(value:accent:)",
      description:"Monospaced time display. Accent color when game running.",
      mocks:[
        { id:"normal", label:"Normal", props:{ value:"14:12", accent:false } },
        { id:"accent", label:"Accent", props:{ value:"00:06", accent:true } },
      ]
    },
    {
      id:"difficulty-picker", name:"DifficultyPicker", group:"Game",
      renderer:"difficulty-picker", swiftui:"DifficultyPicker(selected:)",
      description:"Segmented difficulty selector.",
      mocks:[
        { id:"stredni", label:"Střední sel.", props:{ options:["Extra lehké","Lehké","Střední","Těžké","Extra těžké"], selected:2 } },
        { id:"lehke",   label:"Lehké sel.",   props:{ options:["Extra lehké","Lehké","Střední","Těžké","Extra těžké"], selected:1 } },
      ]
    },
    {
      id:"numpad", name:"NumberPad", group:"Game",
      renderer:"numpad", swiftui:"NumberPad(selected:onTap:)",
      description:"3×3 digit grid. Selected digit highlighted in accent.",
      mocks:[
        { id:"sel5", label:"5 selected", props:{ selected:5 } },
        { id:"sel1", label:"1 selected", props:{ selected:1 } },
        { id:"none", label:"None",       props:{ selected:-1 } },
      ]
    },
    {
      id:"cell-states", name:"GridCell", group:"Game",
      renderer:"cell-states", swiftui:"GridCell(state:value:)",
      description:"All cell rendering states.",
      mocks:[{ id:"all", label:"All states", props:{} }]
    },
    {
      id:"stat-chips", name:"StatChips", group:"Game",
      renderer:"stat-chips", swiftui:"StatChipsRow(difficulty:time:)",
      description:"In-game difficulty + timer row.",
      mocks:[
        { id:"running", label:"Running", props:{ chips:[{label:"Obtížnost",value:"Střední"},{label:"Čas",value:"04:32",accent:true}] } },
        { id:"paused",  label:"Paused",  props:{ chips:[{label:"Obtížnost",value:"Těžké"},{label:"Čas",value:"12:07",accent:false}] } },
      ]
    },
    {
      id:"navbar-game", name:"GameNavBar", group:"Navigation",
      renderer:"navbar", swiftui:"GameNavigationBar(title:actions:)",
      description:"Custom nav bar with circle buttons.",
      mocks:[
        { id:"game",     label:"Game screen", props:{ title:"HumbleSudoku",   actions:["🔖","⊞","⚙"] } },
        { id:"saved",    label:"Saved list",  props:{ title:"Uložená sudoku", actions:["☰"] } },
        { id:"settings", label:"Settings",    props:{ title:"Nastavení",      actions:[] } },
      ]
    },
    {
      id:"settings-list", name:"SettingsList", group:"Lists",
      renderer:"list", swiftui:"SettingsList(sections:)",
      description:"Grouped list rows with chevrons.",
      mocks:[
        { id:"appearance", label:"Appearance", props:{ rows:[{label:"Motiv",value:"Tmavý"},{label:"Jazyk",value:"CS"}] } },
        { id:"game",       label:"Game",       props:{ rows:[{label:"Zobrazení chyb",value:"Ihned"},{label:"Jak hrát",value:""}] } },
      ]
    },
    {
      id:"action-card", name:"ActionCard", group:"Cards",
      renderer:"action-card", swiftui:"ActionCard(title:subtitle:buttons:)",
      description:"Highlighted card with icon action buttons. Used for QR scanner.",
      mocks:[
        { id:"qr", label:"QR Scanner", props:{ title:"Spustit sudoku z kódu", subtitle:"Nasměrujte kameru na QR kód sudoku", buttons:[{icon:"⊟",label:"Skenovat"},{icon:"🖼",label:"Z galerie"}] } },
      ]
    },
  ],
  views: [
    {
      id:"home", name:"HomeView", root:true,
      description:"App entry point. Difficulty selection and game start.",
      navbar:{ title:"HumbleSudoku", back:false, actions:["⚙"] },
      components:["primary-button","difficulty-picker"],
      navigatesTo:[
        { viewId:"game",     trigger:"Spustit klidnou hru", type:"push" },
        { viewId:"settings", trigger:"Settings button",     type:"push" },
      ]
    },
    {
      id:"game", name:"GameView",
      description:"Main game screen with sudoku grid, timer, and numpad.",
      navbar:{ title:"HumbleSudoku", back:true, actions:["🔖","⊞","⚙"] },
      components:["stat-chips","numpad","cell-states"],
      navigatesTo:[
        { viewId:"settings", trigger:"Settings button", type:"push" },
        { viewId:"home",     trigger:"Back",            type:"pop" },
      ]
    },
    {
      id:"saved", name:"SavedView",
      description:"List of bookmarked puzzles. QR import.",
      navbar:{ title:"Uložená sudoku", back:true, actions:["☰"] },
      components:["action-card","settings-list"],
      navigatesTo:[
        { viewId:"detail", trigger:"Row tap", type:"push" },
      ]
    },
    {
      id:"detail", name:"DetailView",
      description:"Puzzle detail with attempt history.",
      presentation:"sheet",
      navbar:{ title:"Detail rébusu", back:false, actions:[] },
      components:["badge","timer-badge","primary-button"],
      navigatesTo:[
        { viewId:"game", trigger:"Pokračovat ve hře", type:"replace" },
      ]
    },
    {
      id:"settings", name:"SettingsView",
      description:"App preferences – theme, error display, saved puzzles.",
      navbar:{ title:"Nastavení", back:true, actions:[] },
      components:["settings-list"],
      navigatesTo:[]
    },
  ],
  navigation: {
    root:"home",
    type:"stack"
  }
};
