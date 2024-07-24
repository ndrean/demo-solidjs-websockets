export const imageHook = {
  async mounted() {
    // this.handleEvent("image_processed", ({ caption }) => console.log(caption));

    const { FilesetResolver, ImageClassifier } = await import(
      "@mediapipe/tasks-vision"
    );

    const image = document.getElementById("image");
    image.onload = async () => {
      console.log("image loaded");
      let mediapipe_caption = await classifiyMeDiaPipe(image);
      let ml5_caption = await classifyML5Image(image);
      this.push("image_processed", {
        mediapipe_caption: mediapipe_caption,
        ml5_caption: ml5_caption,
      });
    };

    async function createImageClassifier() {
      const vision = await FilesetResolver.forVisionTasks(
        "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision/wasm"
      );
      return await ImageClassifier.createFromOptions(vision, {
        baseOptions: {
          modelAssetPath: `https://storage.googleapis.com/mediapipe-models/image_classifier/efficientnet_lite0/float32/1/efficientnet_lite0.tflite`,
          // NOTE: For this demo, we keep the default CPU delegate.
        },
        maxResults: 3,
        runningMode: "IMAGE",
      });
    }

    async function classifiyMeDiaPipe(img) {
      const imageClassifier = await createImageClassifier();
      if (!imageClassifier) {
        alert("Image classifier not available");
        return;
      }

      const { classifications } = imageClassifier.classify(image);
      let result = [];
      if (classifications || classifications.length > 0) {
        classifications[0].categories.forEach((category) =>
          result.push(category.categoryName)
        );
      }
      // this.pushEvent("mediapipe", { mediapipe: result });
      // console.log(result);
      return result;
    }

    async function classifyML5Image(img) {
      const ml5 = await import("ml5");
      const classifier = ml5.imageClassifier("MobileNet");
      const results = await new Promise((resolve) => {
        classifier.classify(img, 3, (error, results) => {
          if (error) {
            console.error(error);
            resolve([]);
          } else {
            resolve(results);
          }
        });
      });

      const classifications = results.map((result) => result.label);
      console.log(classifications);
      return classifications.join(", ");
    }
  },
};
