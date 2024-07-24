import { Socket } from "phoenix";

const userSocket = new Socket("/socket", { params: { test: 1 } });
userSocket.connect();

export default userSocket;
