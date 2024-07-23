import "phoenix_html";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const Hooks = {
  hoverCard: await import("./hoverCard.js").then((module) => module.hoverCard),
  tableHook: await import("./tableHook.js").then((module) => module.tableHook),
  chartHook: await import("./chartHook.js").then((module) => module.chartHook),
};

let liveSocket;

await import("phoenix").then(async ({ Socket }) => {
  const { LiveSocket } = await import("phoenix_live_view");
  liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: { _csrf_token: csrfToken },
    hooks: Hooks,
  });
  liveSocket.connect();
  window.liveSocket = liveSocket;
});

// Show progress bar on live navigation and form submits
await import("topbar").then((topbar) => {
  topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
  window.addEventListener("phx:page-loading-start", (_info) => {
    topbar.show(300);
  });
  window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
});

// connect if there are any LiveViews on the page

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
