import { createEffect, onCleanup } from "solid-js";

export const getCrypto = (ctx, socketRef, channelRef) => {
  const {
    cryptoPrices,
    setCryptoPrices,
    cryptoSocket,
    userSocket,
    useChannel,
  } = ctx;

  return function CryptoTable(props) {
    const { crypto } = props;

    // store in a ref to remove it when the component is unmounted in the hook
    socketRef.current = cryptoSocket(crypto);
    channelRef.current = useChannel(userSocket, `currency:${crypto}`);

    createEffect(() => {
      socketRef.current.onmessage = ({ data }) => {
        const new_data = {
          time: new Date().toLocaleTimeString(),
          type: crypto,
          price: JSON.parse(data)[crypto],
        };
        setCryptoPrices((prev) => [new_data, ...prev]);
        channelRef.current.push(`currency:${crypto}`, new_data);
      };
    });
    // LiveView seems to shadow the onCleanup
    onCleanup(() => {
      socketRef.current.close();
      channelRef.current.leave();
    });

    console.log("Rendered once");

    return (
      <div>
        <h1>Prices for: {crypto.toUpperCase()}</h1>
        <br />
        <table border="1">
          <thead>
            <tr>
              <th>Time</th>
              <th>Currency</th>
              <th>Price</th>
            </tr>
          </thead>
          <tbody>
            <For each={cryptoPrices()}>
              {(update, index) => (
                <tr key={index}>
                  <td>{update.time}&nbsp</td>
                  <td>{update.type}</td>
                  <td>{update.price}</td>
                </tr>
              )}
            </For>
          </tbody>
        </table>
      </div>
    );
  };
};
