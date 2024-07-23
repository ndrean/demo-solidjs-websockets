export const tableHook = {
  cryptoSocketRef: { current: null },
  channelRef: { current: null },
  async mounted() {
    const tableId = document.getElementById("table");
    if (!tableId) return;

    const context = await import("./context.js").then(
      (module) => module.default
    );
    const { getCrypto } = await import("./table.jsx");
    const CryptoTable = getCrypto(
      context,
      this.cryptoSocketRef,
      this.channelRef
    );

    const { render } = await import("solid-js/web");
    render(() => CryptoTable({ crypto: "bitcoin" }), tableId);
  },
  destroyed() {
    console.log("destroyed");
    this.cryptoSocketRef.current.close();
    this.cryptoSocketRef.current = null;
    this.channelRef.current.leave();
    this.channelRef.current = null;
  },
};
