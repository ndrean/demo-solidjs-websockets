export default function useChannel(socket, topic) {
  if (!socket) return null;
  const channel = socket.channel(topic, {});
  channel
    .join()
    .receive("ok", () => {
      console.log(`Joined successfully: ${topic}`);
    })
    .receive("error", (resp) => {
      console.log(`Unable to join ${topic}`, resp.reason);
    });
  return channel;
}
