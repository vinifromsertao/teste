export const colorOptions = [
  {
    id: "amber",
    name: "Ambar",
    solid: "#df8a1c",
    text: "#fff9f0",
    soft: "rgba(223, 138, 28, 0.18)",
    border: "rgba(223, 138, 28, 0.3)",
    gradient: ["#e57d00", "#e99a1f", "#f2b739", "#ffd768"],
  },
  {
    id: "gold",
    name: "Dourado",
    solid: "#d3a400",
    text: "#fffdf1",
    soft: "rgba(211, 164, 0, 0.18)",
    border: "rgba(211, 164, 0, 0.3)",
    gradient: ["#dca300", "#ebba13", "#f4cf3d", "#fde787"],
  },
  {
    id: "olive",
    name: "Oliva",
    solid: "#a9a683",
    text: "#fbfaef",
    soft: "rgba(169, 166, 131, 0.22)",
    border: "rgba(169, 166, 131, 0.32)",
    gradient: ["#a7a583", "#b9b691", "#cbc8a5", "#ddd9bc"],
  },
  {
    id: "teal",
    name: "Turquesa",
    solid: "#4f9da1",
    text: "#f3fffe",
    soft: "rgba(79, 157, 161, 0.18)",
    border: "rgba(79, 157, 161, 0.3)",
    gradient: ["#4a9ca2", "#58aeb0", "#72c1bf", "#8ad2d0"],
  },
  {
    id: "ocean",
    name: "Petroleo",
    solid: "#295467",
    text: "#eefaff",
    soft: "rgba(41, 84, 103, 0.2)",
    border: "rgba(41, 84, 103, 0.32)",
    gradient: ["#24485a", "#2d5b71", "#376d87", "#4a87a2"],
  },
  {
    id: "rose",
    name: "Rosado",
    solid: "#b56b74",
    text: "#fff5f7",
    soft: "rgba(181, 107, 116, 0.18)",
    border: "rgba(181, 107, 116, 0.3)",
    gradient: ["#a95d67", "#bc717b", "#d08e97", "#e3b0b7"],
  },
];

export const defaultThemeStyles = {
  "Figuras de linguagem": "amber",
  Gramatica: "gold",
  Interpretacao: "teal",
  Ortografia: "olive",
};

export function getColorOption(colorId) {
  return colorOptions.find((option) => option.id === colorId) ?? colorOptions[0];
}

export function getThemeColorId(theme, themeStyles = {}) {
  return themeStyles[theme] ?? defaultThemeStyles[theme] ?? colorOptions[0].id;
}

export function getThemeVisual(theme, themeStyles = {}) {
  return getColorOption(getThemeColorId(theme, themeStyles));
}

export function getStripedCardBackground(colorId) {
  const color = getColorOption(colorId);
  const [base, stripeOne, stripeTwo, stripeThree] = color.gradient;

  return `linear-gradient(90deg, ${base} 0%, ${stripeOne} 74%, ${stripeTwo} 88%, ${stripeThree} 100%)`;
}
