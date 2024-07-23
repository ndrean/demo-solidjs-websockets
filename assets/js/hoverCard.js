export const hoverCard = {
  mounted() {
    this.el.onmouseenter = ({ currentTarget }) => {
      currentTarget.style.cursor = "progress";
      const id = this.el.getAttribute("data-id");
      this.pushEvent("prefetch", { id });
    };

    this.el.onmouseleave = ({ currentTarget }) =>
      (currentTarget.style.cursor = "default");
  },
};
