export const chartHook = {
  currChannel: null,
  async mounted() {
    const chartId = document.getElementById("chart");
    if (!chartId) return;

    let currency = "bitcoin";
    const context = await import("./context.js").then(
      (module) => module.default
    );
    const { useChannel, userSocket, data, setData } = context;
    this.currChannel = useChannel(userSocket, `currency:${currency}`);
    this.currChannel.on("update", (point) =>
      setData((prev) => [...prev, [new Date(point.time), point.price]])
    );

    const { lazy } = await import("solid-js");
    const Chart = lazy(() => import("./chart.jsx"));

    const { render } = await import("solid-js/web");
    render(() => Chart(), chartId);
  },
  destroyed() {
    console.log("close channel");
    if (this.currChannel) this.currChannel.leave();
  },
};
