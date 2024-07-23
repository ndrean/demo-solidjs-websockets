import { Socket } from "phoenix";

const userSocket = new Socket("/socket", {});
userSocket.connect();

export default userSocket;
