const chart = async (ctx) => {
  const { SolidApexCharts } = await import("solid-apexcharts");
  const { data, options } = ctx;
  return (_props) => {
    console.log("Rendered once");
    return (
      <SolidApexCharts
        width="700"
        height="500"
        type="line"
        options={options()}
        series={[{ data: data().slice(-100) }]}
      />
    );
  };
};

const context = await import("./context.js").then((module) => module.default);

const Chart = await chart(context);
export default Chart;
