module.exports = {
  defaults: {
    standard: "WCAG2AA",
    runners: ["axe"],
    hideElements: [
      ".usa-banner__button-text" // axe can't determine the background color for this button
    ]
  },
  urls: [
    "http://localhost:3000"
  ]
};
