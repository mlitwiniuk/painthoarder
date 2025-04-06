export default {
  mode: "jit",
  content: [
    "./app/views/**/*.{slim,erb,jbuilder,turbo_stream,js}",
    "./app/decorators/**/*.rb",
    "./app/helpers/**/*.rb",
    "./app/inputs/**/*.rb",
    "./app/assets/javascripts/**/*.js",
    "./config/initializers/**/*.rb",
    "./lib/components/**/*.rb",
  ],
  safelist: ["badge-*"],
  variants: {
    extend: {
      overflow: ["hover"],
    },
  },
  daisyui: {
    themes: [
      {
        minipaints: {
          primary: "#6D28D9", // purple
          secondary: "#EC4899", // pink
          accent: "#10B981", // emerald
          neutral: "#1F2937",
          "base-100": "#F3F4F6",
          "base-200": "#E5E7EB",
          "base-300": "#D1D5DB",
          info: "#3ABFF8",
          success: "#36D399",
          warning: "#FBBD23",
          error: "#F87272",
        },
      },
      "light",
    ],
  },
  theme: {
    listStyleType: {
      none: "none",
      disc: "disc",
      decimal: "decimal",
      square: "square",
    },
  },
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
