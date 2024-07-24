import { createSignal } from "solid-js";

const [slide, setSlide] = createSignal(0);
const [count, setCount] = createSignal(0);
const [cryptoPrices, setCryptoPrices] = createSignal([]);
const [data, setData] = createSignal([]);
const [description, setDescription] = createSignal([]);

const useChannel = await import("./useChannel").then(
  (module) => module.default
);

const cryptoSocket = (currency) =>
  new WebSocket(`wss://ws.coincap.io/prices?assets=${currency}`);

const userSocket = await import("./userSocket").then(
  (module) => module.default
);

const [options] = createSignal({
  chart: {
    id: "realtime",
    height: 350,
    type: "line",
    animations: {
      enabled: true,
      easing: "linear",
      dynamicAnimation: {
        speed: 1000,
      },
    },
    toolbar: {
      show: false,
    },
    zoom: {
      enabled: false,
    },
  },
  dataLabels: {
    enabled: false,
  },
  stroke: {
    curve: "smooth",
  },
  title: {
    text: "Dynamic Updating Realtime Chart",
    align: "left",
  },
  markers: {
    size: 0,
  },
  xaxis: {
    type: "datetime",
    // range: XAXISRANGE,
  },
  // yaxis: {
  //   max: 100,
  // },
  legend: {
    show: false,
  },
});

export default {
  slide,
  setSlide,
  count,
  setCount,
  cryptoPrices,
  setCryptoPrices,
  userSocket,
  useChannel,
  cryptoSocket,
  data,
  setData,
  options,
  description,
  setDescription,
};
